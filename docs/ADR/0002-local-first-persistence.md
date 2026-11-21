# ADR 0002: Local-first persistence

- **Status:** Accepted (2026-11-21)
- **Context:** Learners have patchy, metered data. The core experience must work in flight mode. The app already used SharedPreferences behind `ProgressStore`.
- **Decision:**
  - Keep SharedPreferences, with versioned JSON documents per concern: `learner_progress_v1` and `vocabulary_entries_v2`.
  - Each concern sits behind its repository interface.
  - The learner profile and progress share one document, so onboarding writes are atomic. They will be split when accounts exist.
  - Make records sync-ready (locally generated UUIDs, UTC `updatedAt`, a `dirty` flag), but build **no** sync engine.
- **Consequences:**
  - Zero new infrastructure.
  - A move to SQLite/Drift only changes implementation classes.
  - The documented conflict policy for future sync: last-write-wins per vocabulary entry by `updatedAt`, XP as an append-only event log, and tombstones for deletions (a future field).
  - The UI shows no sync indicator, because nothing syncs.
