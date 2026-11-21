import { ContractError } from "../contract.mjs";

// Addis AI speech adapters: native-language TTS (Addis Voices) and STT
// (Scribe). English TTS stays on-device (Addis English voice is ~20 s).
const BASE = "https://api.addisassistant.com/api/v1";
export const VOICES = { am: "am-hamen", om: "om-ayyaantuu" };

/// Loudness envelope of a PCM16 WAV: RMS per frame, normalised to the
/// clip's own loud level (95th percentile) and clamped to 0..1. It drives
/// the Professor's jaw while the clip plays. It is an AMPLITUDE envelope,
/// not phoneme/viseme data: the mouth opens with loudness, not with sounds.
export function wavEnvelope(buf, frameMs = 50) {
  if (buf.length < 44 || buf.toString("ascii", 0, 4) !== "RIFF" || buf.toString("ascii", 8, 12) !== "WAVE") return null;
  let off = 12, fmt = null, data = null;
  while (off + 8 <= buf.length) {
    const id = buf.toString("ascii", off, off + 4);
    const size = buf.readUInt32LE(off + 4);
    const body = off + 8;
    if (id === "fmt ") fmt = { channels: buf.readUInt16LE(body + 2), rate: buf.readUInt32LE(body + 4), bits: buf.readUInt16LE(body + 14) };
    if (id === "data") { data = buf.subarray(body, Math.min(buf.length, body + size)); break; }
    off = body + size + (size & 1);
  }
  if (!fmt || !data || fmt.bits !== 16 || fmt.channels < 1) return null;
  const step = fmt.channels * 2;
  const perFrame = Math.max(1, Math.round((fmt.rate * frameMs) / 1000));
  const rms = [];
  for (let i = 0; i + step <= data.length; i += perFrame * step) {
    let sum = 0, n = 0;
    for (let j = i; j + step <= data.length && n < perFrame; j += step, n++) {
      const v = data.readInt16LE(j) / 32768;
      sum += v * v;
    }
    rms.push(Math.sqrt(sum / Math.max(1, n)));
  }
  if (!rms.length) return null;
  const sorted = [...rms].sort((a, b) => a - b);
  const ref = Math.max(sorted[Math.floor(sorted.length * 0.95)] ?? 0, 0.02);
  return { frameMs, values: rms.map((r) => Math.round(Math.min(1, r / ref) * 100) / 100) };
}

export function createAddisSpeech({ apiKey = process.env.ADDIS_API_KEY, fetchImpl = fetch } = {}) {
  const cache = new Map(); // text+lang -> audio (bounded), saves credits on repeats
  const remember = (k, v) => {
    cache.set(k, v);
    if (cache.size > 200) cache.delete(cache.keys().next().value);
  };
  const fail = (res) => {
    if (res.status === 401 || res.status === 403) return new ContractError("unavailable", "Speech provider rejected the credentials.", 503);
    if (res.status === 429) return new ContractError("rate_limited", "Speech service busy.", 429);
    return new ContractError("provider_error", `Speech provider error ${res.status}`, 502);
  };
  return {
    name: "addis",
    async synthesize(text, language) {
      if (!(language in VOICES)) throw new ContractError("bad_request", "Synthesis supports am and om only.");
      const clean = text.trim().slice(0, 600);
      if (!clean) throw new ContractError("bad_request", "Empty text.");
      const key = `${language}:${clean}`;
      if (cache.has(key)) return cache.get(key);
      const res = await fetchImpl(`${BASE}/voice/generations`, {
        method: "POST",
        headers: { "content-type": "application/json", "x-api-key": apiKey },
        body: JSON.stringify({
          text: clean,
          voice_id: VOICES[language],
          language,
          output_format: "pcm_16000", // returned as a 16 kHz WAV; small, and we can read its loudness
          client_request_id: `tts-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`,
        }),
        signal: AbortSignal.timeout(25_000),
      }).catch(() => { throw new ContractError("unavailable", "Speech provider unreachable.", 503); });
      if (!res.ok) throw fail(res);
      const d = (await res.json())?.data;
      const dataUrl = typeof d?.audio === "string" ? d.audio : null;
      if (!dataUrl?.startsWith("data:")) throw new ContractError("provider_error", "No audio returned.", 502);
      const [meta, b64] = dataUrl.split(",", 2);
      const mimeType = meta.slice(5).split(";")[0] || "audio/wav";
      const envelope = mimeType.includes("wav") ? wavEnvelope(Buffer.from(b64, "base64")) : null;
      const out = { mimeType, audioBase64: b64, durationSeconds: d.duration_seconds ?? null, envelope };
      remember(key, out);
      return out;
    },
    async transcribe(bytes, language, contentType = "audio/wav") {
      if (!["am", "om", "en"].includes(language)) throw new ContractError("bad_request", "language must be am, om or en.");
      const form = new FormData();
      form.append("audio", new Blob([bytes], { type: contentType }), "speech.wav");
      const url = `${BASE}/scribe/transcribe?language=${language}&request_id=stt-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
      const res = await fetchImpl(url, { method: "POST", headers: { "x-api-key": apiKey }, body: form, signal: AbortSignal.timeout(30_000) })
        .catch(() => { throw new ContractError("unavailable", "Speech provider unreachable.", 503); });
      if (!res.ok) throw fail(res);
      const text = (await res.json())?.data?.text;
      if (typeof text !== "string") throw new ContractError("provider_error", "No transcript returned.", 502);
      return { text: text.trim(), language };
    },
  };
}
