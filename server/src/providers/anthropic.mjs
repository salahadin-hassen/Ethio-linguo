import Anthropic from "@anthropic-ai/sdk";
import { ContractError, TURN_OUTPUT_SCHEMA } from "../contract.mjs";
import { PROFESSOR_SYSTEM, buildUserMessage } from "../prompt.mjs";

// Provider adapter: TutorTurnRequest -> Anthropic Messages API -> TutorTurnResponse.
export function createAnthropicProvider({ model = process.env.TUTOR_MODEL || "claude-opus-5-5", client } = {}) {
  const anthropic = client ?? new Anthropic(); // reads ANTHROPIC_API_KEY from the server environment
  return {
    name: "anthropic",
    model,
    async turn(req) {
      let response;
      try {
        response = await anthropic.beta.messages.create(
          {
            model,
            max_tokens: 4000,
            betas: ["server-side-fallback-2026-07-01"],
            fallbacks: "default",
            // Voice turns are latency-sensitive: low effort keeps replies fast.
            output_config: { effort: "low", format: { type: "json_schema", schema: TURN_OUTPUT_SCHEMA } },
            system: PROFESSOR_SYSTEM,
            messages: [{ role: "user", content: buildUserMessage(req) }],
          },
          { timeout: 20_000, maxRetries: 1 },
        );
      } catch (error) {
        if (error instanceof Anthropic.RateLimitError) throw new ContractError("rate_limited", "The tutor is busy. Try again in a moment.", 429);
        if (error instanceof Anthropic.AuthenticationError) throw new ContractError("unavailable", "Tutor provider credentials are not configured.", 503);
        if (error instanceof Anthropic.APIConnectionError) throw new ContractError("unavailable", "Tutor provider unreachable.", 503);
        if (error instanceof Anthropic.APIError) throw new ContractError("provider_error", `Provider error ${error.status ?? ""}`.trim(), 502);
        throw error;
      }
      if (response.stop_reason === "refusal") throw new ContractError("provider_error", "The tutor could not answer that.", 502);
      const text = response.content.filter((b) => b.type === "text").map((b) => b.text).join("");
      let out;
      try {
        out = JSON.parse(text);
      } catch {
        throw new ContractError("provider_error", "Malformed tutor response.", 502);
      }
      return { ...out, usedExpressions: (out.usedExpressions ?? []).filter((e) => req.targetExpressions.includes(e)) };
    },
  };
}
