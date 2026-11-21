# [E1] Flutter frontend: four-tab shell, Learn polish, My Words

**Owner:** Engineer 1 · **Branch:** `feat/mobile-ui` · **Labels:** `frontend`, `demo-critical`
**Read first:** `docs/INTEGRATION_CONTRACTS.md` §1, §2, §5 and `docs/DESIGN_SYSTEM.md`

## Goal

Turn the milestone-1 app into the hackathon shell (Learn · Discover · Speak · My Words) so E2's and E3's screens plug in with no edits to your files. Build My Words, and keep the whole app premium, responsive and Ethiopic-correct.

## Owned files

- `lib/features/{onboarding,language_selection,home,learning_path,lessons,word_garden,achievements,mascot,my_words}/**`
- `lib/core/{theme,components,motion}/**`, `lib/data/local/**`
- Matching tests under `test/widget/`, `test/unit/`

## Tasks (in order)

1. **Shell (by T+1:00, the first PR so others can see their tabs).**
   - Rework `HomeShell` to the `HomeTab` order with keys `nav_Learn`, `nav_Discover`, `nav_Speak` and `nav_My Words`.
   - The Learn tab is the current dashboard plus the path.
   - Embed `DiscoverScreen()`, `SpeakScreen()` and `MyWordsScreen()`.
   - Keep the Word Garden and badges reachable: the garden inside My Words, badges from the Learn header.
   - Update the existing tests that tap `nav_Path`, `nav_Garden` and `nav_Badges`.
2. **My Words.**
   - List `ServicesScope.of(context).vocabulary.all` with a `ListenableBuilder` and `SavedExpressionTile` (expression, native meaning, context line, source icon).
   - Add an empty state and a section or entry for the Word Garden.
   - Widget test: saving through the repository updates the list.
3. **Home dashboard:** add a "Watch & learn" card that opens `AppRoutes.discover` and a "Talk to the Professor" card that opens `AppRoutes.speak`.
4. **Polish pass:**
   - Responsive layout at 360×640 and 1.3× text scale.
   - Semantics labels.
   - Reduced motion respected.
   - Promote reusable widgets from E2/E3 to `core/components` after T+3:30, if asked.

## Dependencies

- Contracts are already on the branch: `AppRoutes`, `HomeTab`, `AppServices`, `VocabularyRepository`.
- No blocking dependency on E2 or E3: their placeholder screens already exist.

## Acceptance criteria

- [ ] Premium visual quality consistent with `DESIGN_SYSTEM.md`, with no hard-coded colours or sizes.
- [ ] All four tabs work, navigation is functional, and Android back behaves.
- [ ] Amharic and Oromo render correctly everywhere, and `ethiopic_rendering_test` is green.
- [ ] My Words updates live and persists across restarts.
- [ ] Format, analyze and test are all green, and the PR goes to `integration/hackathon-mvp` with screenshots.
