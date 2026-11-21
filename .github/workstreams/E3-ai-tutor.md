# [E3] AI tutor: the Professor voice roleplay, relay and honest fallback

**Owner:** Engineer 3 · **Branch:** `feat/ai-tutor` · **Labels:** `voice-ai`, `demo-critical`
**Read first:** `docs/INTEGRATION_CONTRACTS.md` §2, §5, §6, §7, §9 and `docs/ARCHITECTURE.md`

## Goal

After the clip, the learner holds a button and speaks. The Professor, who knows the scene, answers aloud and gives feedback, with a visible transcript. This must be a **genuine** AI turn. Without a backend or network, the app says so honestly.

## Owned files

- `lib/features/speak/**`
- New files in `lib/services/tutor/`, e.g. `relay_tutor_service.dart` and `speech_io.dart`. `tutor_service.dart` is the shared contract and takes additive changes only.
- `server/**`: the relay, with its own README and `.env.example`.
- Shared, additive only:
  - your dependency lines in `pubspec.yaml`: `http`, `speech_to_text`, `flutter_tts` (or alternatives)
  - the tutor line in `lib/main.dart`
  - `RECORD_AUDIO` / `INTERNET` in `android/app/src/main/AndroidManifest.xml`
- Tests: `test/unit/relay_tutor_service_test.dart` (fake HTTP), `test/widget/speak_screen_test.dart`

## Tasks (in order)

1. **Relay (`server/`, by T+1:30).**
   - Build `GET /v1/health` and `POST /v1/tutor/turn` exactly as in contracts §7.
   - The provider sits behind an adapter. The default is the Anthropic Messages API, with the model set by the `TUTOR_MODEL` env var.
   - The key lives in `server/.env` (git-ignored). Commit only `.env.example`.
   - The Professor persona prompt: warm and concise, ≤ 2 short sentences per reply, roleplays the scene from `sceneSummary`, nudges the learner to use the `targetExpressions`, and returns strict JSON.
   - Test it with `curl` and paste the transcript into the PR.
2. **`RelayTutorService` (Dart):**
   - `availability()` calls `/v1/health` with a 3 s timeout.
   - `TutorSession`: push-to-talk via on-device STT (`speech_to_text`), POST the turn, speak the reply with `flutter_tts`, and append `TutorTurn`s.
   - States follow the contract, `sendText` is the typed fallback, and failures go to `error`, then `unavailable` after 2.
   - In `main.dart`: if `TUTOR_BASE_URL` (`--dart-define`) is set, use `RelayTutorService`, else `UnavailableTutorService`.
3. **Speak screen:**
   - Professor avatar (existing `Mascot`, labelled Professor), a `TutorStateBanner` for every state, `TranscriptBubble`s with feedback cards, and a `TalkButton`.
   - Typed input when the mic is denied or unavailable.
   - An honest unavailable view, with an optional "Offline practice (not AI)" review of saved words.
4. **Wrap-up:**
   - After ≥ 3 learner turns, ending the conversation calls `recordActivity(activityId: 'tutor:<mediaId|free>', xp: 20)`.
   - Show the expressions used, plus a **Save** for any not yet in My Words (`source: tutor`).
5. **Demo hardening:** measure latency (target < 4 s) and check STT on the demo phone (`TEST_PLAN.md` §4).

## Dependencies

- `TutorContext` comes from E2's media lesson via `AppRoutes.speak`. It also works with `null` (free conversation from the tab).
- Credentials: **the Project Owner provides the provider API key directly to the relay host's `server/.env`. Never in chat logs, commits or the app.**

## Acceptance criteria

- [ ] At least one meaningful voice interaction works end to end on the demo phone: speech → AI → spoken reply.
- [ ] The Professor clearly reflects the scene and the target expressions.
- [ ] All `TutorState`s are visibly represented, and the transcript and feedback are shown.
- [ ] No credentials in the repo or the APK (`git grep` check in the PR).
- [ ] With no relay or network, the fallback is graceful and honest. Nothing scripted is ever labelled as live AI.
