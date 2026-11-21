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
