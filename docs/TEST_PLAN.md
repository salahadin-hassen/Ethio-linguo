# Test Plan

Automated checks run on every PR:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Each PR pastes the results. Manual checks run on the **demo Android phone** at T+4:30 and again after the freeze. Record pass/fail in the integration PR.

## 1. Functional

| ID | Check | Auto / Manual |
|---|---|---|
| F1 | Onboarding → language → home for both languages | Auto (existing) |
| F2 | Lesson flow, XP, streak, hearts, completion | Auto (existing) |
| F3 | `recordActivity` adds XP and daily XP and extends the streak | Auto (`contracts_test`) |
| F4 | Saving an expression persists, deduplicates and survives a restart | Auto (`contracts_test`) + manual kill/relaunch |
| F5 | My Words lists saved items live and shows an empty state | E1 widget test |
| F6 | Media lesson completion awards 15 XP once | E2 widget test |

## 2. Offline (flight mode, demo phone)

- [ ] Cold start in flight mode → home loads with no error.
- [ ] Learning path lesson playable end to end.
- [ ] Discover lists the clip; the clip plays; both subtitle tracks show.
- [ ] Expression sheet opens; Save works; My Words shows it after a relaunch.
- [ ] Speak shows the honest unavailable state, not a spinner and not fake replies.
- [ ] Amharic and Oromo text render with no tofu boxes (also covered by `ethiopic_rendering_test`).

## 3. Media

| ID | Check |
|---|---|
| M1 | The manifest parses (unit test loads every manifest in `index.json`) |
| M2 | Segments are sorted and non-overlapping, and each `expression.en` occurs in its segment (unit test) |
| M3 | Subtitles appear within ±250 ms of speech at the start, middle and end (manual, watch twice) |
| M4 | Pause, seek and replay keep subtitles in sync |
| M5 | Switching native language changes the second subtitle line |
| M6 | A missing translation falls back to English only, never blank |
| M7 | Every item has a `license`, and the clip is original or rights-cleared (review) |

## 4. Voice interaction

| ID | Check |
|---|---|
| V1 | `/v1/health` is OK from the phone's network |
| V2 | The opening line references the scene (`sceneSummary`) |
| V3 | Hold → speak → release: transcript shows the recognised text, then the reply is spoken and shown |
| V4 | Feedback appears for a deliberately wrong sentence |
| V5 | The relay is killed mid-conversation → `error` + Retry, and the transcript is kept |
| V6 | No `TUTOR_BASE_URL` → `unavailable` state |
| V7 | Mic permission denied → explanation and typed fallback |
| V8 | Latency from release to reply is under 4 s on demo Wi-Fi (measure 5 turns) |
| V9 | STT works on the demo phone (check whether offline STT is installed) |
| V10 | `git grep -nE "sk-|api[_-]?key"` finds no secrets, and the APK contains no provider key |

## 5. Navigation

- [ ] All four tabs open, and keys `nav_Learn`, `nav_Discover`, `nav_Speak`, `nav_My Words` exist.
- [ ] Every `AppRoutes` route resolves (`routes_contract_test`).
- [ ] Media → Speak handoff passes `TutorContext`. Back from Speak returns to the media lesson or the reward.
- [ ] The Android back button never exits mid-lesson without confirmation.

## 6. Regression

- [ ] The full `flutter test` suite is green on `integration/hackathon-mvp` after each checkpoint merge.
- [ ] The milestone-1 journey still works: lesson, completion, garden and badges.
- [ ] Release APK builds: `flutter build apk --release`.
- [ ] No layout overflow at 360×640 and at 1.3× text scale on the four tab screens.
