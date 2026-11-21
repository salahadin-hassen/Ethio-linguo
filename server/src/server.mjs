import http from "node:http";
import { ContractError, parseTurnRequest } from "./contract.mjs";
import { createAnthropicProvider } from "./providers/anthropic.mjs";

// Stateless tutor relay. Privacy: receives TEXT only (speech is recognised on
// the device), keeps nothing, and never logs utterances or replies.
export function createServer({ provider, allowOrigin = process.env.ALLOW_ORIGIN || "*" } = {}) {
  return http.createServer(async (req, res) => {
    const send = (status, body) => {
      res.writeHead(status, {
        "content-type": "application/json; charset=utf-8",
        "access-control-allow-origin": allowOrigin,
        "access-control-allow-headers": "content-type",
        "access-control-allow-methods": "GET, POST, OPTIONS",
      });
      res.end(body === undefined ? "" : JSON.stringify(body));
    };
    try {
      if (req.method === "OPTIONS") return send(204);
      if (req.method === "GET" && req.url === "/v1/health") {
        return send(200, { ok: Boolean(provider), provider: provider?.name ?? null, model: provider?.model ?? null, contract: 1 });
      }
      if (req.method === "POST" && req.url === "/v1/tutor/turn") {
        if (!provider) throw new ContractError("unavailable", "No tutor provider configured.", 503);
        let raw = "";
        for await (const chunk of req) {
          raw += chunk;
          if (raw.length > 32_000) throw new ContractError("bad_request", "Body too large", 413);
        }
        let body;
        try { body = JSON.parse(raw); } catch { throw new ContractError("bad_request", "Invalid JSON"); }
        const turn = parseTurnRequest(body);
        const started = Date.now();
        const out = await provider.turn(turn);
        console.log(`turn ok session=${turn.sessionId.slice(0, 8)} ms=${Date.now() - started}`); // no content logged
        return send(200, { ...out, speech: null });
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
  const provider = process.env.ANTHROPIC_API_KEY ? createAnthropicProvider() : null;
  if (!provider) console.warn("ANTHROPIC_API_KEY not set: /v1/health reports ok=false and turns return 503.");
  const port = Number(process.env.PORT || 8787);
  createServer({ provider }).listen(port, "0.0.0.0", () => console.log(`tutor relay on :${port} provider=${provider?.name ?? "none"} model=${provider?.model ?? "-"}`));
}
