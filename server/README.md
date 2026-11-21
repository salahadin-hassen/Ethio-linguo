# Tutor relay

This is a stateless Node service. It keeps AI provider credentials off the phone and turns a structured tutoring request into one provider call.

- Contract: `docs/INTEGRATION_CONTRACTS.md` §7
- Design: `docs/AI_PROVIDER_INTEGRATION.md`

```bash
cp .env.example .env    # set ANTHROPIC_API_KEY (never commit .env)
npm install
npm test                # contract tests, no network
npm start               # :8787
curl localhost:8787/v1/health
```

- **Privacy:** the relay receives text only. It stores nothing, and its logs contain timing only, never utterances or replies.
- **Provider:** `src/providers/anthropic.mjs` uses the official `@anthropic-ai/sdk` with structured JSON output. The model comes from `TUTOR_MODEL` (default `claude-opus-5-5`).
- **Adding a provider:** add a module that exports `{name, model, turn(req)}`.
