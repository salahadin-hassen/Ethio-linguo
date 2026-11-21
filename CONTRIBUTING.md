# Contributing

The short version of [`docs/TEAM_WORKFLOW.md`](docs/TEAM_WORKFLOW.md).

1. **Branch:** work on your own `feat/*` branch, cut from `integration/hackathon-mvp`. Merge `integration` into it at least hourly.
2. **Stay in your lane:** edit only files your workstream owns. Shared files (`lib/app/**`, `lib/main.dart`, `lib/core/navigation/**`, `lib/data/models/**`, repository and tutor interfaces, `pubspec.yaml`) take additive changes only, in a PR labelled `integration`.
3. **Contracts first:** use the models, routes and services in [`docs/INTEGRATION_CONTRACTS.md`](docs/INTEGRATION_CONTRACTS.md). Don't invent parallel ones.
4. **Small commits** with imperative messages ("Add subtitle panel sync"). Push often.
5. **Before every PR:**
   ```bash
   dart format lib test
   flutter analyze
   flutter test
   ```
   Paste the result into the PR. Report failures; don't hide them.
6. **PR target:** `integration/hackathon-mvp`, never `main`. Fill in the template.
7. **Never:**
   - force-push shared branches
   - commit secrets, `.env` files or keystores
   - commit unlicensed media, fonts or lyrics
   - commit `build/` output
   - present scripted replies as live AI
8. **Blocked for 15 minutes?** Post it with the `blocker` label. See the escalation section of the workflow doc.
