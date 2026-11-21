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
