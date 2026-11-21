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

## Problem and who it serves

Tens of millions of Ethiopians speak Amharic or Afaan Oromo as their first language. Most English-learning apps explain English in English, assume constant mobile data, and drill isolated words. Learners meet real English in video and conversation, but nothing helps them understand it *in their own language* or practise saying it.

Ethio-Linguo serves Amharic and Afaan Oromo speakers learning English, from beginner to conversational, on affordable Android phones with unreliable data.

## Features (as of 2026-11-21)

- **Onboarding:** choose Amharic or Afaan Oromo and an English level; both are saved on the device.
- **Gamified path:** short lessons (multiple choice, match pairs, type the answer, build a sentence) with XP, streaks, hearts, levels, daily quests, badges and a Word Garden.
- **Watch & learn:** a short original English scene with English, Amharic and Afaan Oromo subtitles synced to playback, and tappable expressions explained in context.
- **My Words and review:** save expressions, then review them with spaced flashcards.
- **The Professor (live AI tutor):** a spoken English roleplay of the scene, with teaching in Amharic or Afaan Oromo:
  - you speak English (recognised on the phone) or ask a question in your own language (transcribed by Addis AI);
  - the Professor answers in English as soon as the first line arrives, then coaches you aloud in your language (Addis voices Yohanes and Leta);
  - "repeat after me" tasks are checked word by word on the phone, instantly;
  - you can cut in while he is talking, and a dropped connection is retried once automatically.
- **Animated characters:** Spark and the Professor are Rive rigs that react to what happens (listening, thinking, speaking, correct, wrong).
- **Translations:** all Amharic and Afaan Oromo content is a labelled draft until a native speaker reviews it (`docs/CONTENT_GOVERNANCE.md`).

## Offline and online

| Works with no internet | Needs internet |
|---|---|
| Onboarding, lessons, path, XP, streaks, quests, badges, Word Garden | The Professor (AI tutor), including his Amharic/Oromo voice and transcription of spoken questions |
| Watch & learn scene, subtitles, expression cards | |
| My Words and review | |

The offline journey is covered by an automated test with networking blocked. Without the relay, the Speak tab says plainly that the Professor is offline and offers offline practice instead.

## Architecture

- **Flutter app** (`lib/`): features depend only on interfaces collected in `AppServices` (content, vocabulary, tutor, speech, voice, audio). All progress goes through one service, `AppController.completeActivity`. Network code lives in a single file, `lib/services/tutor/relay_tutor_engine.dart`, enforced by a test.
- **Tutor relay** (`server/`, Node 24, no dependencies): holds the Addis AI key, builds the teaching prompt, streams the tutor's answer (`POST /v1/tutor/turn/stream`), and synthesises and transcribes Amharic/Afaan Oromo speech. The app never contains an API key.
- Details: `docs/ARCHITECTURE.md`, `docs/AI_PROVIDER_INTEGRATION.md` and `docs/ADR/`.

## Run

### 1. Start the AI relay (on a laptop on the same Wi-Fi as the phone)

```bash
cd server
cp .env.example .env        # then put your own Addis AI key in .env (ADDIS_API_KEY=...). Never commit it.
npm test
npm start                   # listens on port 8787
```

Check it: open `http://<laptop-ip>:8787/v1/health` (it should say `"ok":true`). Find the laptop IP with `ip -4 addr` (Linux) or `ipconfig` (Windows). If a firewall blocks the phone, allow port 8787 from your local network only.

Optional: install `ffmpeg` on the relay machine so the Professor's mouth follows the measured loudness of his voice.

### 2. Build and install the Android app

```bash
flutter pub get
flutter build apk --release --target-platform android-arm64 \
  --dart-define=TUTOR_BASE_URL=http://<laptop-ip>:8787
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

If the laptop's IP changes later, open Speak; on "The Professor is offline", type the new address in **Tutor server** and tap **Connect**. No rebuild needed.

For development: `flutter run --dart-define=TUTOR_BASE_URL=http://<laptop-ip>:8787`. On a machine with little RAM, run tests with `flutter test -j 1` and never alongside a build.

## Limitations

- The relay runs on a laptop over plain HTTP; the Android app allows cleartext traffic for that reason. A production deployment needs the relay on a host with HTTPS.
- AI response time depends on the network: measured 1.5–2.8 s to the first spoken line on a good connection and 5–10 s on a slow one.
- The Professor's mouth follows the loudness of his voice; it is not phoneme lip-sync. His English voice is the phone's text-to-speech and varies by device.
- Content is a demo: one video scene and one course unit.
- Tutor conversations are not saved between app restarts.
- The Rive character files are on Rive's free plan and carry its watermark.
- Translations are AI-assisted drafts pending native-speaker review.

## Quality checks

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test -j 1                             # unit, widget, offline, Ethiopic coverage, contract tests
(cd server && npm test)                       # relay tests
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
