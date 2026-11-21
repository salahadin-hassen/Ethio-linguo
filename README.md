# Ethio Linguo (working title)

> **Learn from what you love. Understand it in your language. Speak it with confidence.**

An Ethiopian-first, offline-first app for learning English **through Amharic or Afaan Oromo**. It is built around a Media-to-Conversation loop: **watch** a short English clip, **understand** expressions in your own language, **keep** them in My Words, and **speak** them with the Professor, an AI tutor.

The product name is not final. It lives in `lib/app/app_config.dart`.

## Hackathon: start here

| You are… | Read | Then |
|---|---|---|
| Everyone | [`docs/INTEGRATION_CONTRACTS.md`](docs/INTEGRATION_CONTRACTS.md), [`docs/TEAM_WORKFLOW.md`](docs/TEAM_WORKFLOW.md) | `git switch <your feat branch>` |
| Engineer 1: Flutter frontend | [`.github/workstreams/E1-mobile-ui.md`](.github/workstreams/E1-mobile-ui.md) | branch `feat/mobile-ui` |
| Engineer 2: Media learning | [`.github/workstreams/E2-media-learning.md`](.github/workstreams/E2-media-learning.md) | branch `feat/media-learning` |
| Engineer 3: AI tutor | [`.github/workstreams/E3-ai-tutor.md`](.github/workstreams/E3-ai-tutor.md) | branch `feat/ai-tutor` |

**Docs:**

- [Product brief](docs/PRODUCT_BRIEF.md)
- [MVP scope](docs/MVP_SCOPE.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Data model](docs/DATA_MODEL.md)
- [Design system](docs/DESIGN_SYSTEM.md)
- [Offline strategy](docs/OFFLINE_STRATEGY.md)
- [Demo script](docs/DEMO_SCRIPT.md)
- [Test plan](docs/TEST_PLAN.md)
- [Roadmap](docs/FUTURE_ROADMAP.md)
- [AI provider integration](docs/AI_PROVIDER_INTEGRATION.md)
- [Content governance](docs/CONTENT_GOVERNANCE.md)
- [ADRs](docs/ADR/)
- [Contributing](CONTRIBUTING.md)

Pull requests go into `integration/hackathon-mvp`. `main` changes only through a PR from integration.

## What works today (2026-11-21)

**Scene-to-Speech MVP:** learn English from a real-life scene, understand it in your language, and practise it with an AI character.

- **Onboarding:** Amharic or Afaan Oromo, English as the target language, and English level. All three are persisted.
- **Dashboard (5 tabs: Home · Learn · Discover · Speak · My Words):**
  - greeting, XP, streak and daily progress
  - continue learning and a featured scene
  - entry points to every product area
- **Media lesson:** one original bundled clip, with English, Amharic and Afaan Oromo subtitles synced to playback.
  - Controls: replay line, previous and next line, and a tappable transcript.
  - Expressions are tappable and open a card with the meaning in context, an example, pronunciation help, Save, and "Practise with the Professor".
- **My Words:** save, remove (with undo), details and status. Saved words persist offline.
- **Revision:** a flashcard review that awards XP.
- **Gamification:** a single central progress service (`AppController.completeActivity`) handles XP, streak, badges and reward sheets.
- **Offline:** the whole journey above passes an automated test with networking blocked.
- **The Professor:** speech in → AI tutor → speech out, with a transcript and feedback.
  - Implemented and tested with test doubles. The relay lives in `server/`.
  - ✅ **A live AI conversation is verified with Addis AI** in both Amharic and Afaan Oromo, at about 2.7 s per turn (`test/live/`).
  - Without the relay, the app honestly shows "The Professor is offline". See `docs/AI_PROVIDER_INTEGRATION.md`.
- **Translations:** all Amharic and Afaan Oromo content is a labelled **draft** until a native speaker reviews it (`docs/CONTENT_GOVERNANCE.md`).

Architecture: `docs/ARCHITECTURE.md` and `docs/ADR/`.

## Run

```bash
flutter pub get
flutter run                                   # Android device/emulator (or -d linux / -d chrome)
(cd server && cp .env.example .env && npm install && npm start)          # tutor relay; set ADDIS_API_KEY in server/.env
flutter run --dart-define=TUTOR_BASE_URL=http://<relay-host>:8787
```

## Quality checks

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test                                  # unit, widget, offline, Ethiopic coverage, contract tests
flutter test test/screenshots --run-skipped --update-goldens   # regenerate screenshots
flutter build apk --release
```

## Structure

```
lib/
  app/            bootstrap, router, AppController (central progress service), AppScope, AppServices
  core/           theme, motion, navigation (AppRoutes, HomeTab), components, l10n (AppStrings), util
  data/
    models/       language, content, transcript, vocabulary, activity, conversation, progress, course
    repositories/ content/transcript/download, vocabulary, conversation (interfaces + local impls)
    local/        bundled path course, ProgressStore
  services/       playback (MediaPlayback), speech (STT/TTS), tutor (TutorEngine, relay client), analytics
  features/       onboarding, language_selection, home, learning_path, lessons, word_garden, achievements,
                  discover, media_lesson, my_words, revision, speak, progress, mascot
assets/content/   bundled content packages (manifest, transcript, translations/<code>.json, clip)
server/           tutor relay (Node, holds the provider key; never bundled)
tool/content/     reproducible generator for the original demo clip
docs/             product, architecture, contracts, governance, ADRs, test plan, screenshots
```

## Security

- No API keys in the app or the repo. Provider keys live only in `server/.env`, which is git-ignored.
- Only original or rights-cleared media.
