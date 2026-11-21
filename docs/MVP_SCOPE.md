# MVP Scope: Scene-to-Speech

> Learn English through real-life media, understand it in your language, and practise it with an AI character.

The status below is what is built and tested **as of 2026-11-21**. Items marked ⚠️ have code and tests but lack a runtime verification.

## P0: essential (all ✅)

| Feature | Status | Evidence |
|---|---|---|
| Welcome, native language (Amharic / Afaan Oromo), English as target, English level | ✅ persisted (`LearnerProfile`) | `startup_and_onboarding_test`, `content_and_vocabulary_test` |
| Five-tab dashboard: Home · Learn · Discover · Speak · My Words | ✅ | `dashboard_and_path_test`, screenshot 30 |
| Home: greeting, daily progress, XP, streak, continue learning, featured scene, Discover, Professor, My Words and Badges entry points | ✅ no fake stats; every tile navigates | `dashboard_and_path_test` |
| One bundled, original video lesson (15.7 s, 170 KB) | ✅ | `content_and_vocabulary_test` |
| Playback controls: play/pause, previous/next line, replay line, scrubber | ✅ | `scene_to_speech_test` |
| Timestamped English + Amharic + Afaan Oromo subtitles, chosen by the learner's language, synced to playback | ✅ | `scene_to_speech_test` (both languages, gaps, seek) |
| Tap-to-select expressions (7 in the clip), transcript list that taps to replay | ✅ | `scene_to_speech_test` |
| Expression card: English, translation, meaning in this scene, example + translation, pronunciation (replays the real line from the clip offline; device TTS where available), Save, Practise with Professor | ✅ | `scene_to_speech_test`, screenshot 34 |
| My Words: save, remove (with undo), open details, status, saved date, source, persists across restart, offline | ✅ | `content_and_vocabulary_test`, `scene_to_speech_test` |
| Revision: flashcards on fixed intervals (1 / 3 / 7 days), XP | ✅ | `scene_to_speech_test` |
| Gamification: one central `completeActivity`, lesson completion, streak, new badges (Scene Starter, Word Keeper, First Conversation), reward sheet | ✅ | `content_and_vocabulary_test` |
| Offline: the whole P0 journey with networking blocked | ✅ automated (`HttpOverrides` tripwire) | `scene_to_speech_test`, `offline_test` |

## P1: differentiator

| Feature | Status |
|---|---|
| Professor screen: lesson context, every conversation state, transcript, feedback cards, "AI translation" labels | ✅ implemented and tested with test doubles |
| Push-to-talk speech recognition and spoken replies | ⚠️ implemented (OS speech services). **Not verified on a physical phone yet** |
| Live AI replies via the relay | ⚠️ relay built and tested. **Live call not verified: no valid provider key on the build machine** |
| Honest fallback when the tutor is unavailable | ✅ tested |
| XP celebration | ✅ |

## P2: not started (by design)

Rich character animation, more activity types, advanced achievements, music and book prototypes.

## Explicit exclusions

- Accounts, login and cloud sync. Records are sync-ready, but nothing syncs.
- Content downloads. Everything is bundled; `DownloadRepository` is an interface only.
- Phoneme-level pronunciation scoring.
- More than one AI character.
- Treating unreviewed translations as authoritative. Every translation is a labelled **draft** until a native speaker reviews it.

## Before the demo

- [ ] Put a valid provider key in `server/.env`, run `npm start`, and verify one live turn (TEST_PLAN §4).
- [ ] Install the release APK on the demo phone. Check video, STT and TTS there.
- [ ] Native-speaker review of `translations/am.json` and `om.json` (CONTENT_GOVERNANCE checklist).
