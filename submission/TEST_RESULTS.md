# Test results (2026-11-21, commit dbe0880, branch feat/architecture-v2)

| Suite | Command | Result |
|---|---|---|
| Static analysis | `flutter analyze` | No issues found |
| Flutter tests | `flutter test -j 1` | 144 passed, 5 skipped (live AI and screenshot suites, run on demand) |
| Relay tests | `cd server && npm test` | 17 passed, 0 failed |
| Live AI (on demand) | `flutter test test/live --run-skipped` (relay running) | Passed in Amharic and Afaan Oromo earlier today: first line 1.5–2.8 s, coaching audio ready ~3 s after the turn |
| Android release | `flutter build apk --release --target-platform android-arm64` | Built (45.1 MB); installed and launched on TECNO KJ7, Android 14 |

What the Flutter suite covers: lesson engine and scoring, progress/XP/streak service, vocabulary and review, offline journey with networking blocked, Ethiopic glyph coverage, tutor session (streaming reply, coaching audio, instant repeat feedback, automatic retry, barge-in paths), relay client contract and errors, relay address setting, character rig contract.
