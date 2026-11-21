# Integration Contracts (v2)

**Read this before writing code.**

- The code is the contract. `test/unit/architecture_test.dart`, `test/unit/content_and_vocabulary_test.dart`, `test/unit/tutor_test.dart` and `test/widget/routes_contract_test.dart` guard it.
- To change a contract, open a PR labelled `integration` into `integration/hackathon-mvp`.
  - Adding an optional field is fine.
  - Renaming or removing anything needs the Senior Tech Lead's approval.

## 1. Theme, components, strings

- Use the tokens only: `AppColors`, `AppType`, `Space`, `Radii`, `Motion`.
- Coloured text uses the `*Ink` variants. Brand colours are used only as fills, with indigo text on them.
- Reuse `AppButton`, `AppCard`, `EmptyState`, `showAppSheet`, `SpeechBubble`, `AppProgressBar`, `LabelWithSupport` and `showActivityReward`.
- Support lines in the learner's language come from `AppStrings` / `S` (`core/l10n`). Never write Amharic or Oromo literals in widgets.
- Respect `Motion.reduced(context)`.
- Touch targets must be at least 48 px. Interactive widgets need Semantics labels.
- Test keys follow the pattern `ValueKey('<feature>_<thing>')`.

## 2. Routes and tabs

| Route | Arguments | Screen |
|---|---|---|
| `/welcome`, `/language` | — | onboarding |
| `/home` | `HomeTab?` or `int?` | `HomeShell` |
| `/lesson`, `/complete` | `LessonLaunch`, `LessonReward` | path lessons |
| `/discover` | — | `DiscoverScreen` |
| `/media-lesson` | `MediaLessonArgs(contentId)` | `MediaLessonScreen` |
| `/speak` | `TutorContext?` | `SpeakScreen` |
| `/my-words` | — | `MyWordsScreen` |
| `/revision` | — | `RevisionScreen` |
| `/garden`, `/achievements` | — | Word Garden, Badges |

- Tabs (`HomeTab`): `home`, `learn`, `discover`, `speak`, `myWords`. Their keys are `nav_Home`, `nav_Learn`, `nav_Discover`, `nav_Speak` and `nav_My Words`.
- Features navigate only with `Navigator.pushNamed(AppRoutes.x, arguments: …)`. They never import another feature's screen.

## 3. Content package schema (v2)

```
assets/content/catalog.json                    {"schemaVersion":2,"items":["assets/content/<id>/manifest.json"]}
assets/content/<id>/manifest.json              LearningContent
assets/content/<id>/transcript.en.json         source segments + expressions
assets/content/<id>/translations/<code>.json   one file per learner language
assets/content/<id>/clip.mp4, poster.jpg
```

`manifest.json` (abridged from `bus_stop_hello`):

```json
{ "schemaVersion": 2, "id": "bus_stop_hello", "type": "video", "title": "Long time no see",
  "sourceLanguage": "en", "difficulty": 1, "durationMs": 15733, "contentVersion": 1, "offlineAvailable": true,
  "sceneSummary": "Two old friends, Liya and Dawit, meet by chance at a city bus stop…",
  "speakers": { "liya": "Liya", "dawit": "Dawit" },
  "media": { "id": "bus_stop_hello_video", "type": "video", "durationMs": 15733,
             "localAsset": "assets/content/bus_stop_hello/clip.mp4", "posterAsset": "…/poster.jpg" },
  "transcript": "assets/content/bus_stop_hello/transcript.en.json",
  "translations": { "am": { "status": "draft", "translator": "…" }, "om": { "status": "draft" } },
  "rights": { "creator": "…", "rightsHolder": "…", "licenseType": "original", "attribution": "…",
              "offlineUseAllowed": true, "derivativeTranslationsAllowed": true, "components": ["…"] } }
```

`transcript.en.json`:

```json
{ "mediaId": "bus_stop_hello_video", "language": "en",
  "segments": [ { "id": "s1", "startMs": 600, "endMs": 2897, "speakerId": "liya",
                  "text": "Hey, Dawit! Long time no see!", "expressionIds": ["long_time_no_see"] } ],
  "expressions": [ { "id": "long_time_no_see", "segmentId": "s1", "text": "Long time no see",
                     "example": "Long time no see! How is your family?" } ] }
```

`translations/am.json`:

```json
{ "language": "am", "status": "draft",
  "segments": { "s1": "ሄይ ዳዊት! ከተያየን ቆየን!" },
  "expressions": { "long_time_no_see": { "meaning": "ከተያየን ቆየን", "context": "…", "example": "…" } } }
```

Validation runs on load:
- Segments must be sorted and must not overlap. `endMs` is exclusive.
- `expression.text` must appear in its segment.
- Bundled content must have `offlineUseAllowed: true`.
- A missing translation shows English only, never a blank.

## 4. Vocabulary schema (`vocabulary_entries_v2`)

See `VocabularyEntry.toJson()`. Create entries only with `VocabularyEntry.fromExpression(...)` and `newLocalId()`. The dedupe key is `expressionId`.

## 5. Services (`ServicesScope.of(context)` → `AppServices`)

