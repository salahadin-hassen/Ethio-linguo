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
- [Contributing](CONTRIBUTING.md)

Pull requests go into `integration/hackathon-mvp`. `main` changes only through a PR from integration.

## What works today

- **Milestone 1:**
  - Screens: welcome, language selection (Amharic / Afaan Oromo), home dashboard, learning path, 4 exercise types, lesson completion.
  - Rewards: XP, levels, streak, hearts, quests, achievements, Word Garden.
  - Fully offline: bundled content, on-device progress, bundled Ethiopic fonts.
- **Hackathon foundation:**
  - Shared models for media, subtitles, expressions and saved expressions.
  - `MediaRepository`, `VocabularyRepository` and a provider-agnostic `TutorService`, injected via `AppServices`.
  - Frozen route names, a `recordActivity` XP hook, and placeholder screens for Discover, media lesson, Speak and My Words.
- **Not yet built** (workstreams in progress): the video player and subtitles, the live voice tutor, the four-tab shell and the My Words list. The tutor currently reports itself **unavailable**, honestly.

## Run

```bash
flutter pub get
flutter run                                   # Android device/emulator (or -d linux / -d chrome)
flutter run --dart-define=TUTOR_BASE_URL=http://<relay-host>:8787   # once the tutor relay exists
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
  app/          bootstrap, router, AppController (progress rules), AppScope, AppServices
  core/         theme tokens, motion, navigation (AppRoutes, HomeTab), components
  data/
    models/     language, course, exercise, progress, gamification, media, saved_expression
    local/      bundled demo course, ProgressStore
    repositories/  MediaRepository, VocabularyRepository
  services/tutor/  TutorService contract (+ live implementation, E3)
  features/     onboarding, language_selection, home, learning_path, lessons, word_garden,
                achievements, mascot, my_words (E1) · discover, media_lesson (E2) · speak (E3)
assets/
  fonts/        Nunito + Noto Sans Ethiopic (OFL, see FONTS_LICENSE.md)
  content/media/  bundled clips + manifests (E2)
server/         tutor relay (E3, optional, never bundled; holds the API key)
docs/           product, architecture, contracts, design, test plan, screenshots
```

## Security

- No API keys in the app or the repo. Provider keys live only in `server/.env`, which is git-ignored.
- Only original or rights-cleared media.
