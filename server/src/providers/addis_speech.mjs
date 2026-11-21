import { spawn } from "node:child_process";
import { ContractError } from "../contract.mjs";

// Addis AI speech adapters: native-language TTS (Addis Voices) and STT
// (Scribe). English TTS stays on-device (Addis English voice is ~20 s).
const BASE = "https://api.addisassistant.com/api/v1";
// The Professor: mature male, low-key reflective voices.
export const VOICES = { am: "am-yohanes-calm", om: "om-leta" };

// ---------------------------------------------------------------------------
// Loudness envelopes. They drive the Professor's jaw while a clip plays.
// AMPLITUDE only, not phoneme/viseme data: the mouth opens with loudness.
// ---------------------------------------------------------------------------

/// RMS per [frameMs] of mono/interleaved PCM16, normalised to the clip's own
/// loud level (95th percentile) and clamped to 0..1.
export function pcmEnvelope(data, rate, channels = 1, frameMs = 50) {
  const step = channels * 2;
  const perFrame = Math.max(1, Math.round((rate * frameMs) / 1000));
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

/// Envelope of a PCM16 WAV (RIFF) buffer, or null if it isn't one.
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
  const env = pcmEnvelope(data, fmt.rate, fmt.channels, frameMs);
  return env && { ...env, source: "pcm" };
}

/// Decodes MP3 with ffmpeg (if installed) to measure real loudness.
function decodeMp3(mp3, ffmpeg = process.env.FFMPEG || "ffmpeg") {
  return new Promise((resolve) => {
    let p;
    try {
      p = spawn(ffmpeg, ["-loglevel", "error", "-i", "pipe:0", "-ac", "1", "-ar", "16000", "-f", "s16le", "pipe:1"], { stdio: ["pipe", "pipe", "ignore"] });
    } catch { return resolve(null); }
    const out = [];
    const timer = setTimeout(() => { p.kill("SIGKILL"); resolve(null); }, 4000);
    p.on("error", () => { clearTimeout(timer); resolve(null); });
    p.stdout.on("data", (c) => out.push(c));
    p.on("close", (code) => { clearTimeout(timer); resolve(code === 0 ? Buffer.concat(out) : null); });
    p.stdin.on("error", () => {});
    p.stdin.end(mp3);
  });
}

/// Lowers pitch by PROFESSOR_PITCH (default 0.86) keeping tempo; null if
/// ffmpeg is unavailable (the original voice is used then).
function deepen(mp3, ffmpeg = process.env.FFMPEG || "ffmpeg") {
  const f = Number(process.env.PROFESSOR_PITCH || 1);
  if (!(f > 0.5 && f < 1)) return Promise.resolve(null);
  return new Promise((resolve) => {
    let p;
    try {
      p = spawn(ffmpeg, ["-loglevel", "error", "-i", "pipe:0", "-af", `aresample=44100,asetrate=44100*${f},aresample=44100,atempo=${(1 / f).toFixed(4)}`, "-c:a", "libmp3lame", "-b:a", "96k", "-f", "mp3", "pipe:1"], { stdio: ["pipe", "pipe", "ignore"] });
    } catch { return resolve(null); }
    const out = [];
    const timer = setTimeout(() => { p.kill("SIGKILL"); resolve(null); }, 5000);
    p.on("error", () => { clearTimeout(timer); resolve(null); });
    p.stdout.on("data", (c) => out.push(c));
    p.on("close", (code) => { clearTimeout(timer); const b = Buffer.concat(out); resolve(code === 0 && b.length > 200 ? b : null); });
    p.stdin.on("error", () => {});
    p.stdin.end(mp3);
  });
}