```dart
content        LearningContentRepository   list(), byId()
transcripts    TranscriptRepository        load(content, languages: [...])
downloads      DownloadRepository          stateOf(content)
vocabulary     VocabularyRepository        all, due(now), byExpressionId, save, remove   (ChangeNotifier)
conversations  ConversationRepository      recent, save
tutor          TutorEngine                 availability(), respond(TutorRequest)
speechIn       SpeechRecognizer            initialize, listen, stop, cancel
speechOut      SpeechSynthesizer           initialize, speak, stop
explanations   ExplanationProvider         explain(expression, lang)
playbackFactory MediaPlaybackFactory       (MediaItem) -> MediaPlayback (owner disposes)
analytics      Analytics                   log(AnalyticsEvent, props)  — ids/counts only
```

- Implementations are swapped only in `main.dart`. Tests use `AppServices.inMemory(...)`.
- Repositories may return `SynchronousFuture`, so don't combine them with `Future.wait`.

## 6. Progress contract

```dart
final reward = await AppScope.read(context).completeActivity(
  LearningActivity(id: 'media:<id>' | 'revision:<day>' | 'tutor:<id|free>', type: …, native: …),
  units: <cards reviewed, revision only>,
);
showActivityReward(context, reward, title: …);
```

- XP values live only in `ActivityXp`: media 15, revision 2 per card (capped at 20), tutor 20 (needs at least 3 learner turns). A repeat completion earns one third.
- Nothing else writes XP, the streak or the completed-activity list. An architecture test enforces this.

## 7. Tutor relay HTTP API v1 (`server/`)

`GET /v1/health` returns `200 {"ok": bool, "provider": "anthropic"|null, "model": string|null, "contract": 1}`.

`POST /v1/tutor/turn`. The request body is at most 32 KB; the server clamps history to 12 turns and target expressions to 8:

```json
{ "sessionId": "uuid", "character": "professor",
  "learner": { "nativeLanguage": "am", "targetLanguage": "en", "level": 1 },
  "lesson": { "contentId": "bus_stop_hello", "title": "Long time no see", "sceneSummary": "…",
              "transcript": ["Liya: Hey, Dawit! Long time no see!", "…"] },
  "focusExpression": "Long time no see",
  "targetExpressions": ["Long time no see", "catch up"],
  "history": [ { "speaker": "tutor", "text": "…" }, { "speaker": "learner", "text": "…" } ],
  "utterance": { "text": "i been busy with my new job", "sttConfidence": 0.81 } }
```

`utterance: null` asks the Professor to open the conversation. A successful call returns `200`:

```json
{ "reply": { "text": "Oh nice, a new job! What do you do now?", "translation": "<learner language>" },
  "feedback": { "kind": "grammar", "note": "Say \"I have been\".", "noteNative": "…", "suggestion": "I have been busy with my new job." },
  "suggestedExpression": null, "usedExpressions": [], "done": false, "speech": null }
```

An error returns `{"error": {"code": "unavailable|rate_limited|bad_request|provider_error", "message": "…"}}` with status 503, 429, 400/413 or 502.

## 8. Local persistence keys

| Key | Owner |
|---|---|
| `learner_progress_v1` | `AppController` / `ProgressStore` |
| `vocabulary_entries_v2` | `VocabularyRepository` |

## 9. Error states

- Bad data never crashes the app: the affected store resets, or the content item is skipped and logged in debug builds.
- Lesson load failure shows `EmptyState` with a Back button.
- Tutor problems:
  - A tutor failure shows the `error` state with Retry, and the transcript is kept.
  - After 2 failures, or on `unavailable`, the app switches to the honest unavailable view.
  - If the microphone is denied, the app falls back to typed input.
- Nothing scripted is ever presented as live AI.

## 10. Future APIs (drafts only, not implemented)

All future APIs are versioned under `/v1/`. They use bearer auth once accounts exist, and IDs are client-generated UUIDs.

| API | Draft |
|---|---|
| Auth | `POST /v1/auth/otp/start {phone}` → `POST /v1/auth/otp/verify {phone, code}` → `{accessToken, refreshToken, learnerId}` |
| Content catalogue | `GET /v1/catalog?lang=am&since=<contentVersion>` → `[LearningContent summary]` |
| Translation delivery | `GET /v1/content/{id}/translations/{code}?v=<contentVersion>` → `translations/<code>.json` shape + `TranslationInfo` |
| Content packages | `GET /v1/content/{id}/package` → signed URL + `sha256` + `sizeBytes` + rights flags (`offlineUseAllowed` gates download) |
| Vocabulary sync | `POST /v1/sync/vocabulary {since, changes:[VocabularyEntry with dirty=true]}` → `{applied:[ids], serverChanges:[…], cursor}`. Last-write-wins on `updatedAt`, with tombstones for deletes |
| Progress | `POST /v1/sync/progress {events:[{activityId, xp, at}]}`. XP is an append-only event log; the server recomputes totals |
| AI conversation | `/v1/tutor/turn` (§7). A streaming `/v1/tutor/stream` (SSE) is possible later for lower latency |
