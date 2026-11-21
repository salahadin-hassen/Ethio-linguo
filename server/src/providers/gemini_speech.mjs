import { ContractError } from "../contract.mjs";
import { pcmEnvelope } from "./addis_speech.mjs";

// English voice for the Professor via Gemini TTS (streamGenerateContent,
// audio response modality). The exact English text is sent as-is (no
// rewriting). Audio arrives as 24 kHz 16-bit mono PCM chunks; we collect them
// into one WAV plus a loudness envelope for the mouth. Measured 2026-11-21:
// first chunk 0.6-1.0 s, whole clip 1.7-2.4 s. The free quota is small
// (429 after a few calls), so requests are deduped and the app always falls
// back to the phone's own voice.
const BASE = "https://generativelanguage.googleapis.com/v1beta/models";

function wav(pcm, rate) {
  const h = Buffer.alloc(44);
  h.write("RIFF", 0); h.writeUInt32LE(36 + pcm.length, 4); h.write("WAVE", 8);
  h.write("fmt ", 12); h.writeUInt32LE(16, 16); h.writeUInt16LE(1, 20); h.writeUInt16LE(1, 22);
  h.writeUInt32LE(rate, 24); h.writeUInt32LE(rate * 2, 28); h.writeUInt16LE(2, 32); h.writeUInt16LE(16, 34);
  h.write("data", 36); h.writeUInt32LE(pcm.length, 40);
  return Buffer.concat([h, pcm]);
}

export function createGeminiSpeech({
  apiKey = process.env.GEMINI_API_KEY,
  model = process.env.GEMINI_TTS_MODEL || "gemini-3.8-flash-tts",
  voice = process.env.GEMINI_VOICE || "Charon",
  fetchImpl = fetch,
  timeoutMs = 8000,
} = {}) {
  const cache = new Map();

  async function produce(text) {
    let res;
    try {
      res = await fetchImpl(`${BASE}/${model}:streamGenerateContent?alt=sse`, {
        method: "POST",
        headers: { "content-type": "application/json", "x-goog-api-key": apiKey },
        body: JSON.stringify({
          contents: [{ parts: [{ text }] }],
          generationConfig: {
            responseModalities: ["AUDIO"],
            speechConfig: { voiceConfig: { prebuiltVoiceConfig: { voiceName: voice } } },
          },
        }),
        signal: AbortSignal.timeout(timeoutMs),
      });
    } catch {
      throw new ContractError("unavailable", "English voice unreachable.", 503);
    }
    if (res.status === 429) throw new ContractError("rate_limited", "English voice busy.", 429);
    if (res.status === 401 || res.status === 403) throw new ContractError("unavailable", "English voice rejected the credentials.", 503);
    if (!res.ok || !res.body) throw new ContractError("provider_error", `English voice error ${res.status}`, 502);
    const chunks = [];
    let rate = 24000, buf = "";
    try {
      const dec = new TextDecoder();
      for await (const c of res.body) {
        buf += dec.decode(c, { stream: true });
        let nl;
        while ((nl = buf.indexOf("\n")) >= 0) {
          const line = buf.slice(0, nl).trim();
          buf = buf.slice(nl + 1);
          if (!line.startsWith("data:")) continue;
          let part;
          try { part = JSON.parse(line.slice(5))?.candidates?.[0]?.content?.parts?.[0]?.inlineData; } catch { continue; }
          if (!part?.data) continue;
          const m = /rate=(\d+)/.exec(part.mimeType ?? "");
          if (m) rate = Number(m[1]);
          chunks.push(Buffer.from(part.data, "base64"));
        }
      }
    } catch {
      throw new ContractError("unavailable", "English voice timed out.", 503);
    }
    const pcm = Buffer.concat(chunks);
    // Validate: at least ~0.2 s of 16-bit audio.
    if (pcm.length < rate * 2 * 0.2) throw new ContractError("provider_error", "No English audio returned.", 502);
    return {
      mimeType: "audio/wav",
      audioBase64: wav(pcm, rate).toString("base64"),
      durationSeconds: Math.round((pcm.length / (rate * 2)) * 100) / 100,
      envelope: { ...pcmEnvelope(pcm, rate), source: "pcm" },
    };
  }

  function synthesize(text) {
    const clean = String(text ?? "").trim().slice(0, 600);
    if (!clean) return Promise.reject(new ContractError("bad_request", "Empty text."));
    if (cache.has(clean)) return cache.get(clean);
    const p = produce(clean);
    cache.set(clean, p);
    if (cache.size > 100) cache.delete(cache.keys().next().value);
    p.catch(() => { if (cache.get(clean) === p) cache.delete(clean); });
    return p;
  }

  return {
    name: "gemini",
    model,
    synthesize,
    prewarm(text) { synthesize(text).catch(() => {}); },
  };
}
