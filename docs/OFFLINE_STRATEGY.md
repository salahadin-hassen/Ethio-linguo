# Offline Strategy

**Principle:** the core learning loop never needs a network. Connectivity only adds the live Professor.

## What works offline

| Capability | How |
|---|---|
| Onboarding, language choice | Local state |
| Learning path, lessons, validation, XP, streak, hearts, quests, achievements, Word Garden | Bundled `DemoCourse` + `AppController` + `SharedPrefsProgressStore` |
| Discover catalogue and media lessons | Clips, manifests and subtitles bundled under `assets/content/media/` |
| Expression explanations | Stored in the manifest (written and reviewed in advance, not generated live) |
| My Words | `SharedPrefsVocabularyRepository` |
| Amharic and Oromo rendering | Bundled Noto Sans Ethiopic and Nunito. No device fonts and no downloads |
| Speak, when no tutor is available | Honest "Professor is offline" state, plus typed review of saved words labelled "Offline practice" |

## What needs connectivity

- **Live Professor conversation:** the relay plus the LLM provider.
- **Speech recognition, on some devices:** Android's recogniser may need the network unless an offline English language pack is installed. Check this on the demo phone (`TEST_PLAN.md` §4). TTS is on-device.
- Nothing else.

## Local data persistence

- SharedPreferences JSON blobs, versioned keys (`INTEGRATION_CONTRACTS.md` §8).
- Writes happen immediately after each state change. There is no "save" button and nothing is lost on kill.
- Corrupt data resets that one store and never bricks the app.
- *Post-hackathon:* move to SQLite/Drift behind the same interfaces.

## Downloaded content

- **MVP:** "downloaded content" means **bundled in the APK**. Clip budget: ≤ 2 clips, ≤ 10 MB each.
- *Post-hackathon:* content packs (manifest + clip + subtitles zip) are downloaded to app storage and registered through a `DownloadedMediaRepository` that implements the same `MediaRepository`. The UI does not change.

## Synchronisation boundaries

- **MVP:** there is no sync. All state is device-local. The tutor relay is stateless, and transcripts are not stored server-side.
- **Future:** progress and My Words sync through an account service. Conflicts are resolved with last-write-wins per item, plus XP as an additive event log.

## Verification

Offline claims are only made after the flight-mode checklist in `TEST_PLAN.md` §2 passes on the demo device. The automated tests run with no network and in-memory stores.
