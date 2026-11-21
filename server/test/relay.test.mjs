import { test } from "node:test";
import assert from "node:assert/strict";
import { createServer } from "../src/server.mjs";
import { parseTurnRequest } from "../src/contract.mjs";

const fakeProvider = {
  name: "fake", model: "fake-1",
  async turn(req) {
    return { reply: { text: `echo ${req.utterance?.text ?? "open"}`, translation: "-" }, feedback: null, suggestedExpression: null, usedExpressions: [], done: false };
  },
};
async function withServer(provider, fn) {
  const server = createServer({ provider }).listen(0);
  await new Promise((r) => server.once("listening", r));
  try { await fn(`http://127.0.0.1:${server.address().port}`); } finally { server.close(); }
}

test("health reports provider", () => withServer(fakeProvider, async (base) => {
  const body = await (await fetch(`${base}/v1/health`)).json();
  assert.deepEqual([body.ok, body.provider], [true, "fake"]);
}));

test("turn returns provider output with speech:null", () => withServer(fakeProvider, async (base) => {
  const res = await fetch(`${base}/v1/tutor/turn`, { method: "POST", body: JSON.stringify({ learner: { nativeLanguage: "am" }, utterance: { text: "hi" } }) });
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.reply.text, "echo hi");
  assert.equal(body.speech, null);
}));

test("no provider -> 503 unavailable", () => withServer(null, async (base) => {
  const res = await fetch(`${base}/v1/tutor/turn`, { method: "POST", body: "{}" });
  assert.equal(res.status, 503);
  assert.equal((await res.json()).error.code, "unavailable");
}));

test("bad language -> 400", () => {
  assert.throws(() => parseTurnRequest({ learner: { nativeLanguage: "fr" } }), /nativeLanguage/);
});

test("request is clamped and sanitised", () => {
  const r = parseTurnRequest({ learner: { nativeLanguage: "om", level: 9 }, history: Array(40).fill({ speaker: "learner", text: "x" }), targetExpressions: [1, "Sounds good"] });
  assert.equal(r.learner.level, 3);
  assert.equal(r.history.length, 12);
  assert.deepEqual(r.targetExpressions, ["Sounds good"]);
});

import { parseAddisReply, buildAddisPrompt, createAddisProvider } from "../src/providers/addis.mjs";

const addisReq = parseTurnRequest({
  learner: { nativeLanguage: "am", level: 1 },
  lesson: { sceneSummary: "Two friends meet at a bus stop.", transcript: ["Liya: Long time no see!"] },
  targetExpressions: ["Long time no see"],
  utterance: { text: "long time no see i been busy" },
});

test("addis prompt carries scene, targets and the learner utterance", () => {
  const p = buildAddisPrompt(addisReq);
  for (const s of ["bus stop", "Long time no see", "i been busy", "Amharic", "JSON"]) assert.ok(p.includes(s), s);
});

test("addis reply in a code fence is parsed and mapped to the contract", () => {
  const text = '```json\n{"reply":"Nice!","translation":"ጥሩ!","feedback_kind":"grammar","note":"Say I have been.","note_native":"…","suggestion":"I have been busy.","used":["Long time no see","bogus"]}\n```';
  const out = parseAddisReply(text, addisReq);
  assert.equal(out.reply.text, "Nice!");
  assert.equal(out.feedback.kind, "grammar");
  assert.equal(out.feedback.suggestion, "I have been busy.");
  assert.deepEqual(out.usedExpressions, ["Long time no see"]);
});

test("addis non-JSON reply -> provider_error, bad key -> unavailable", async () => {
  assert.throws(() => parseAddisReply("sorry", addisReq), /unreadable/);
  const p = createAddisProvider({ apiKey: "x", fetchImpl: async () => new Response("{}", { status: 401 }) });
  await assert.rejects(p.turn(addisReq), (e) => e.code === "unavailable");
});

test("addis teaching fields are mapped (coach, task, hint)", () => {
  const text = '{"reply":"Hi!","translation":"ሰላም","coach":"ይህ ሰላምታ ነው።","task_type":"repeat","task_prompt":"Long time no see!","task_prompt_native":"ከተያየን ቆየን!","hint":"Long time no see, Liya!","feedback_kind":"great","note":"Good","used":[]}';
  const out = parseAddisReply(text, addisReq);
  assert.equal(out.coach, "ይህ ሰላምታ ነው።");
  assert.deepEqual(out.task, { type: "repeat", prompt: "Long time no see!", promptNative: "ከተያየን ቆየን!" });
  assert.equal(out.hint, "Long time no see, Liya!");
});

test("native-language question gets no grammar feedback", () => {
  const q = parseTurnRequest({ learner: { nativeLanguage: "am" }, utterance: { text: "ምን ማለት ነው?", language: "am" } });
  assert.equal(q.utterance.language, "am");
  assert.match(buildAddisPrompt(q), /asked a question/);
  const out = parseAddisReply('{"reply":"x","coach":"y","feedback_kind":"grammar","note":"z"}', q);
  assert.equal(out.feedback, null);
});

