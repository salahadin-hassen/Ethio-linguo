# Motion & Sound System

One motion language for the whole app. Tokens live in `lib/core/motion/motion.dart`, and every animation reads `Motion.of(context, …)`, so the OS "reduce motion" setting turns movement off everywhere.

## Tokens

| Token | Value | Use |
|---|---|---|
| `press` | 120 ms | button and tile press (`Pressable`: scale/lip + haptic) |
| `feedback` | 200 ms | small state feedback: subtitle line change, status text |
| `medium` / `card` | 260 / 280 ms | card and selection transitions, bubbles |
| `screen` | 320 ms | page transitions (`AppPageRoute`: fade + rise) |
| `reaction` | 380 ms | character reactions, save confirmation |
| `slow` | 420 ms | progress fills, XP count-up |
| `achievement` | 900 ms | double-hop celebration, badge reveal |
| `celebrate` | 1600 ms | lesson completion (confetti appears only here) |

| Curve | Use |
|---|---|
| `emphasized` (easeOutCubic) | entrances and state changes |
| `exit` (easeInCubic) | things leaving |
| `bouncy` (easeOutBack) | selection, pose swaps |
| `spring` (damped, ~13% overshoot) | character reactions, rewards, badge bump |

## Rules

- Every animation explains a state change, confirms an action, or rewards progress. Nothing loops just to look busy.
- Only one thing celebrates at a time. Confetti is kept for lesson completion and badge unlocks.
- Reduced motion: characters still change pose, but there is no movement, no idle timers and no thought-dot animation. Every transition becomes instant.
- Animation is never the only signal. Every state also has text and semantics labels.

## Characters

- **All motion lives in the designer's rig.** Characters are animated **only** by rigged Rive files: breathing, blinks, gaze, gestures and speech. Flutter sends meaningful inputs through `CharacterRigController` and never moves the character itself.
- **Rejected approach removed.** The earlier whole-image transforms (hop, tilt, bob, scale) were rejected and have been taken out.
- **Fallback.** Until `companion.riv` and `professor.riv` are delivered (see `CHARACTER_RIG_SPEC.md`), the app shows the static pose for each state and cross-fades between poses.

## Sound (`lib/services/audio/sound_effects.dart`)

- **Sounds:** `correct`, `incorrect`, `xp`, `save`, `complete`, `achievement`, `tap`.
- **Format:** 22 kHz mono WAV, 132 KB in total. All are **original**, synthesized by `tool/sfx/make_sfx.py`, with no samples and no third-party audio.
- **Playback:** quiet by design (volume 0.6). The incorrect sound is soft and falling, never harsh.
- **When:** only on meaningful events. Bigger events get the bigger sound, never both.
- **Setting:** an on/off toggle in the home header, persisted as `settings_sound_v1`. Sound is optional, and every sound has a visual twin.
- **Mute switch:** device mute is respected by the OS media stream on Android. The app does not detect the silent switch.

## Future assets (production)

| Need | Why |
|---|---|
| Rive (or sprite) rigs for Spark and the Professor | Real blinking, mouth shapes driven by audio amplitude, body language |
| High-resolution character artwork | Current poses are cut from a 1260×680 sheet, about 110 px tall each |
| More poses: Professor *listening* and *surprised*; Spark *thinking* and *sleeping* | Today motion stands in for these |
