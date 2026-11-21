# Interaction State Map

Each row gives: event (trigger) → app state → character state → visual and audio response → completion.

Character states always come from real app state. No arbitrary timers stand in for events.

## Spark: companion (home, lessons, path)

| Trigger | App state | Character | Response | Completes when |
|---|---|---|---|---|
| Home opens, no lessons yet | `p.completedNodeIds.isEmpty` | `waving` | Wave reaction; "Hi, I'm Spark!" + native line | Learner starts a lesson |
| Home after XP was earned elsewhere | `totalXp > seenXp` (header state) | `excited` | Double-hop; "+N XP!" with the real amount | Next tap or visit |
| Returning after 2+ days | `daysBetween(lastActive, today) ≥ 2` | `greeting` | "Welcome back!" (no guilt) | Any activity |
| Quests all done | `quests.every(done)` | `celebrating` | "Champion day!" | Next day |
| Words need water | `wordsNeedingWater > 0` | `curious` | "N words need water" | Garden watered |
| Spark tapped | — | `happy` | Hop + haptic; next tip in sequence | Next tap |
| Exercise shown | `verdict == null` | `curious` | Breathing, attentive | Answer checked |
| Correct / almost | `Verdict.correct/almost` | `happy` | Hop; `Sfx.correct`; light haptic; teal feedback panel | Continue |
| Incorrect | `Verdict.incorrect` | `confused` → panel `encouraging` | Tilt; answer shake; `Sfx.incorrect` (soft); solution shown | Continue / retry at end |
| Lesson complete | `completeLesson` returns | `celebrating` (Beat) or `excited` | Confetti; XP count-up; `Sfx.complete`, or `Sfx.achievement` on level-up/badge | Continue |

## Professor: Speak (`TutorSessionController.professorState`)

| Trigger | `TutorState` | Professor | Response | Completes when |
|---|---|---|---|---|
| Start pressed | `connecting` | `greeting` | Wave | `/v1/health` answered |
| Mic opened (live or tap) | `listening` | `listening` | Lean in; **real** level meter (or "Mic on" when the platform gives no level); live partial transcript | Final result / tap to send |
| "Ask in Amharic/Oromo" | `recordingNative` | `listening` | Real amplitude meter from the recorder | Tap stop |
| Audio uploaded | `transcribing` | `transcribing` | Thought dots | Scribe returns text |
| Waiting for Addis AI | `thinking` | `thinking` | Thought dots | Reply arrives |
| TTS / native clip playing | `speaking` | `speaking` (`speaking: true`) | Talking cadence **only during playback**; tap to interrupt | Playback ends |
| Learner correct / repeat passed | `idle` + feedback `great` or `repeatScore.passed` | `approving` | Hop; "Excellent!"; `Sfx.correct` | Next learner turn |
| Learner needs a fix | `idle` + feedback / failed repeat | `correcting` | Tilt; "Almost — let's fix one thing"; missing words in red; repeat task | Next learner turn |
| STT heard nothing | `idle` + message | `idle` | "I didn't catch that…" | Next try |
| Provider error | `error` | `confused` | Retry button; transcript kept | Retry |
| No relay / offline | `unavailable` | `sleeping` | Honest offline view + "Offline practice (not AI)" | Try again |
| End | `ended` | `celebrating` | Summary sheet; XP only for 3+ English turns | Done |

## Media lesson

| Trigger | State | Response | Completes when |
|---|---|---|---|
| Playback position enters a line | `controller.current` changes | Subtitle cross-fades and rises (200 ms); transcript row highlights | Next line |
| Phrase tapped | `controller.selected = e`; video paused | Phrase gets a gold fill in the subtitle; learning panel slides up | Panel closed → `clearSelection()` |
| Save | `vocabulary.save` completes | Button → "Saved"; badge "N in My Words" springs in; `Sfx.save` + haptic; **My Words tab badge bumps** | — (state persists) |

## XP and achievements

| Trigger | Response |
|---|---|
| `completeActivity` returns `ActivityReward` | Reward sheet: Beat celebrates, `AnimatedCount` XP, streak tile, badge line; `Sfx.xp` or `Sfx.achievement` |
| Home header sees higher XP | Spark reacts with the real amount; `StatPill` counts up |