test("speech routes: synthesize + transcribe via provider; 503 without", async () => {
  const speech = {
    async synthesize(text, language) { return { mimeType: "audio/mpeg", audioBase64: "AAAA", durationSeconds: 1, text, language }; },
    async transcribe(bytes, language) { return { text: `got ${bytes.length}`, language }; },
  };
  await withServerSpeech(speech, async (base) => {
    const a = await (await fetch(`${base}/v1/speech/synthesize`, { method: "POST", body: JSON.stringify({ text: "ሰላም", language: "am" }) })).json();
    assert.equal(a.audioBase64, "AAAA");
    const t = await (await fetch(`${base}/v1/speech/transcribe?language=om`, { method: "POST", headers: { "content-type": "audio/wav" }, body: new Uint8Array(2000) })).json();
    assert.deepEqual(t, { text: "got 2000", language: "om" });
  });
  await withServerSpeech(null, async (base) => {
    const r = await fetch(`${base}/v1/speech/synthesize`, { method: "POST", body: "{}" });
    assert.equal(r.status, 503);
  });
});

async function withServerSpeech(speech, fn) {
  const server = createServer({ provider: fakeProvider, speech }).listen(0);
  await new Promise((r) => server.once("listening", r));
  try { await fn(`http://127.0.0.1:${server.address().port}`); } finally { server.close(); }
}

test("wavEnvelope: per-frame loudness of a PCM16 WAV, 0..1, silence stays shut", async () => {
  const { wavEnvelope } = await import("../src/providers/addis_speech.mjs");
  const rate = 16000, n = rate; // 1 s: 0.5 s silence then 0.5 s tone
  const pcm = Buffer.alloc(n * 2);
  for (let i = n / 2; i < n; i++) pcm.writeInt16LE(Math.round(Math.sin(i / 8) * 12000), i * 2);
  const h = Buffer.alloc(44);
  h.write("RIFF", 0); h.writeUInt32LE(36 + pcm.length, 4); h.write("WAVE", 8);
  h.write("fmt ", 12); h.writeUInt32LE(16, 16); h.writeUInt16LE(1, 20); h.writeUInt16LE(1, 22);
  h.writeUInt32LE(rate, 24); h.writeUInt32LE(rate * 2, 28); h.writeUInt16LE(2, 32); h.writeUInt16LE(16, 34);
  h.write("data", 36); h.writeUInt32LE(pcm.length, 40);
  const env = wavEnvelope(Buffer.concat([h, pcm]), 50);
  assert.equal(env.frameMs, 50);
  assert.equal(env.values.length, 20);
  assert.ok(env.values.slice(0, 10).every((v) => v === 0));
  assert.ok(env.values.slice(11).every((v) => v > 0.9 && v <= 1));
  assert.equal(wavEnvelope(Buffer.from("not a wav")), null);
});

test("streaming turn: reply event first, then the full turn; coach voice pre-warmed", async () => {
  const warmed = [];
  const provider = {
    name: "fake", model: "fake-1",
    async turn(req, { onReply } = {}) {
      onReply?.("Nice to see you!");
      return { reply: { text: "Nice to see you!", translation: "-" }, coach: "ጥሩ ነው።", feedback: null, suggestedExpression: null, usedExpressions: [], done: false };
    },
  };
  const speech = { prewarm: (t, l) => warmed.push(`${l}:${t}`) };
  const server = createServer({ provider, speech }).listen(0);
  await new Promise((r) => server.once("listening", r));
  try {
    const base = `http://127.0.0.1:${server.address().port}`;
    const res = await fetch(`${base}/v1/tutor/turn/stream`, { method: "POST", body: JSON.stringify({ learner: { nativeLanguage: "am" }, utterance: { text: "hi" }, voice: true }) });
    assert.equal(res.status, 200);
    assert.match(res.headers.get("content-type"), /ndjson/);
    const events = (await res.text()).trim().split("\n").map((l) => JSON.parse(l));
    assert.deepEqual(events.map((e) => e.type), ["reply", "turn"]);
    assert.equal(events[0].text, "Nice to see you!");
    assert.equal(events[1].turn.coach, "ጥሩ ነው።");
    assert.deepEqual(warmed, ["am:ጥሩ ነው።"]);
    // without voice:true nothing is synthesised (no wasted credits)
    await (await fetch(`${base}/v1/tutor/turn/stream`, { method: "POST", body: JSON.stringify({ learner: { nativeLanguage: "am" }, utterance: { text: "hi" } }) })).text();
    assert.equal(warmed.length, 1);
  } finally { server.close(); }
});

test("streaming turn: provider failure becomes an error event", () => withServer({
  name: "fake", model: "x",
  async turn() { const { ContractError } = await import("../src/contract.mjs"); throw new ContractError("rate_limited", "busy", 429); },
}, async (base) => {
  const res = await fetch(`${base}/v1/tutor/turn/stream`, { method: "POST", body: JSON.stringify({ learner: { nativeLanguage: "am" } }) });
  const events = (await res.text()).trim().split("\n").map((l) => JSON.parse(l));
  assert.deepEqual(events, [{ type: "error", error: { code: "rate_limited", message: "busy" } }]);
}));

