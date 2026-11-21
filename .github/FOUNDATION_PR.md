## What and why

This PR sets up the shared engineering foundation for the six-hour hackathon. Three workstreams can build in parallel against frozen contracts.

## Contents

- **Code contracts:**
  - models: `MediaItem`, `SubtitleSegment`, `Expression`, `SavedExpression`
  - repositories: `MediaRepository`, `VocabularyRepository`
  - tutor: `TutorService` / `TutorSession`, which honestly reports itself unavailable by default
  - wiring: `AppServices`, `ServicesScope`, `recordActivity`
  - navigation: new `AppRoutes`, `HomeTab`, and placeholder screens that each workstream owns
- **Tests:** `test/unit/contracts_test.dart` and `test/widget/routes_contract_test.dart`.
- **Docs:** the product brief, MVP scope, architecture (with a Mermaid diagram), data model, integration contracts, design system, offline strategy, team workflow, demo script, test plan and roadmap.
- **Collaboration:** a PR template, issue templates, `CONTRIBUTING.md`, the workstream issue bodies in `.github/workstreams/`, `scripts/github_setup.sh`, and secret patterns in `.gitignore`.

## Checks

Run locally on Flutter 3.47.6 before pushing:

```
dart format --output=none --set-exit-if-changed lib test  ->  Formatted 96 files (0 changed)
flutter analyze                                           ->  No issues found!
flutter test                                              ->  +88 ~2: All tests passed!   (~2 = screenshot goldens, skipped by design)
secret scan (git grep for key patterns)                   ->  no matches
```

## Not included (by design)

- No video player and no voice implementation. Those are workstreams E2 and E3.
- No Figma file was created or changed.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
