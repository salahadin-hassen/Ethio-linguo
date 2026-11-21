// Tutor relay contract v1 - mirrors docs/INTEGRATION_CONTRACTS.md §7.
// Provider-independent: providers receive a validated TutorTurnRequest and
// must return a TutorTurnResponse. Nothing provider-specific leaks out.

export const LANGUAGE_NAMES = { am: "Amharic", om: "Afaan Oromo", en: "English" };

export class ContractError extends Error {
  constructor(code, message, status = 400) {
    super(message);
    this.code = code;
    this.status = status;
  }
}

const str = (v, max) => (typeof v === "string" ? v.slice(0, max) : undefined);

/** Validates and normalises an incoming request body (untrusted input). */
export function parseTurnRequest(body) {
  if (!body || typeof body !== "object") throw new ContractError("bad_request", "JSON body required");
  const lang = body.learner?.nativeLanguage;
  if (!(lang in LANGUAGE_NAMES) || lang === "en") {
    throw new ContractError("bad_request", "learner.nativeLanguage must be 'am' or 'om'");
  }
  const history = Array.isArray(body.history) ? body.history.slice(-12) : [];
  return {
    sessionId: str(body.sessionId, 64) ?? "anon",
    character: body.character === "professor" ? "professor" : "professor",
    learner: {
      nativeLanguage: lang,
      targetLanguage: "en",
      level: Number.isInteger(body.learner?.level) ? Math.min(Math.max(body.learner.level, 1), 3) : 1,
    },
    lesson: body.lesson
      ? {
          contentId: str(body.lesson.contentId, 80),
          title: str(body.lesson.title, 120),
          sceneSummary: str(body.lesson.sceneSummary, 600) ?? "",
          transcript: (Array.isArray(body.lesson.transcript) ? body.lesson.transcript : [])
            .slice(0, 20)
            .map((l) => str(l, 200))
            .filter(Boolean),
        }
      : null,
    focusExpression: str(body.focusExpression, 120) ?? null,
    targetExpressions: (Array.isArray(body.targetExpressions) ? body.targetExpressions : [])
      .slice(0, 8)
      .map((e) => str(e, 120))
      .filter(Boolean),
    history: history
      .filter((t) => (t?.speaker === "tutor" || t?.speaker === "learner") && typeof t.text === "string")
      .map((t) => ({ speaker: t.speaker, text: t.text.slice(0, 500) })),
    utterance: body.utterance && typeof body.utterance.text === "string"
      ? { text: body.utterance.text.slice(0, 500), sttConfidence: typeof body.utterance.sttConfidence === "number" ? body.utterance.sttConfidence : null }
      : null,
  };
}

/** JSON Schema for the provider's structured output (= response body minus envelope). */
export const TURN_OUTPUT_SCHEMA = {
  type: "object",
  additionalProperties: false,
  required: ["reply", "feedback", "usedExpressions", "done"],
  properties: {
    reply: {
      type: "object",
      additionalProperties: false,
      required: ["text", "translation"],
      properties: {
        text: { type: "string", description: "What the Professor says, in simple English, max 2 short sentences." },
        translation: { type: "string", description: "The same reply in the learner's language." },
      },
    },
    feedback: {
      anyOf: [
        { type: "null" },
        {
          type: "object",
          additionalProperties: false,
          required: ["kind", "note", "noteNative", "suggestion"],
          properties: {
            kind: { type: "string", enum: ["great", "grammar", "word_choice", "pronunciation"] },
            note: { type: "string" },
            noteNative: { type: "string" },
            suggestion: { anyOf: [{ type: "string" }, { type: "null" }] },
          },
        },
      ],
    },
    suggestedExpression: { anyOf: [{ type: "string" }, { type: "null" }] },
    usedExpressions: { type: "array", items: { type: "string" } },
    done: { type: "boolean" },
  },
};
