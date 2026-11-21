# Data Model

The Dart classes are the source of truth. This page describes them. All persisted JSON is versioned and corrupt data falls back to empty instead of crashing.

## User preferences: `LearnerProgress` (`data/models/progress.dart`)

| Field | Type | Notes |
|---|---|---|
| `onboarded` | bool | Gate between welcome and home |
| `native` | `NativeLanguage` (`am` / `om`) | Instruction language |
| `target` | `TargetLanguage` (`en`) | Only English is available |

Persisted under the SharedPreferences key `learner_progress_v1`.

## Lesson content: `Course` / `Unit` / `PathNode` / `Lesson` / `Term` / `Exercise`

These are bundled in `data/local/demo_course.dart`. A `Term` holds English plus `Localized(am, om)`. The data is read-only at runtime.

## Media item: `MediaItem` (`data/models/media.dart`)

| Field | Type | Notes |
|---|---|---|
| `id` | String | Stable, snake_case, equal to the asset folder name |
| `title` | String | English |
| `videoAsset` / `posterAsset` | String | Bundled asset paths |
| `durationMs` | int | |
| `license` | `MediaLicense{kind, attribution, url?}` | `kind` is `"original"` or an SPDX id. **Required.** |
| `sceneSummary` | String | Plain English. Passed to the tutor |
| `level` | int | 1 = beginner |
| `segments` | `List<SubtitleSegment>` | Sorted, non-overlapping |
| `expressions` | `List<Expression>` | Learnable phrases |

## Subtitle segment: `SubtitleSegment`

`id`, `startMs`, `endMs` (end exclusive), `en`, `translations` (`{"am": …, "om": …}`), `speaker?`, `expressionIds[]`. Each expression's `en` must appear verbatim in the segment's `en` so the UI can highlight it.

## Expression: `Expression`

`id`, `en`, `meaning` (a short gloss per language), `explanation` (why it is said this way in this scene, per language), `example?`, and `reviewed`. `reviewed` is `true` only after a native speaker has checked it.

## Vocabulary entry: `SavedExpression` (`data/models/saved_expression.dart`)

`id` (equals the `Expression.id`, which deduplicates), `en`, `meaning`, `source` (`media` / `tutor` / `lesson`), `savedAt` (ISO-8601), `contextLine?`, `mediaId?`, `segmentId?` and `reviewCount`. Persisted as a JSON list under `saved_expressions_v1`, newest first.

Lesson words keep living in `LearnerProgress.words` (the Word Garden, as `strength` 0–4). My Words shows both.

## Learning progress: `LearnerProgress`

`totalXp`, `streak`, `lastActiveDay` (`yyyy-mm-dd`), `hearts` / `heartsDay`, `completedNodeIds`, `perfectNodeIds`, `words`, `daily` (`DailyStats{day, xp, lessons, perfectLessons}`) and `longestCorrectRun`.

Media and tutor activities add XP through `AppController.recordActivity`. They do not write their own progress.

## Conversation record: `TutorTurn` (`services/tutor/tutor_service.dart`)

`speaker` (`learner` / `tutor`), `text` (English), `translation?`, `feedback?` (`TutorFeedback{kind, note, suggestion?, noteNative?}`) and `usedExpressions[]`.

Transcripts are **in memory only** for the MVP. They are not persisted or uploaded beyond the turn request, which is a privacy default. After a conversation, expressions the learner used can be saved with `source: tutor`.
