# Integration Contracts

**Read this before writing code.** These contracts let three workstreams build in parallel without editing each other's files.

- The code in the listed files *is* the contract, and `test/unit/contracts_test.dart` and `test/widget/routes_contract_test.dart` guard it.
- **To change a contract:** open a small PR labelled `integration` into `integration/hackathon-mvp`, and post in the team channel. Adding an optional field is fine. Renaming or removing anything needs Senior Tech Lead approval.

## 1. Theme and component conventions

- Use only the tokens: `AppColors`, `AppType`, `Space`, `Radii`, `Motion` (`lib/core/theme`, `lib/core/motion`). Never hard-code hex colours, font sizes or durations.
- Coloured text uses the `*Ink` variants. Brand colours are fills with indigo text on top (WCAG rule, `DESIGN_SYSTEM.md`).
- Reuse `AppButton`, `AppCard`, `Pressable`, `EmptyState`, `showAppSheet`, `SpeechBubble`, `StatPill`, `AppProgressBar`.
  - E2 and E3 need a new shared component? Build it inside your feature folder first. E1 promotes it to `core/components` later.
- Every text style already has the Ethiopic fallback. Never set `fontFamily` without `AppType.fallback`.
- Respect `Motion.reduced(context)`: loops stop, transitions become instant.
- Touch targets must be at least 48 px. Interactive widgets need `Semantics` labels. Test keys use `ValueKey('<feature>_<thing>')`.

## 2. Navigation ownership and route names

| Route | Arguments | Screen | Owner |
|---|---|---|---|
| `AppRoutes.welcome` `/welcome` | — | WelcomeScreen | E1 |
| `AppRoutes.language` `/language` | — | LanguageSelectionScreen | E1 |
| `AppRoutes.home` `/home` | `HomeTab?` or `int?` | HomeShell | E1 |
| `AppRoutes.lesson` `/lesson` | `LessonLaunch` | LessonScreen | E1 |
| `AppRoutes.complete` `/complete` | `LessonReward` | LessonCompleteScreen | E1 |
| `AppRoutes.discover` `/discover` | — | DiscoverScreen | E2 |
| `AppRoutes.mediaLesson` `/media-lesson` | `MediaLessonArgs(mediaId)` | MediaLessonScreen | E2 |
| `AppRoutes.speak` `/speak` | `TutorContext?` | SpeakScreen | E3 |
| `AppRoutes.myWords` `/my-words` | — | MyWordsScreen | E1 |

- The router is `lib/app/app.dart`. It is **shared**, and only new `case` entries are added to it.
- **Bottom tabs (E1):** `HomeTab.learn`, `discover`, `speak`, `myWords`, in that order, with keys `nav_Learn`, `nav_Discover`, `nav_Speak`, `nav_My Words`.
  - The tabs embed `DiscoverScreen()`, `SpeakScreen()` and `MyWordsScreen()` directly. Those screens must work both as a tab (no back button) and as a pushed route.
  - Achievements and the Word Garden stay reachable from Learn and My Words.
- **Cross-feature navigation:** use `Navigator.pushNamed(context, AppRoutes.x, arguments: …)` only. Never import another feature's screen.
- **Handoff from media to speech:** `pushNamed(AppRoutes.speak, arguments: TutorContext(native: …, mediaId: m.id, sceneSummary: m.sceneSummary, targetExpressions: [saved expression en strings]))`.

## 3. Media and subtitle schema (v1)

Each clip lives in its own folder:

```
assets/content/media/
  index.json                         {"v":1,"items":["assets/content/media/<id>/manifest.json"]}
  <id>/manifest.json                 MediaItem JSON (below)
  <id>/clip.mp4                      H.264/AAC, 720p max, ≤ 10 MB, ≤ 60 s
  <id>/poster.jpg                    optional, ≤ 150 KB
```

```json
{
  "v": 1,
  "id": "bus_stop_hello",
  "title": "Long time no see",
  "videoAsset": "assets/content/media/bus_stop_hello/clip.mp4",
  "posterAsset": "assets/content/media/bus_stop_hello/poster.jpg",
  "durationMs": 32000,
  "license": { "kind": "original", "attribution": "Recorded by the team, 2026" },
  "sceneSummary": "Two old friends meet unexpectedly at a bus stop and catch up.",
  "level": 1,
  "segments": [
    {
      "id": "s1", "startMs": 800, "endMs": 3200, "speaker": "Liya",
      "en": "Long time no see!",
      "translations": { "am": "<native speaker>", "om": "<native speaker>" },
      "expressionIds": ["long_time_no_see"]
    }
  ],
  "expressions": [
    {
      "id": "long_time_no_see",
      "en": "Long time no see",
      "meaning":     { "am": "<native speaker>", "om": "<native speaker>" },
      "explanation": { "am": "<native speaker>", "om": "<native speaker>" },
      "example": "Long time no see, how is your family?",
      "reviewed": false
    }
  ]
}
```

Rules:

