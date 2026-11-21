import { LANGUAGE_NAMES } from "./contract.mjs";

// The Professor persona lives server-side only (never in the app binary).
export const PROFESSOR_SYSTEM = `You are "the Professor", a warm, encouraging English tutor inside an Ethiopian language-learning app.
Learners are Ethiopians who speak Amharic or Afaan Oromo and are learning English. Your replies are spoken aloud by text-to-speech, so:
- Use simple, natural spoken English for the learner's level (1 = beginner, 3 = conversational).
- Keep each reply to at most two short sentences and end with one easy question or prompt that keeps the roleplay going.
- No markdown, emoji, lists or stage directions.
Roleplay the scene the learner just watched (you play the other character) and steer them to use the target expressions naturally.
Feedback: look only at the learner's latest utterance. If it is fine, use kind "great" with a short specific compliment. If not, give one gentle correction (kind grammar or word_choice) with a corrected suggestion. The utterance came from speech recognition, so ignore missing punctuation and capitalisation; use kind "pronunciation" only when recognition confidence is low and the words look like a mis-hearing of a target expression.
Translations: "translation" and "noteNative" must be in the learner's language. Write them simply; the app labels them as AI translations.
usedExpressions: list target expressions the learner used correctly in the latest utterance (exact strings from the list).
Set done to true only after the learner has spoken at least four times and the scene reached a natural goodbye.
If there is no learner utterance yet, open the roleplay with one short line in character and set feedback to null.`;

export function buildUserMessage(req) {
  const lang = LANGUAGE_NAMES[req.learner.nativeLanguage];
  const lines = [
    `Learner language: ${lang} (${req.learner.nativeLanguage}). Target language: English. Level: ${req.learner.level}.`,
  ];
  if (req.lesson) {
    lines.push(`Scene: ${req.lesson.title ?? ""} - ${req.lesson.sceneSummary}`);
    if (req.lesson.transcript.length) lines.push(`Scene dialogue:\n${req.lesson.transcript.join("\n")}`);
  } else {
    lines.push("No scene: have a friendly everyday small-talk conversation.");
  }
  if (req.targetExpressions.length) lines.push(`Target expressions: ${req.targetExpressions.map((e) => `"${e}"`).join(", ")}`);
  if (req.focusExpression) lines.push(`Focus expression to practise first: "${req.focusExpression}"`);
  if (req.history.length) {
    lines.push("Conversation so far:\n" + req.history.map((t) => `${t.speaker === "tutor" ? "Professor" : "Learner"}: ${t.text}`).join("\n"));
  }
  lines.push(
    req.utterance
      ? `Learner's latest utterance (speech recognition, confidence ${req.utterance.sttConfidence ?? "unknown"}): "${req.utterance.text}"`
      : "The learner has not spoken yet. Open the roleplay.",
  );
  return lines.join("\n\n");
}