/// Fallback when ffmpeg is missing: each MP3 granule's global_gain (from the
/// frame side info) tracks loudness roughly (r ~ 0.6 against decoded RMS on
/// Addis clips). Coarser than decoding, still measured from the real audio.
export function mp3GainEnvelope(buf, frameMs = 50) {
  const BR1 = [0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320];
  const BR2 = [0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160];
  const SR = { 3: [44100, 48000, 32000], 2: [22050, 24000, 16000], 0: [11025, 12000, 8000] };
  let i = 0;
  if (buf.length > 10 && buf.toString("ascii", 0, 3) === "ID3") {
    i = 10 + (((buf[6] & 0x7f) << 21) | ((buf[7] & 0x7f) << 14) | ((buf[8] & 0x7f) << 7) | (buf[9] & 0x7f));
  }
  const buckets = [];
  let t = 0;
  while (i + 4 <= buf.length) {
    if (buf[i] !== 0xff || (buf[i + 1] & 0xe0) !== 0xe0) { i++; continue; }
    const ver = (buf[i + 1] >> 3) & 3, layer = (buf[i + 1] >> 1) & 3, prot = buf[i + 1] & 1;
    const bri = buf[i + 2] >> 4, sri = (buf[i + 2] >> 2) & 3, pad = (buf[i + 2] >> 1) & 1, mode = buf[i + 3] >> 6;
    if (layer !== 1 || bri === 0 || bri === 15 || sri === 3 || ver === 1) { i++; continue; }
    const mpeg1 = ver === 3, rate = SR[ver][sri], kbps = (mpeg1 ? BR1 : BR2)[bri];
    const len = Math.floor(((mpeg1 ? 144000 : 72000) * kbps) / rate) + pad;
    if (len < 8 || i + len > buf.length) break;
    let bit = (i + 4 + (prot ? 0 : 2)) * 8;
    const rd = (n) => { let v = 0; for (let k = 0; k < n; k++, bit++) v = (v << 1) | ((buf[bit >> 3] >> (7 - (bit & 7))) & 1); return v; };
    const ch = mode === 3 ? 1 : 2, gr = mpeg1 ? 2 : 1;
    rd(mpeg1 ? 9 : 8); rd(mpeg1 ? (ch === 1 ? 5 : 3) : (ch === 1 ? 1 : 2)); if (mpeg1) rd(4 * ch);
    let gain = 0;
    for (let g = 0; g < gr; g++) for (let c = 0; c < ch; c++) {
      rd(12); rd(9); gain = Math.max(gain, rd(8)); rd(mpeg1 ? 4 : 9);
      if (rd(1)) { rd(2); rd(1); rd(10); rd(9); } else { rd(15); rd(4); rd(3); }
      if (mpeg1) rd(1);
      rd(1); rd(1);
    }
    const k = Math.floor((t * 1000) / frameMs);
    buckets[k] = Math.max(buckets[k] ?? 0, gain);
    t += (mpeg1 ? 1152 : 576) / rate;
    i += len;
  }
  if (!buckets.length) return null;
  const g = Array.from(buckets, (v) => v ?? 0);
  const s = [...g].sort((a, b) => a - b);
  const lo = s[Math.floor(s.length * 0.1)], hi = Math.max(s[Math.floor(s.length * 0.95)], lo + 1);
  return { frameMs, source: "mp3-gain", values: g.map((v) => Math.round(Math.min(1, Math.max(0, (v - lo) / (hi - lo))) * 100) / 100) };
}

/// Strips Addis "mp3-frames-v1" framing: [u32 BE length][bytes]..., a zero
/// length frame, then a JSON completion record.
export function unframeMp3Stream(buf) {
  const audio = [];
  let off = 0, meta = null;
  while (off + 4 <= buf.length) {
    const n = buf.readUInt32BE(off);
    off += 4;
    if (n === 0) {
      const rest = buf.subarray(off);
      // The completion record may itself be length-prefixed.
      const body = rest.length >= 4 && rest.readUInt32BE(0) === rest.length - 4 ? rest.subarray(4) : rest;
      try { meta = JSON.parse(body.toString("utf8"))?.data ?? null; } catch { meta = null; }
      break;
    }
    if (off + n > buf.length) break;
    audio.push(buf.subarray(off, off + n));
    off += n;
  }
  return { mp3: Buffer.concat(audio), meta };
}

