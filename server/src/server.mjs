import http from "node:http";
import net from "node:net";
import { ContractError, parseTurnRequest } from "./contract.mjs";
import { createAddisProvider } from "./providers/addis.mjs";
import { createAddisSpeech } from "./providers/addis_speech.mjs";
import { createAnthropicProvider } from "./providers/anthropic.mjs";

async function readBody(req, max) {
  const chunks = [];
  let n = 0;
  for await (const c of req) {
    n += c.length;
    if (n > max) throw new ContractError("bad_request", "Body too large", 413);
    chunks.push(c);
  }
  return Buffer.concat(chunks);
}

// Stateless tutor relay. Privacy: tutor turns carry TEXT only. The optional
// /v1/speech/transcribe route forwards a learner's native-language question
// audio to the speech provider once; nothing is stored or logged.
export function createServer({ provider, speech = null, allowOrigin = process.env.ALLOW_ORIGIN || "*" } = {}) {
  return http.createServer(async (req, res) => {
    const send = (status, body) => {
      res.writeHead(status, {
        "content-type": "application/json; charset=utf-8",
        "access-control-allow-origin": allowOrigin,
        "access-control-allow-headers": "content-type, x-language",
        "access-control-allow-methods": "GET, POST, OPTIONS",
      });
      res.end(body === undefined ? "" : JSON.stringify(body));
    };
    try {
      if (req.method === "OPTIONS") return send(204);
      if (req.method === "GET" && req.url === "/v1/health") {
        return send(200, {
          ok: Boolean(provider),
          provider: provider?.name ?? null,
          model: provider?.model ?? null,
          contract: 1,
          streaming: true, // POST /v1/tutor/turn/stream (NDJSON)
          speech: speech ? { synthesize: ["am", "om"], transcribe: ["am", "om", "en"] } : null,
        });
      }
      if (req.method === "POST" && (req.url === "/v1/tutor/turn" || req.url === "/v1/tutor/turn/stream")) {
        if (!provider) throw new ContractError("unavailable", "No tutor provider configured.", 503);
        let body;
        try { body = JSON.parse((await readBody(req, 32_000)).toString("utf8")); } catch (e) {
          if (e instanceof ContractError) throw e;
          throw new ContractError("bad_request", "Invalid JSON");
        }
        const turn = parseTurnRequest(body);
        // The app will speak the coaching line in the learner's language:
        // start that synthesis now so it is ready when the English ends.
        const prewarm = (out) => {
          if (body.voice === true && speech?.prewarm && out.coach) speech.prewarm(out.coach, turn.learner.nativeLanguage);
        };
        const started = Date.now();
        if (req.url === "/v1/tutor/turn") {
          const out = await provider.turn(turn);
          prewarm(out);
          console.log(`turn ok session=${turn.sessionId.slice(0, 8)} ms=${Date.now() - started}`); // no content logged
          return send(200, { ...out, speech: null });
        }
        // Streaming: NDJSON events. "reply" as soon as the Professor's line
        // is known (the app starts speaking it), then the full "turn".
        res.writeHead(200, {
          "content-type": "application/x-ndjson; charset=utf-8",
          "cache-control": "no-store",
          "x-accel-buffering": "no",
          "access-control-allow-origin": allowOrigin,
          "access-control-allow-headers": "content-type, x-language",
          "access-control-allow-methods": "GET, POST, OPTIONS",
        });
        res.flushHeaders?.();
        const event = (e) => res.write(JSON.stringify(e) + "\n");
        let replyMs = null;
        try {
          const out = await provider.turn(turn, {
            onReply: (text) => {
              replyMs = Date.now() - started;
              event({ type: "reply", text });
            },
          });
          prewarm(out);
          event({ type: "turn", turn: { ...out, speech: null } });
          console.log(`turn ok stream session=${turn.sessionId.slice(0, 8)} replyMs=${replyMs ?? "-"} ms=${Date.now() - started}`);
        } catch (e) {
          const err = e instanceof ContractError ? e : new ContractError("provider_error", "Unexpected relay error", 500);
          console.log(`turn failed stream session=${turn.sessionId.slice(0, 8)} code=${err.code} ms=${Date.now() - started}`);
          event({ type: "error", error: { code: err.code, message: err.message } });
        }
        return res.end();
      }
      if (req.method === "POST" && req.url === "/v1/speech/synthesize") {
        if (!speech) throw new ContractError("unavailable", "No speech provider configured.", 503);
        const body = JSON.parse((await readBody(req, 8_000)).toString("utf8") || "{}");
        const clip = await speech.synthesize(String(body.text ?? ""), body.language);
        // no content logged: language, duration and envelope size only
        console.log(`synth ok lang=${body.language} s=${clip.durationSeconds ?? "?"} envelopeFrames=${clip.envelope?.values?.length ?? 0}`);
        return send(200, clip);
      }
      if (req.method === "POST" && req.url.startsWith("/v1/speech/transcribe")) {
        if (!speech) throw new ContractError("unavailable", "No speech provider configured.", 503);
        const lang = new URL(req.url, "http://x").searchParams.get("language") ?? "am";
        const audio = await readBody(req, 8_000_000);
        if (audio.length < 1000) throw new ContractError("bad_request", "Recording too short.");
        // Audio is forwarded once and never stored or logged.
        return send(200, await speech.transcribe(audio, lang, req.headers["content-type"] || "audio/wav"));
      }
      send(404, { error: { code: "not_found", message: "Unknown route" } });
    } catch (error) {
      if (error instanceof ContractError) return send(error.status, { error: { code: error.code, message: error.message } });
      console.error("relay error:", error?.name);
      send(500, { error: { code: "provider_error", message: "Unexpected relay error" } });
    }
  });
}

if (import.meta.url === `file://${process.argv[1]}`) {
  // Slow/high-latency networks (venue Wi-Fi, tethering): Node's default
  // happy-eyeballs gives each address only 250 ms to connect, so every Addis
  // call failed with ETIMEDOUT where a TCP connect takes ~0.5-4 s. Measured
  // 2026-11-21: 0/2 succeed at 250 ms, 2/2 at 3000 ms.
  net.setDefaultAutoSelectFamilyAttemptTimeout(Number(process.env.CONNECT_ATTEMPT_MS || 3000));
  // TUTOR_PROVIDER=addis|anthropic (default: whichever key is present, Addis first).
  const choice = process.env.TUTOR_PROVIDER || (process.env.ADDIS_API_KEY ? "addis" : "anthropic");
  const provider =
    choice === "addis" && process.env.ADDIS_API_KEY ? createAddisProvider()
    : choice === "anthropic" && process.env.ANTHROPIC_API_KEY ? createAnthropicProvider()
    : null;
  if (!provider) console.warn(`No credentials for provider "${choice}": /v1/health reports ok=false and turns return 503.`);
  const port = Number(process.env.PORT || 8787);
  const speech = process.env.ADDIS_API_KEY ? createAddisSpeech() : null;
  createServer({ provider, speech }).listen(port, "0.0.0.0", () => console.log(`tutor relay on :${port} provider=${provider?.name ?? "none"} model=${provider?.model ?? "-"}`));
}
