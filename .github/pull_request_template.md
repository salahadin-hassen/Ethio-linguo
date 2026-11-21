## What & why

<!-- One or two sentences. Link the workstream issue: Closes #… / Part of #… -->

## Workstream

- [ ] E1 mobile UI
- [ ] E2 media learning
- [ ] E3 AI tutor
- [ ] Integration / shared contract (label `integration`, needs Tech Lead review)

## Checks (paste the output)

```
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Contract and ownership

- [ ] I only changed files my workstream owns, or additive lines in shared files.
- [ ] No new models or route names outside `docs/INTEGRATION_CONTRACTS.md`, or that doc is updated in this PR.
- [ ] No secrets, `.env` files, keystores, unlicensed media or `build/` output.
- [ ] Nothing scripted is presented as live AI.

## Screenshots / recording (UI changes)

## Known gaps / follow-ups