export function createAddisSpeech({ apiKey = process.env.ADDIS_API_KEY, fetchImpl = fetch, decode = decodeMp3 } = {}) {
  // text+lang -> Promise<clip>. Holding the PROMISE dedupes concurrent
  // requests: a pre-warm started by the relay and the app's own request for
  // the same line share one Addis call. Failures are evicted (retryable).
  const cache = new Map();
  const fail = (res) => {
    if (res.status === 401 || res.status === 403) return new ContractError("unavailable", "Speech provider rejected the credentials.", 503);
    if (res.status === 402) return new ContractError("unavailable", "Speech credits are used up.", 503);
    if (res.status === 429) return new ContractError("rate_limited", "Speech service busy.", 429);
    return new ContractError("provider_error", `Speech provider error ${res.status}`, 502);
  };
  const requestId = (p) => `${p}-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;

  // Fast path: the streaming endpoint delivers the whole clip in ~3 s where
  // the one-shot endpoint takes 4-13 s (measured on Addis, 2026-11-21).
  async function viaStream(text, language) {
    const res = await fetchImpl(`${BASE}/voice/generations/stream`, {
      method: "POST",
      headers: { "content-type": "application/json", "x-api-key": apiKey },
      body: JSON.stringify({ text, voice_id: VOICES[language], language, output_format: "mp3_44100", client_request_id: requestId("tts") }),
      signal: AbortSignal.timeout(20_000),
    });
    if (!res.ok) throw fail(res);
    const { mp3, meta } = unframeMp3Stream(Buffer.from(await res.arrayBuffer()));
    if (mp3.length < 200) throw new ContractError("provider_error", "No audio returned.", 502);
    const pcm = await decode(mp3);
    // The Professor's voice: pitched down (older, deeper), same tempo and
    // length, so the loudness envelope still lines up. Needs ffmpeg.
    const deep = (await deepen(mp3)) ?? mp3;
    const env = pcm ? pcmEnvelope(pcm, 16000) : null;
    return {
      mimeType: "audio/mpeg",
      audioBase64: deep.toString("base64"),
      durationSeconds: meta?.duration_seconds ?? null,
      envelope: env ? { ...env, source: "pcm" } : mp3GainEnvelope(mp3),
    };
  }

  async function viaOneShot(text, language) {
    const res = await fetchImpl(`${BASE}/voice/generations`, {
      method: "POST",
      headers: { "content-type": "application/json", "x-api-key": apiKey },
      body: JSON.stringify({
        text,
        voice_id: VOICES[language],
        language,
        output_format: "pcm_16000", // returned as a 16 kHz WAV we can measure directly
        client_request_id: requestId("tts"),
      }),
      signal: AbortSignal.timeout(25_000),
    });
    if (!res.ok) throw fail(res);
    const d = (await res.json())?.data;
    const dataUrl = typeof d?.audio === "string" ? d.audio : null;
    if (!dataUrl?.startsWith("data:")) throw new ContractError("provider_error", "No audio returned.", 502);
    const [meta, b64] = dataUrl.split(",", 2);
    const mimeType = meta.slice(5).split(";")[0] || "audio/wav";
    const envelope = mimeType.includes("wav") ? wavEnvelope(Buffer.from(b64, "base64")) : null;
    return { mimeType, audioBase64: b64, durationSeconds: d.duration_seconds ?? null, envelope };
  }

  async function produce(text, language) {
    try {
      return await viaStream(text, language);
    } catch (e) {
      // Credentials/credits problems won't be fixed by the other endpoint.
      if (e instanceof ContractError && e.code === "unavailable") throw e;
      try {
        return await viaOneShot(text, language);
      } catch (e2) {
        if (e2 instanceof ContractError) throw e2;
        throw new ContractError("unavailable", "Speech provider unreachable.", 503);
      }
    }
  }

  function synthesize(text, language) {
    if (!(language in VOICES)) return Promise.reject(new ContractError("bad_request", "Synthesis supports am and om only."));
    const clean = String(text ?? "").trim().slice(0, 600);
    if (!clean) return Promise.reject(new ContractError("bad_request", "Empty text."));
    const key = `${language}:${clean}`;
    if (cache.has(key)) return cache.get(key);
    const p = produce(clean, language);
    cache.set(key, p);
    if (cache.size > 200) cache.delete(cache.keys().next().value);
    p.catch(() => { if (cache.get(key) === p) cache.delete(key); });
    return p;
  }

  return {
    name: "addis",
    synthesize,
    /// Starts synthesis without waiting (the app will ask for it shortly).
    prewarm(text, language) {
      synthesize(text, language).catch(() => {});
    },
    async transcribe(bytes, language, contentType = "audio/wav") {
      if (!["am", "om", "en"].includes(language)) throw new ContractError("bad_request", "language must be am, om or en.");
      const form = new FormData();
      form.append("audio", new Blob([bytes], { type: contentType }), "speech.wav");
      const url = `${BASE}/scribe/transcribe?language=${language}&request_id=${requestId("stt")}`;
      const res = await fetchImpl(url, { method: "POST", headers: { "x-api-key": apiKey }, body: form, signal: AbortSignal.timeout(30_000) })
        .catch(() => { throw new ContractError("unavailable", "Speech provider unreachable.", 503); });
      if (!res.ok) throw fail(res);
      const text = (await res.json())?.data?.text;
      if (typeof text !== "string") throw new ContractError("provider_error", "No transcript returned.", 502);
      return { text: text.trim(), language };
    },
  };
}
