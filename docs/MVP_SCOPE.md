# MVP Scope: Six-Hour Hackathon

**Rule:** one complete, integrated journey beats many half-features. If it is not on the demo path (`DEMO_SCRIPT.md`), it waits.

## Already implemented (milestone 1, on `main`)

- Welcome, language selection (Amharic / Afaan Oromo), home dashboard, learning path, 4 exercise types, lesson completion.
- XP, levels, streak, hearts, daily quests, achievements, Word Garden.
- Offline: bundled course, local progress (SharedPreferences), bundled Nunito + Noto Sans Ethiopic.
- 88 automated tests (unit, widget, offline, Ethiopic glyph coverage, contracts).

## To build in the hackathon

| # | Feature | Owner | Acceptance criteria |
|---|---|---|---|
| 1 | Four-tab shell: Learn · Discover · Speak · My Words | E1 | Tabs per `HomeTab`; keys `nav_Learn` etc.; existing Learn flow is unchanged |
| 2 | Discover catalogue | E2 | Lists bundled clips from `MediaRepository`; works in flight mode |
| 3 | Media lesson player | E2 | One clip plays; English plus native subtitles stay within ±250 ms of speech; Amharic and Oromo both work |
| 4 | Expression explanation | E2 | Tapping a highlighted expression pauses the video and opens a sheet with its meaning and explanation in the learner's language |
| 5 | Save to My Words | E2 | `VocabularyRepository.save`; it persists across app restarts; saving twice creates no duplicate |
| 6 | My Words screen | E1 | Lists saved expressions with their context line and native meaning; updates live; shows an empty state |
| 7 | Professor voice tutor | E3 | At least one genuine voice turn (speech → AI → spoken reply) using the scene's `TutorContext`; transcript shown; every `TutorState` rendered |
| 8 | Honest fallback | E3 | With no backend, credentials or network, the UI says the live tutor is unavailable. Any offline practice is labelled "not AI" |
| 9 | Rewards | E2 / E3 | `recordActivity`: media lesson complete = **15 XP**; tutor conversation with ≥ 3 learner turns = **20 XP** |
| 10 | Offline proof | all | The demo path (except Speak) works in flight mode on the demo Android phone |

## Explicit exclusions

- Accounts, login, cloud sync, and any backend other than the tutor relay.
- More than one or two clips; streaming or downloadable catalogues; music, lyrics, books and articles.
- More than one AI character; separate AI personalities for the cast.
- Phoneme-level pronunciation scoring. Feedback is based on recognised text and confidence only.
- iOS polish, tablets, dark theme, payments, notifications, analytics.
- Machine-translated subtitles shipped as if they were verified. Every translation is either reviewed by a native-speaking teammate or marked `"reviewed": false`.

## Definition of done (demo)

- [ ] `flutter analyze` clean, `flutter test` green on `integration/hackathon-mvp`.
- [ ] Release APK installed on the demo phone; the demo path rehearsed twice end to end.
- [ ] Flight-mode run of the offline steps passes (`TEST_PLAN.md` §2).
- [ ] The voice tutor is either live and verified, or the fallback is shown and stated as such in the pitch.
- [ ] No secrets in the repo; every media item has a licence entry.
