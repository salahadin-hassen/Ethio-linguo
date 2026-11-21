# [E2] Media learning: Discover, synced bilingual subtitles, expressions, save

**Owner:** Engineer 2 · **Branch:** `feat/media-learning` · **Labels:** `media`, `demo-critical`
**Read first:** `docs/INTEGRATION_CONTRACTS.md` §2, §3, §4, §5, §6, §9 and `docs/OFFLINE_STRATEGY.md`

## Goal

A learner opens Discover, watches one short English clip with synchronised English and Amharic or Afaan Oromo subtitles, taps an expression, reads its meaning in context, saves it, finishes for XP, and continues to Speak. All of this works offline.

## Owned files

- `lib/features/discover/**`, `lib/features/media_lesson/**`
- `assets/content/media/**` (`index.json`, `<id>/manifest.json`, `clip.mp4`, `poster.jpg`)
- `AssetMediaRepository` body in `lib/data/repositories/media_repository.dart` (keep the interface)
- Tests: `test/unit/media_manifest_test.dart`, `test/widget/media_lesson_test.dart`
- Shared, additive only: the `video_player` dependency line in `pubspec.yaml`

## Tasks (in order)

1. **Demo content (start now, in parallel).**
   - Record or obtain **one original** 20–40 s English clip: two people, everyday scene, clear audio. Export as H.264, ≤ 720p, ≤ 10 MB.
   - Write the manifest using schema v1, with 2–4 tappable expressions.
   - Get the Amharic and Afaan Oromo lines from native-speaking teammates. Set `"reviewed": true` only after they check them.
   - Fill in the `license` block.
2. **Manifest test:**
   - every manifest in `index.json` parses
   - segments are sorted and non-overlapping
   - each `expression.en` occurs in its segment
   - each item has a licence
   - every `translations` map has `am` and `om` or falls back cleanly
3. **Discover screen:** cards from `ServicesScope.of(context).media.list()`, then `pushNamed(AppRoutes.mediaLesson, arguments: MediaLessonArgs(id))`. It must work as a tab (no app bar back button) and as a route.
4. **Media lesson screen.**
   - Use `video_player` with an asset source. The player position drives `MediaItem.segmentAt(ms)`.
   - `SubtitlePanel` shows English with highlighted expressions and the native line from `Translations.of(AppScope.of(context).native)`.
   - Play, pause and replay controls.
5. **Expression sheet:**
   - Tapping an expression pauses the video and opens `showAppSheet`.
   - The sheet shows the meaning, the scene explanation and the context line.
   - **Save** calls `vocabulary.save(SavedExpression.fromMedia(...))` and shows a saved state.
6. **Finish:**
   - At the clip end, show a summary: lines watched and expressions saved.
   - Call `recordActivity(activityId: 'media:<id>', xp: 15)` once.
   - Add a CTA, **Practise with the Professor**, that does `pushNamed(AppRoutes.speak, arguments: TutorContext(native:, mediaId:, sceneSummary:, targetExpressions: saved en strings))`.

## Dependencies

- Uses only the existing contracts. E3 consumes your `TutorContext`, so agree on the sceneSummary wording by T+1:30.
- The Linux desktop cannot play `video_player`. Test on Android, and run widget tests with an injectable player or a position stream.

## Acceptance criteria

- [ ] One video is playable on the demo Android phone.
- [ ] Captions stay within ±250 ms through play, pause and seek.
- [ ] Both Amharic and Afaan Oromo subtitle lines work, and a missing translation falls back to English only.
- [ ] Selecting a phrase opens its contextual explanation.
- [ ] Saving persists locally and survives a restart, with no duplicates.
- [ ] The whole flow works in flight mode.
- [ ] The media is original or rights-cleared, with its licence recorded. No translations are presented as reviewed unless they were reviewed.