test("addis: reply extracted from partial JSON; 'great' with a correction becomes grammar", async () => {
  const { completedReply, parseAddisReply } = await import("../src/providers/addis.mjs");
  assert.equal(completedReply('```json\n{"reply": "Hi \\"there\\"!", "transl'), 'Hi "there"!');
  assert.equal(completedReply('{"reply": "Hi the'), null);
  const req = parseTurnRequest({ learner: { nativeLanguage: "am" }, utterance: { text: "i been busy", language: "en" } });
  const fixed = parseAddisReply(JSON.stringify({ reply: "Oh?", feedback_kind: "great", note: "Say have been.", suggestion: "I have been busy." }), req);
  assert.equal(fixed.feedback.kind, "grammar");
  assert.equal(fixed.feedback.suggestion, "I have been busy.");
  const same = parseAddisReply(JSON.stringify({ reply: "Good!", feedback_kind: "great", note: "Perfect.", suggestion: "I been busy" }), req);
  assert.equal(same.feedback.kind, "great");
});

test("addis provider: streams the reply early, falls back to one-shot when streaming is unavailable", async () => {
  const { createAddisProvider } = await import("../src/providers/addis.mjs");
  const json = JSON.stringify({ reply: "Hello again!", translation: "ሰላም", coach: "ይድገሙ።", task_type: "repeat", task_prompt: "Hello again!", feedback_kind: "none", used: [], done: false });
  const sse = (text) => new Response(new ReadableStream({
    start(c) {
      const enc = new TextEncoder();
      for (const piece of [text.slice(0, 30), text.slice(30)]) c.enqueue(enc.encode(`data: ${JSON.stringify({ choices: [{ delta: { content: piece } }] })}\n\n`));
      c.enqueue(enc.encode("data: [DONE]\n\n"));
      c.close();
    },
  }), { status: 200, headers: { "content-type": "text/event-stream" } });
  const calls = [];
  const streaming = createAddisProvider({ apiKey: "k", fetchImpl: async (url) => { calls.push(url); return sse(json); } });
  const req = parseTurnRequest({ learner: { nativeLanguage: "am" } });
  let early = null;
  const out = await streaming.turn(req, { onReply: (t) => { early = t; } });
  assert.equal(early, "Hello again!");
  assert.equal(out.task.prompt, "Hello again!");
  assert.match(calls[0], /\/v1\/chat\/completions$/);
  const fallback = createAddisProvider({ apiKey: "k", fetchImpl: async (url) => url.endsWith("/chat/completions")
    ? new Response("{}", { status: 404 })
    : Response.json({ data: { response_text: json } }) });
  assert.equal((await fallback.turn(req)).reply.text, "Hello again!");
});

test("speech: unframes Addis mp3 stream, dedupes in-flight requests, falls back to one-shot", async () => {
  const { createAddisSpeech, unframeMp3Stream } = await import("../src/providers/addis_speech.mjs");
  const frame = (b) => { const h = Buffer.alloc(4); h.writeUInt32BE(b.length); return Buffer.concat([h, b]); };
  const audio = Buffer.alloc(400, 0x55);
  const body = Buffer.concat([frame(audio.subarray(0, 250)), frame(audio.subarray(250)), Buffer.alloc(4), frame(Buffer.from(JSON.stringify({ data: { duration_seconds: 1.5 } })))]);
  const u = unframeMp3Stream(body);
  assert.equal(u.mp3.length, 400);
  assert.equal(u.meta.duration_seconds, 1.5);
  let calls = 0;
  const speech = createAddisSpeech({ apiKey: "k", decode: async () => Buffer.alloc(3200), fetchImpl: async () => { calls++; return new Response(body, { status: 200 }); } });
  const [a, b] = await Promise.all([speech.synthesize("ሰላም", "am"), speech.synthesize("ሰላም", "am")]);
  assert.equal(calls, 1, "pre-warm and the app's request share one provider call");
  assert.equal(a, b);
  assert.equal(a.mimeType, "audio/mpeg");
  assert.equal(a.durationSeconds, 1.5);
  assert.equal(a.envelope.source, "pcm");
  const oneShotWav = (() => { const h = Buffer.alloc(44); h.write("RIFF", 0); h.write("WAVE", 8); h.write("fmt ", 12); h.writeUInt32LE(16, 16); h.writeUInt16LE(1, 20); h.writeUInt16LE(1, 22); h.writeUInt32LE(16000, 24); h.writeUInt16LE(16, 34); h.write("data", 36); h.writeUInt32LE(3200, 40); return Buffer.concat([h, Buffer.alloc(3200)]); })();
  const fb = createAddisSpeech({ apiKey: "k", fetchImpl: async (url) => url.endsWith("/stream")
    ? new Response("", { status: 500 })
    : Response.json({ data: { audio: `data:audio/wav;base64,${oneShotWav.toString("base64")}`, duration_seconds: 0.1 } }) });
  const c = await fb.synthesize("ሰላም", "am");
  assert.equal(c.mimeType, "audio/wav");
  assert.equal(c.envelope.values.length, 2);
});
