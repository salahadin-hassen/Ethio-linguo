import { ContractError, LANGUAGE_NAMES } from "../contract.mjs";

// Provider adapter for Addis AI (https://docs.addisassistant.com).
// The native chat_generate API takes a single prompt (system_prompt is not
// honoured), so the persona, scene and history are rendered into the prompt
// and the model is asked for a strict JSON object that we validate here.
const ENDPOINT = "https://api.addisassistant.com/api/v1/chat_generate";
// OpenAI-compatible streaming endpoint (used by the Addis SDK's
// chat.completions with stream: true). Lets the Professor start speaking as
// soon as the "reply" field has arrived, before the rest of the JSON.
const STREAM_ENDPOINT = "https://api.addisassistant.com/v1/chat/completions";

export function buildAddisPrompt(req) {
  const lang = LANGUAGE_NAMES[req.learner.nativeLanguage];
  const lines = [
    `TASK: You are "the Professor", a patient, encouraging English teacher for a ${lang} speaker (English level ${req.learner.level} of 3). The goal is that the learner SPEAKS English as much as possible and understands why.`,
    `Teaching method, one small step per turn:
1. MODEL: show a useful English sentence from the scene.
2. REPEAT: ask the learner to repeat it exactly (task type "repeat").
3. USE: ask a roleplay question they answer using the expression (task type "answer" or "use_expression").
4. CORRECT: if they make a mistake, explain briefly in ${lang}, then ask them to repeat the corrected sentence (task type "repeat").
Move on to the next target expression once one is used correctly.`,
  ];
  if (req.lesson) {
    lines.push(`Scene for the roleplay (you play the other character): ${req.lesson.sceneSummary}`);
    if (req.lesson.transcript.length) lines.push(`Original dialogue:\n${req.lesson.transcript.join("\n")}`);
  } else {
    lines.push("No scene: practise everyday greetings and small talk.");
  }
  if (req.targetExpressions.length) lines.push(`Target expressions to teach: ${req.targetExpressions.map((e) => `"${e}"`).join(", ")}.`);
  if (req.focusExpression) lines.push(`Start with "${req.focusExpression}".`);
  if (req.history.length) {
    lines.push("Conversation so far:\n" + req.history.map((t) => `${t.speaker === "tutor" ? "Professor" : "Learner"}: ${t.text}`).join("\n"));
  }
  if (!req.utterance) {
    lines.push(`The learner has not spoken yet. In "reply", greet them warmly in character and MODEL the first expression. In "coach", ONE short ${lang} sentence (max 15 words): what the expression means and to repeat it. Give a "repeat" task. feedback_kind "none".`);
  } else if (req.utterance.language !== "en") {
    lines.push(`The learner asked a question in ${lang}: "${req.utterance.text}". Answer it clearly in ${lang} in "coach", then give them an English sentence to practise. feedback_kind "none".`);
  } else {
    lines.push(`The learner just said in English (speech recognition, punctuation and capitals may be missing): "${req.utterance.text}". Judge THAT sentence only. Use feedback_kind "great" ONLY if it needs no correction (then "suggestion" is empty). Otherwise use "grammar" or "word_choice", put the corrected sentence in "suggestion", explain THEIR specific mistake in "coach" in ${lang}, and give a "repeat" task with the corrected sentence. Keep the roleplay going in "reply".`);
  }
  lines.push(`Reply ONLY with this JSON and nothing else:
{"reply": "<what you say in the roleplay, simple ENGLISH, max 2 short sentences>",
 "translation": "<reply translated into ${lang}>",
 "coach": "<teaching in ${lang}, spoken aloud: at most 2 SHORT sentences, max 20 words in total. Explain the meaning, grammar or their mistake, and what to say next>",
 "task_type": "repeat or answer or use_expression",
 "task_prompt": "<the exact English sentence to repeat, or the English question to answer>",
 "task_prompt_native": "<task_prompt in ${lang}>",
 "hint": "<a good example English answer for the task>",
 "feedback_kind": "none or great or grammar or word_choice",
 "note": "<short tip in ENGLISH about the learner sentence, or empty>",
 "note_native": "<the tip in ${lang}, or empty>",
 "suggestion": "<corrected learner sentence in English, or empty>",
 "used": [<target expressions the learner used correctly>],
 "done": false}`);
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
  let kind = ["great", "grammar", "word_choice", "pronunciation"].includes(j.feedback_kind) ? j.feedback_kind : null;
  // Guard: models sometimes say "great" while also writing a correction.
  // A suggestion that differs from what the learner said is a correction.
  const norm = (v) => String(v ?? "").toLowerCase().replace(/[^\p{L}\p{N}\s']/gu, " ").replace(/\s+/g, " ").trim();
  if (kind === "great" && req.utterance && typeof j.suggestion === "string" && norm(j.suggestion) && norm(j.suggestion) !== norm(req.utterance.text)) {
    kind = "grammar";
  }
  const hasNote = req.utterance && req.utterance.language === "en" && kind && typeof j.note === "string" && j.note.trim();
  const str = (v) => (typeof v === "string" ? v.trim() : "");
  const taskType = ["repeat", "answer", "use_expression"].includes(j.task_type) ? j.task_type : "answer";
  return {
    reply: { text: j.reply.trim(), translation: str(j.translation) },
    coach: str(j.coach),
    task: str(j.task_prompt) ? { type: taskType, prompt: str(j.task_prompt), promptNative: str(j.task_prompt_native) } : null,
    hint: str(j.hint),
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

/// Extracts the "reply" string once it is complete in a partial JSON text.
export function completedReply(partial) {
  const m = /"reply"\s*:\s*"((?:[^"\\]|\\.)*)"/.exec(partial);
  if (!m) return null;
  try { return JSON.parse(`"${m[1]}"`).trim() || null; } catch { return null; }
}

export function createAddisProvider({ apiKey = process.env.ADDIS_API_KEY, fetchImpl = fetch } = {}) {
  const generation = { temperature: 0.4, maxOutputTokens: 600 };

  async function oneShot(prompt, req) {
    let res;
    try {
      res = await fetchImpl(ENDPOINT, {
        method: "POST",
        headers: { "content-type": "application/json", "x-api-key": apiKey },
        body: JSON.stringify({ prompt, target_language: req.learner.nativeLanguage, generation_config: generation }),
        signal: AbortSignal.timeout(20_000),
      });
    } catch {
      throw new ContractError("unavailable", "Tutor provider unreachable.", 503);
    }
    if (res.status === 401 || res.status === 403) throw new ContractError("unavailable", "Tutor provider rejected the credentials.", 503);
    if (res.status === 402) throw new ContractError("unavailable", "Tutor credits are used up.", 503);
    if (res.status === 429) throw new ContractError("rate_limited", "The tutor is busy. Try again in a moment.", 429);
    if (!res.ok) throw new ContractError("provider_error", `Provider error ${res.status}`, 502);
    const body = await res.json().catch(() => null);
    const text = body?.data?.response_text;
    if (typeof text !== "string") throw new ContractError("provider_error", "Malformed provider response.", 502);
    return text;
  }

  /// Streams the completion; calls onReply(text) once the reply is complete.
  /// Returns the full text, or null if streaming is unavailable (caller then
  /// falls back to the one-shot endpoint).
  async function streamed(prompt, onReply) {
    let res;
    try {
      res = await fetchImpl(STREAM_ENDPOINT, {
        method: "POST",
        headers: { "content-type": "application/json", "x-api-key": apiKey },
        body: JSON.stringify({
          messages: [{ role: "user", content: prompt }],
          stream: true,
          temperature: generation.temperature,
          max_tokens: generation.maxOutputTokens,
        }),
        signal: AbortSignal.timeout(20_000),
      });
    } catch {
      return null;
    }
    if (res.status === 401 || res.status === 403) throw new ContractError("unavailable", "Tutor provider rejected the credentials.", 503);
    if (res.status === 402) throw new ContractError("unavailable", "Tutor credits are used up.", 503);
    if (!res.ok || !res.body) return null;
    let acc = "", buf = "", announced = false;
    try {
      const dec = new TextDecoder();
      for await (const chunk of res.body) {
        buf += dec.decode(chunk, { stream: true });
        let nl;
        while ((nl = buf.indexOf("\n")) >= 0) {
          const line = buf.slice(0, nl).trim();
          buf = buf.slice(nl + 1);
          if (!line.startsWith("data:")) continue;
          const data = line.slice(5).trim();
          if (!data || data === "[DONE]") continue;
          let piece = "";
          try { piece = JSON.parse(data)?.choices?.[0]?.delta?.content ?? ""; } catch { continue; }
          acc += piece;
          if (!announced && onReply) {
            const r = completedReply(acc);
            if (r) { announced = true; onReply(r); }
          }
        }
      }
    } catch {
      // Stream broke mid-way: use what arrived if it parses, else fall back.
    }
    return acc || null;
  }

  return {
    name: "addis",
    model: "addis-chat_generate",
    async turn(req, { onReply } = {}) {
      const prompt = buildAddisPrompt(req);
      const text = (await streamed(prompt, onReply)) ?? (await oneShot(prompt, req));
      try {
        return parseAddisReply(text, req);
      } catch (e) {
        // One retry: occasionally the model returns malformed JSON.
        if (!(e instanceof ContractError) || e.code !== "provider_error") throw e;
        return parseAddisReply(await oneShot(prompt, req), req);
      }
    },
  };
}
