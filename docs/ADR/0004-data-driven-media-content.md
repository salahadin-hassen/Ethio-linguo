# ADR 0004: Data-driven media content

- **Status:** Accepted (2026-11-21)
- **Context:** Future content includes films, songs, books, articles, audio stories and podcasts. Subtitles must not be hard-coded into widgets.
- **Decision:**
  - Each item is a content package: `manifest.json` (`LearningContent` + `MediaItem` + rights), `transcript.en.json` (timed source segments + expressions) and `translations/<code>.json` (one file per language).
  - Sync and highlighting logic (`Transcript.segmentAt`, `spansFor`) is pure Dart.
  - Players implement `MediaPlayback`.
- **Consequences:**
  - Adding a language is adding a file.
  - Adding a medium is a new `MediaPlayback` plus a reader UI; the transcript logic is reused.
  - Packages are versioned (`schemaVersion`, `contentVersion`), and transcripts are validated on load (no overlaps, expressions must be present in their segment).
