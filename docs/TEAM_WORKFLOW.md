# Team Workflow

## Roles

| Person | Role | Decides |
|---|---|---|
| Salahadin | Project Owner / PM | Product priority, scope cuts, demo narrative. **Not** an implementation resource |
| Senior Tech Lead (ChatGPT) | Architecture and integration reviewer | Contract changes, technical disputes, PR approval into integration |
| Engineer 1 | Flutter frontend | Shell, tabs, Learn, My Words, shared components and tokens |
| Engineer 2 | Media learning and offline content | Discover, media lesson, subtitles, expressions, saving, clip package |
| Engineer 3 | AI voice tutor | Speak, TutorService implementation, relay server, fallback |

## Branches

```
main                        stable: demo-ready only; changed by PR from integration
└─ integration/hackathon-mvp   all feature PRs land here; must always build
   ├─ feat/mobile-ui        Engineer 1
   ├─ feat/media-learning   Engineer 2
   └─ feat/ai-tutor         Engineer 3
```

- Branch from `integration/hackathon-mvp`, which already contains the contracts.
- Rebase or merge `integration` into your feature branch at least **hourly**.
- **Never force-push** `main`, `integration/*` or a teammate's branch.

## File ownership

| Path | Owner |
|---|---|
| `lib/features/{onboarding,language_selection,home,learning_path,lessons,word_garden,achievements,mascot,my_words}/**`, `lib/core/{theme,components,motion}/**`, `lib/data/local/**` | E1 |
| `lib/features/{discover,media_lesson}/**`, `assets/content/media/**`, `AssetMediaRepository` body | E2 |
| `lib/features/speak/**`, `lib/services/tutor/**` (new files), `server/**` | E3 |
| **Shared** (PR labelled `integration`, Tech Lead review): `lib/app/**`, `lib/main.dart`, `lib/core/navigation/**`, `lib/data/models/**`, repository interfaces, `lib/services/tutor/tutor_service.dart`, `pubspec.yaml`, `docs/INTEGRATION_CONTRACTS.md` | — |

**Additive-change rule for shared files:**

- `pubspec.yaml`: add only your own dependency lines.
- `app.dart`: route cases already exist, so don't touch them.
- `main.dart`: change only your service's line.

Any other edit to someone else's file needs their OK in the PR.

## Pull-request rules

1. PR into `integration/hackathon-mvp` (never into `main`), using the template.
2. Small, focused PRs, at least one every 60–90 minutes. Commit messages are imperative and descriptive.
3. `dart format`, `flutter analyze` and `flutter test` must be green, with the output pasted in the PR. Never hide failures; mark known failures in the PR.
4. Add screenshots or a short recording for UI changes.
5. No secrets, no unlicensed media, no generated `build/` output.
6. Review: the Tech Lead, or another engineer if the Tech Lead is blocked for more than 10 minutes. Squash-merge.

## Integration procedure

- **T+1:30 and T+2:30:** checkpoint merges. Each workstream merges whatever compiles, even behind a placeholder.
- **T+3:30:** feature merge deadline. After it, `integration` is the only branch being changed.
  - E1 wires the tabs, E2 → E3 wires the handoff, and everyone runs the demo path together.
- **T+5:15:** feature freeze. Only demo-blocking fixes after that.
- **T+5:30:** PR `integration/hackathon-mvp` → `main`, tag `demo-v1`, then build the release APK from `main`.

## Escalation procedure

1. Blocked for more than 15 minutes? Post in the team channel with the label `blocker`: what, where and what you tried.
2. Contract mismatch: stop and raise it with the Tech Lead. Never fork a model "just for now".
3. Scope trade-off (dropping or replacing a feature): the Tech Lead proposes and the **Project Owner decides**.
4. Anything threatening the demo path gets the `demo-critical` label and goes to the top of everyone's list.
