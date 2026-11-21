# Offline Strategy

**Principle:** local storage is the source of truth, and the core learning loop never needs a network. Connectivity only adds the live Professor.

## Works offline (verified by automated tests with networking blocked)

| Capability | Mechanism | Test |
|---|---|---|
| Startup, onboarding, language and level preferences | `SharedPrefsProgressStore` | `offline_test`, `startup_and_onboarding_test` |
| Learning path, lessons, XP, streak, badges, Word Garden | bundled `DemoCourse` + `AppController` | `offline_test` |
| Discover, media lesson playback, subtitles, translations, explanations | bundled content package (`assets/content/`) | `scene_to_speech_test` (`HttpOverrides` tripwire: 0 attempts) |
| Save, remove and review My Words; revision activity | `SharedPrefsVocabularyRepository` | `scene_to_speech_test`, `content_and_vocabulary_test` |
| Pronunciation help | replays the real line from the bundled clip. Device TTS is added where the OS provides it | manual |
| Ethiopic rendering | bundled Noto Sans Ethiopic; glyph coverage checked for `lib/` **and** `assets/content/` | `ethiopic_rendering_test` |

Automated tests run against a clock-driven player (`ClockPlayback`), not real video decoding. Real decoding of the bundled MP4 still has to be confirmed on the demo phone (TEST_PLAN §2).

## Needs connectivity

| Capability | Offline behaviour |
|---|---|
| Live Professor (relay + AI provider) | "The Professor is offline right now", with Try again and an "Offline practice (not AI)" section that links to the review. No fake replies. |
| Speech recognition on some devices | The OS may need network unless an offline English pack is installed. Typed input always works |

## Persistence

- Versioned JSON documents in SharedPreferences (`learner_progress_v1`, `vocabulary_entries_v2`).
- Writes happen immediately on every change. Corrupt data resets that one store only.
- Move to SQLite/Drift behind the same interfaces when volumes grow ([ADR 0002](ADR/0002-local-first-persistence.md)).

## Downloads

- MVP: "available offline" means **bundled in the APK**. `BundledDownloadRepository` reports `bundled`, and the Discover card shows "Works offline" only in that case.
- Future: content packages downloaded to app storage (`DownloadRepository` + `LearningContentRepository` implementations). Downloads are gated on `rights.offlineUseAllowed` and versioned by `contentVersion`.

## Synchronisation readiness (no sync engine, no sync indicators)

- IDs are locally generated UUID v4 (`newLocalId()`).
- `VocabularyEntry.updatedAt` is in UTC, and `dirty = true` on every local write.
- Content carries `schemaVersion` and `contentVersion`.
- Conflict policy (future): last-write-wins per vocabulary entry; XP as an append-only event log; deletions as tombstones.
- Local and remote repository implementations stay separate, so screens never change.
