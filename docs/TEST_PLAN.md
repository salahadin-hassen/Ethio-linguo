# Test Plan

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test                                              # unit + widget + architecture + offline
flutter test test/screenshots --run-skipped --update-goldens   # regenerate screenshots
(cd server && npm test)                                   # relay contract tests
```

## Automated coverage of the core journey (directive Part 5)

| # | Check | Test |
|---|---|---|
| 1-2 | Select Amharic / Afaan Oromo | `startup_and_onboarding_test`, `scene_to_speech_test` |
| 3 | Translations change with the language (no Amharic leaks into Oromo) | `scene_to_speech_test` › Afaan Oromo |
| 4 | Bundled media plays (clock-driven player in tests) | `scene_to_speech_test` |
| 5 | Subtitles follow playback position, gaps and seeks | `scene_to_speech_test`, `content_and_vocabulary_test` › transcript sync |
| 6-7 | Select an expression, see the correct contextual translation | `scene_to_speech_test` |
| 8 | Save the expression | `scene_to_speech_test` |
| 9-10 | Restart, and saved words persist | `scene_to_speech_test` (fresh repository on the same storage), `content_and_vocabulary_test` |
| 11 | Complete a revision activity | `scene_to_speech_test` |
| 12-13 | XP awarded through the central service and persisted | `scene_to_speech_test`, `content_and_vocabulary_test` › central progress |
| 14 | Learning activity works without internet | `scene_to_speech_test` + `offline_test` (`HttpOverrides` tripwire records 0 attempts) |
| 15 | AI unavailable is handled gracefully and honestly | `scene_to_speech_test`, `tutor_test` |

## Architecture tests (`test/unit/architecture_test.dart`)

- Each repository and provider implementation satisfies its interface.
- Features never import `http`, `speech_to_text`, `flutter_tts` or `video_player`, nor the concrete tutor provider.
- Domain models are never declared inside `lib/features`.
- XP, streak and completed activities are written only by `AppController`.
- No hard-coded secrets in `lib`, `assets/content`, `server/src` or `android/app/src`, and `server/.env` is not tracked.
- Amharic and Oromo UI strings are centralised (legacy files listed explicitly).
- `offline_test`: network APIs appear only in `relay_tutor_engine.dart`, and only approved dependencies are used.

## Tutor (`test/unit/tutor_test.dart`, `server/test/relay.test.mjs`)

- The client wire format carries structured lesson context, and replies, feedback and used expressions are parsed.
- Relay errors map to typed exceptions. The health check fails cleanly when the relay is offline.
- Session: speech in, reply, speech out; feedback attached to the learner's turn; XP only after 3 or more learner turns; summary saved.
- Unavailable provider: no turns, no speech, no XP.
- Failure: the `error` state keeps the transcript, Retry works, and the session becomes unavailable after the second failure.
- Relay: health, turn envelope, 503 without a provider, request validation and clamping.

## Manual checks on the demo Android phone (not yet run)

### 2. Offline (flight mode)

- [ ] Cold start → Discover → the clip plays with picture and sound → both subtitle lines appear and stay in sync (within ±250 ms by eye at start, middle and end).
- [ ] Save 2 expressions → force-stop → relaunch → My Words shows both → review completes with XP.
- [ ] Speak → offline state shown, with no spinner left hanging.

### 4. Voice

- [ ] Relay `GET /v1/health` is reachable from the phone's network.
- [ ] **One genuine live turn**: hold, speak "Long time no see", release → transcript → spoken reply that references the bus-stop scene → feedback card.
- [ ] The microphone permission prompt appears. Denying it falls back to typed input.
- [ ] Latency from release to reply is under 4 s (measure 5 turns).
- [ ] Kill the relay mid-conversation → Retry → then the unavailable view.

### 6. Regression

- [ ] Milestone-1 lesson path, completion, garden and badges still work.
- [ ] No layout overflow at 360×640 and at 1.3× text scale on all five tabs and the lesson screen.

## Results log

Fill in from real runs only. See the final engineering report for the 2026-11-21 results.