- Segments are sorted and non-overlapping, and `endMs` is exclusive.
- `expression.en` appears verbatim in its segment's `en`, so the UI can highlight it.
- If a translation is missing for a language, show the English line only. Never show a blank or `null`.
- `<native speaker>` marks a slot for a teammate who speaks the language. Never fill it with unreviewed machine translation without leaving `"reviewed": false`.
- `license` is required. Only `original` media or explicitly rights-cleared media is allowed.

## 4. Vocabulary schema

`SavedExpression` JSON, persisted under `saved_expressions_v1`:

```json
{ "id": "long_time_no_see", "en": "Long time no see", "meaning": {"am": "…", "om": "…"},
  "source": "media", "savedAt": "2026-11-21T10:04:00.000", "contextLine": "Long time no see!",
  "mediaId": "bus_stop_hello", "segmentId": "s1", "reviewCount": 0 }
```

Create from media with `SavedExpression.fromMedia(media:, segment:, expression:, now: AppScope.read(context).now)`.

## 5. Repository interfaces and service access

```dart
final services = ServicesScope.of(context);   // AppServices
services.media        // MediaRepository: list(), byId(id)
services.vocabulary   // VocabularyRepository (ChangeNotifier): all, contains, save, remove, markReviewed
services.tutor        // TutorService: availability(), open(TutorContext)
AppScope.of(context)  // AppController: native, progress, recordActivity(...)
```

- Use `ListenableBuilder(listenable: services.vocabulary, …)` to rebuild when words change.
- Workstreams swap implementations **only in `main.dart`**. Tests use `AppServices.inMemory()`.

## 6. Progress and XP contract

```dart
await AppScope.read(context).recordActivity(activityId: 'media:<mediaId>', xp: 15);
await AppScope.read(context).recordActivity(activityId: 'tutor:<mediaId|free>', xp: 20);
```

- Only `AppController` writes `LearnerProgress`.
- Award XP once per completed activity. The tutor awards it only after at least 3 learner turns.

## 7. Voice conversation interface

### In the app (Dart, `services/tutor/tutor_service.dart`)

```
TutorService.availability() -> TutorAvailability{live, reason?}
TutorService.open(TutorContext) -> TutorSession
TutorSession.state : ValueListenable<TutorState>   idle|connecting|listening|thinking|speaking|ended|unavailable|error
TutorSession.turns : ValueListenable<List<TutorTurn>>
start() · startListening() · stopListening() · sendText(text) · end() · errorMessage
```

- E3 adds the live implementation (on-device STT → relay → on-device TTS) in new files under `services/tutor/`.
- `UnavailableTutorService` remains the fallback when `TUTOR_BASE_URL` is unset or `/v1/health` fails.

### Relay HTTP API (`server/`)

`GET /v1/health` returns `200 {"ok": true, "provider": "anthropic", "model": "<id>"}`.

`POST /v1/tutor/turn` (`Content-Type: application/json`, client timeout 15 s):

```json
{
  "sessionId": "uuid",
  "character": "professor",
  "context": { "nativeLanguage": "am", "mediaId": "bus_stop_hello",
               "sceneSummary": "…", "targetExpressions": ["Long time no see"], "learnerLevel": 1 },
  "history": [ { "speaker": "tutor", "text": "…" }, { "speaker": "learner", "text": "…" } ],
  "utterance": { "text": "long time no see how are you", "sttConfidence": 0.82 }
}
```

`utterance: null` asks for the Professor's opening line.

The response is `200`:

```json
{
  "reply": { "text": "It really has been a long time! …", "translation": "…" },
  "feedback": { "kind": "grammar", "note": "…", "suggestion": "Long time no see! How are you?", "noteNative": "…" },
  "usedExpressions": ["Long time no see"],
  "done": false
}
```

An error returns `4xx/5xx` with `{"error": {"code": "unavailable|rate_limited|bad_request|provider_error", "message": "…"}}`.

- The relay keeps the API key server-side, enforces JSON output, and caps the reply at about 2 sentences so it can be spoken.
- The Professor persona and prompt live **only in the relay**.
- `translation` and `noteNative` are AI-generated, so the UI labels them "AI translation".

## 8. Local persistence contract

| Key (SharedPreferences) | Owner | Content |
|---|---|---|
| `learner_progress_v1` | AppController | `LearnerProgress` JSON |
| `saved_expressions_v1` | VocabularyRepository | `SavedExpression` list |

- New keys follow the pattern `<feature>_<thing>_v<n>` and are added to this table by PR.
- No feature reads another feature's key directly.

## 9. Error-state conventions

- **Never crash on bad data.** Repositories return empty or `null` and log in debug.
- Show a missing clip, an empty list or a failed load with `EmptyState`: a mascot, one plain sentence and at most one action (e.g. "Try again").
- Network failures in Speak:
  - Show `TutorState.error` with `errorMessage` and a **Retry** button. Keep the transcript.
  - After 2 consecutive failures, switch to `unavailable`.
- Microphone permission denied: explain why the mic is needed, offer `sendText` (typed input) and link to the system settings.
- Never present scripted or offline content as live AI. Label it "Offline practice".
