# Data Model

The Dart classes are the source of truth. All of them are plain Dart in `lib/data/models/`, and the persisted JSON is versioned.

| Directive model | Implementation | File |
|---|---|---|
| LearnerProfile | `LearnerProfile`: `id` (local UUID), `nativeLanguage`, `targetLanguages`, `level` (`LearnerLevel`), `createdAt`. Persisted inside `LearnerProgress` ([ADR 0002](ADR/0002-local-first-persistence.md)) | `progress.dart` |
| Language | `LanguageInfo`: `code` (BCP-47 `en`/`am`/`om`), `displayName`, `nativeName`, `script`, `textDirection`, `capabilities`, `speechLocale`. Registry: `Languages`. `NativeLanguage.info` links the enum | `language.dart` |
| LearningContent | `LearningContent`: `id`, `type` (`ContentType`), `title`, `description`, `sourceLanguage`, `translations` (code → `TranslationInfo`), `difficulty`, `durationMs`, `rights` (`ContentRights`), `offlineAvailable`, `contentVersion`, `media`, `transcriptAsset`, `sceneSummary`, `speakers` | `content.dart` |
| MediaItem | `MediaItem`: `id`, `contentId`, `mediaType`, `localAsset`, `remoteUrl`, `posterAsset`, `durationMs`. Attribution and licensing live in `LearningContent.rights` | `content.dart` |
| TranscriptSegment | `TranscriptSegment`: `id`, `mediaId`, `startMs`, `endMs` (exclusive), `originalText`, `speakerId`, `translations` (code → text), `expressionIds`. Grouped and validated by `Transcript` | `transcript.dart` |
| (expression) | `Expression`: `id`, `text`, `segmentId`, `meaning`, `contextualMeaning`, `example`, `exampleTranslation` (all keyed by language code) | `content.dart` |
| VocabularyEntry | `VocabularyEntry`: `id` (UUID), `learnerId`, `expressionId`, `originalExpression`, `translations`, `contextualMeaning`, `example`, `contextLine`, `contextTranslations`, `source`, `sourceContentId`/`Title`/`SegmentId`, `masteryStatus`, `createdAt`, `updatedAt`, `nextReviewAt`, `reviewCount`, `dirty` | `vocabulary.dart` |
| LearningActivity | `LearningActivity`: `id` (e.g. `media:bus_stop_hello`), `type`, `contentId`, `difficulty`, `native`/`target` (language configuration), `activityData` | `activity.dart` |
| LearningProgress | `LearnerProgress`: `completedNodeIds` + `completedActivityIds`, `totalXp`, `streak`, `lastActiveDay`, `daily`, `words` (Word Garden). Achievements are *derived* (`Achievement.evaluate`), not stored | `progress.dart`, `gamification.dart` |
| ConversationSession | `ConversationSession`: `id`, `tutorCharacterId`, `native` (language configuration), `contentId` (lesson context), `createdAt`, `learnerTurns`, `usedExpressions`, `suggestions` (feedback). Full transcripts are not persisted (privacy) | `conversation.dart` |

Supporting types:
- `TutorContext`, `TutorTurn` and `TutorFeedback` in `conversation.dart`
- `ActivityReward` and `ActivityXp` (the only XP rule table) in `activity.dart`
- `ContentRights` and `TranslationInfo` in `content.dart`

## Storage

| Key / path | Content |
|---|---|
| `learner_progress_v1` (SharedPreferences) | `LearnerProgress` JSON, including the profile fields `learnerId`, `createdAt`, `level` and `activities` |
| `vocabulary_entries_v2` (SharedPreferences) | `VocabularyEntry[]`, newest first |
| `assets/content/catalog.json` | list of manifest paths |
| `assets/content/<id>/manifest.json` | `LearningContent` (schemaVersion 2) |
| `assets/content/<id>/transcript.en.json` | source segments + expressions |
| `assets/content/<id>/translations/<code>.json` | `{segments:{id:text}, expressions:{id:{meaning,context,example}}}` |

Example JSON is in [INTEGRATION_CONTRACTS.md](INTEGRATION_CONTRACTS.md) §3–4.

The v1 key `saved_expressions_v1` from the foundation branch was never shipped, so no migration is needed.
