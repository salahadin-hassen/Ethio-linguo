import { ContractError, LANGUAGE_NAMES } from "../contract.mjs";

// Provider adapter for Addis AI (https://docs.addisassistant.com).
// The native chat_generate API takes a single prompt (system_prompt is not
// honoured), so the persona, scene and history are rendered into the prompt
// and the model is asked for a strict JSON object that we validate here.
const ENDPOINT = "https://api.addisassistant.com/api/v1/chat_generate";

export function buildAddisPrompt(req) {
  const lang = LANGUAGE_NAMES[req.learner.nativeLanguage];
  const lines = [
    `TASK: You are "the Professor", a warm English teacher helping a ${lang} speaker practise speaking ENGLISH (level ${req.learner.level} of 3).`,
  ];
  if (req.lesson) {
    lines.push(`Roleplay this scene; you play the other character and the learner plays one of them. Scene: ${req.lesson.sceneSummary}`);
    if (req.lesson.transcript.length) lines.push(`Original dialogue:\n${req.lesson.transcript.join("\n")}`);
  } else {
    lines.push("Have a friendly everyday small-talk conversation in English.");
  }
  if (req.targetExpressions.length) lines.push(`Encourage the learner to use: ${req.targetExpressions.map((e) => `"${e}"`).join(", ")}.`);
  if (req.focusExpression) lines.push(`Start by practising "${req.focusExpression}".`);
  if (req.history.length) {
    lines.push("Conversation so far:\n" + req.history.map((t) => `${t.speaker === "tutor" ? "Professor" : "Learner"}: ${t.text}`).join("\n"));
  }
  const noteRule = req.utterance
    ? `The learner just said (speech recognition, may lack punctuation): "${req.utterance.text}". Give one gentle tip about THAT sentence ("great" if it is fine).`
    : `The learner has not spoken yet: open the roleplay with one short line. Use feedback_kind "none".`;
  lines.push(noteRule);
  lines.push(`Reply ONLY with this JSON and nothing else:
{"reply": "<your answer in simple ENGLISH, max 2 short sentences, end with a question>", "translation": "<same answer in ${lang}>", "feedback_kind": "none or great or grammar or word_choice", "note": "<one short tip in ENGLISH>", "note_native": "<the tip in ${lang}>", "suggestion": "<the learner sentence corrected in English, or empty>", "used": [<target expressions the learner used correctly>], "done": false}`);
  return lines.join("\n\n");
}

export function parseAddisReply(text, req) {
  const cleaned = text.replace(/```(?:json)?/gi, "").trim();
  const start = cleaned.indexOf("{");
  const end = cleaned.lastIndexOf("}");
  let j;
  try {
    j = JSON.parse(cleaned.slice(start, end + 1));
  } catch {
    throw new ContractError("provider_error", "The tutor returned an unreadable answer. Try again.", 502);
  }
  if (typeof j.reply !== "string" || !j.reply.trim()) {
    throw new ContractError("provider_error", "The tutor returned an empty answer.", 502);
  }
  const kind = ["great", "grammar", "word_choice", "pronunciation"].includes(j.feedback_kind) ? j.feedback_kind : null;
  const hasNote = req.utterance && kind && typeof j.note === "string" && j.note.trim();
  return {
    reply: { text: j.reply.trim(), translation: typeof j.translation === "string" ? j.translation.trim() : "" },
    feedback: hasNote
      ? {
          kind,
          note: j.note.trim(),
          noteNative: typeof j.note_native === "string" ? j.note_native.trim() : "",
          suggestion: kind !== "great" && typeof j.suggestion === "string" && j.suggestion.trim() ? j.suggestion.trim() : null,
        }
      : null,
    suggestedExpression: null,
    usedExpressions: (Array.isArray(j.used) ? j.used : []).filter((e) => req.targetExpressions.includes(e)),
    done: j.done === true,
  };
}

export function createAddisProvider({ apiKey = process.env.ADDIS_API_KEY, fetchImpl = fetch } = {}) {
  return {
    name: "addis",
    model: "addis-chat_generate",
    async turn(req) {
      let res;
      try {
        res = await fetchImpl(ENDPOINT, {
          method: "POST",
          headers: { "content-type": "application/json", "x-api-key": apiKey },
          body: JSON.stringify({
            prompt: buildAddisPrompt(req),
            target_language: req.learner.nativeLanguage,
            generation_config: { temperature: 0.4, maxOutputTokens: 600 },
          }),
          signal: AbortSignal.timeout(20_000),
        });
      } catch {
        throw new ContractError("unavailable", "Tutor provider unreachable.", 503);
      }
      if (res.status === 401 || res.status === 403) throw new ContractError("unavailable", "Tutor provider rejected the credentials.", 503);
      if (res.status === 429) throw new ContractError("rate_limited", "The tutor is busy. Try again in a moment.", 429);
      if (!res.ok) throw new ContractError("provider_error", `Provider error ${res.status}`, 502);
      const body = await res.json().catch(() => null);
      const text = body?.data?.response_text;
      if (typeof text !== "string") throw new ContractError("provider_error", "Malformed provider response.", 502);
      return parseAddisReply(text, req);
    },
  };
}
