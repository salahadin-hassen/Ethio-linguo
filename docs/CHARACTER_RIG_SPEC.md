# Character Rig Specification: Companion (Spark) & Professor

**Status (2026-11-21): the engineering pipeline is ready, the rigs do not exist yet.**

## 0. Blocker

The animation this directive asks for needs artwork that is drawn and rigged by hand in the **Rive editor**: bones, meshes, facial controls, state machines and blend layers. Two things stop that from happening here:

1. **No Rive editor.** The engineering environment has no access to the Rive editor or any rigging tool, so no real `.riv` character rig can be authored or exported. A rig generated from code would be exactly the "fake animation" the directive forbids.
2. **Raster source art.** The only character art is a 1260×680 screenshot, roughly 110 px per pose, with flattened parts. It cannot be rigged. Rigging needs layered **vector** source art (§2).

Under the directive, the following is **not** shipped as character animation:
- whole-image bounce, hop, tilt or scale (removed in this change)
- a procedural stand-in

Until the rigs exist, the app shows the authored static pose for each state, with a short cross-fade between poses. This is labelled as a fallback in the code and the docs.

**What is done (Flutter side):**
- **Runtime:** `rive ^0.14.11` (`rive_native 0.1.11`).
- **Controller and binding:**
  - `CharacterRigController` is the app-facing API.
  - `RiveCharacter` loads the `.riv`, binds the view model (or state-machine inputs), and mirrors state into it. It disposes everything in reverse order.
- **Event mapping:** every real app event already drives the controller, including speaking from real audio playback, taps, verdicts, listening and thinking.
- **Automatic switch-over:** the moment a `.riv` is dropped into the asset path below, it is used. No code change is needed. In debug builds, any contract inputs the rig lacks are logged.

## 1. Files and names (contract: `lib/features/mascot/rig/rig_contract.dart`)

| Character | File | Artboard | State machine |
|---|---|---|---|
| Companion (Spark) | `assets/brand/characters/companion/companion.riv` | `Companion` | `CompanionCharacter` |
| Professor | `assets/brand/characters/professor/professor.riv` | `Professor` | `ProfessorCharacter` |

- **Runtime compatibility:** export for the Rive runtime used by `rive_native 0.1.11` (Flutter `rive 0.14.11`). Use the Rive renderer and test in the Rive editor's Flutter preview.
- **Data binding (preferred):** set the default view model instance to *exported*. Its properties use the names below: Number, Boolean and Trigger types.
- **Inputs (accepted):** state-machine inputs with the same names also work. Rive has deprecated inputs, but the app supports both and tries data binding first.

### Numbers
| Name | Range | Meaning |
|---|---|---|
| `emotion` | 0–7 | 0 neutral, 1 happy, 2 curious, 3 thinking, 4 surprised, 5 encouraging, 6 disappointed (gentle), 7 sleepy |
| `gazeX`, `gazeY` | -1…1 | Where the eyes and head look (taps send the touch point) |
| `voiceAmplitude` | 0…1 | **Real** playback level when available (0 otherwise) |
| `mouthOpen` | 0…1 | Direct jaw override (= amplitude while speaking) |
| `idleVariant` | 0, 1, 2 | Idle A (rest), Idle B (curious), Idle C (playful). The app rotates it on taps. **The rig should also vary idles on its own** with random timing |

### Booleans
`isListening`, `isSpeaking` (true **only** while audio plays), `isThinking`, `isHappy`, `reducedMotion`. When `reducedMotion` is true, keep blinks and expression changes, and drop body travel and gestures.

### Triggers
`tapReaction`, `celebrate`, `wave`, `laugh`, `correctAnswer`, `incorrectAnswer`, `achievementUnlocked`, `wakeUp`.

Professor-only: `explain`, `pointToExample`, `nod`, `goodbye`.

## 2. Source art required (from the character designer)

- **Vector source:** Figma, Illustrator or SVG, matching the existing character bible (Spark: coral jacket and high-top hair; Professor: white hair cloud, gold glasses, green waistcoat, scarf).
- **Separate layers per part**, named like `head`, `jaw`, `eye_L/R_white`, `pupil_L/R`, `eyelid_upper_L/R`, `brow_L/R`, `mouth_*`, `cheek_L/R`, `neck`, `torso`, `shoulder_L/R`, `upperarm_L/R`, `forearm_L/R`, `hand_L/R` (plus finger groups for pointing and the thumbs-up), `hips`, `thigh_L/R`, `shin_L/R`, `foot_L/R`.
- **Secondary parts:**
  - Spark: hair block, jacket hem, lightning stripe.
  - Professor: hair cloud lobes, glasses, scarf ends, waistcoat flaps.
- **Mouth set:** at least rest, smile, open-small, open-wide, "O", "E", "M/B/P" (closed), laugh. Draw them as **mesh-deformable shapes** so transitions blend; do not swap images.
- **Pose:** neutral, three-quarter front, arms relaxed. Rendered with the brand's shading (one shade plane plus a highlight) so the character looks finished when still.

## 3. Rig requirements

- **Bones:** a spine chain (hips → torso → neck → head), arms using **IK** with hand targets, legs with IK for weight shifts.
- **Meshes and weights** on the torso (breathing), cheeks, mouth, brows and eyelids. Breathing comes from torso and shoulder deformation; the whole character must not move up and down.
- **Constraints:** pupils limited inside the eye whites; distance constraints on secondary parts (hair, scarf) so they lag and settle as follow-through.
- **Expression rigs:** independent brow raise and furrow, eyelid open and squint, cheek lift on smile.

## 4. State machine layers (both characters)

1. **Base / Idle:** a blend of Idle A, B and C, picked by `idleVariant` plus the rig's own random timer (8–20 s between variants). There is always gentle breathing and natural blinking at irregular 2–6 s intervals, with an occasional double blink.
2. **Expression:** a blend state on `emotion` that drives brows, lids, mouth and cheeks.
3. **Gaze:** a 2D blend on `gazeX`/`gazeY`. The eyes lead, the head follows about 80 ms later, and the torso a little after that.
4. **Gesture:** one-shot clips fired by triggers, each with anticipation, action, follow-through and recovery back to the base layer.
5. **Speech:** while `isSpeaking`, an authored speech loop with mouth shapes and head emphasis. Use `voiceAmplitude` to open the jaw when it is non-zero. No phoneme accuracy is claimed.
6. **Secondary:** hair, scarf and clothing follow-through, driven by constraints.

Transitions must blend (100–250 ms) and must never cut to unrelated poses. Gestures must not fight speech: the speech layer only drives mouth and head.

## 5. Animation list

**Companion (Spark):**
breathing · blinking · eye tracking · look left and right · look at learner · head tilts · curious lean · thinking gesture (chin) · excited reaction · smile · laugh · wave · small celebration dance · encouraging gesture (thumbs up or fist) · surprised · gentle disappointment · sleeping · waking up.

**Professor:**
explaining (raised hand and open palm) · pointing to an example · thinking (hand to chin, eyes up and away) · listening (lean forward, occasional nod, soft eye movement) · surprised (brows up, small step back) · correcting (gentle "one finger" teaching gesture, then an inviting open palm) · approving (smile and nod or thumbs up) · laughing · congratulating (applause) · goodbye (wave).

**Timing guidance:**
- Reactions: 400–900 ms.
- Celebrations: 1.2–1.8 s.
- Anticipation is about 15% of the clip, follow-through about 25%.

## 6. App event → rig (already wired; full table in `INTERACTION_STATE_MAP.md`)

| App event | Controller call | Rig receives |
|---|---|---|
| Mic opens (real recognizer or recorder) | `applyState(listening)` | `isListening`, `emotion=curious`, `nod` |
| Waiting for Addis Chat | `applyState(thinking)` | `isThinking`, `emotion=thinking` |
| Native-voice clip or TTS **playing** | `setSpeaking(true)` → `false` on completion or interrupt | `isSpeaking`, `voiceAmplitude` (0 today) |
| Learner correct, or repeat passed | `applyState(approving)` | `correctAnswer`, `isHappy` |
| Learner needs a fix | `applyState(correcting)` | `incorrectAnswer`, `emotion=encouraging` |
| Lesson complete, or XP earned on home | `applyState(celebrating/excited)` | `celebrate` |
| First visit or welcome back | `applyState(waving/greeting)` | `wave` |
| Tap | `reactToTap(x,y)` | `gazeX/Y` toward the touch, `tapReaction`, `idleVariant` rotation |
| Offline Professor | `applyState(sleeping)` | `emotion=sleepy`; `wakeUp` when it changes |

**Audio amplitude:** neither device TTS nor `audioplayers` exposes the playback level, so `voiceAmplitude` is currently 0 and the rig's authored speech loop drives the mouth. There are two future options:
- The relay could return an amplitude envelope alongside the Addis audio.
- The app could switch to a player that reports levels.

## 7. Performance budget (affordable Android)

| Item | Budget |
|---|---|
| `.riv` file size | ≤ 400 KB per character |
| Bones | ≤ 60 |
| Weighted vertices | ≤ 1,500 |
| Images | None. Vectors only, no embedded raster |
| Frame rate | Holds 60 fps in the Rive preview at 300×300 on a mid-range device |

The app keeps one controller per on-screen character and disposes it on unmount. The rig should also stop all idle activity at `reducedMotion`.

## 8. Acceptance tests (run on a real device with a screen recording)

| Test | How |
|---|---|
| A. Idle observation | Home screen, 30 s untouched: breathing, irregular blinks, at least 2 idle variants, no repeated loop feel |
| B. Touch | Tap Spark 5×: the gaze goes to the touch point, with varied reactions |
| C. Emotional range | Drive `emotion` 0–7 in the Rive preview: each reads differently in both face and body |
| D. Full-body action | Finish a lesson: `celebrate` involves head, eyes, arms, torso and secondary parts |
| E. Voice | Speak tab with the relay running: idle → listening → thinking → speaking; the mouth moves only while audio plays |
| F. Recovery | Interrupt speech (tap the banner), end the session, go home: no stuck speaking or listening state |
| G. Quality | Recording review: no whole-image bouncing; the face and body act |

## 9. Handoff steps

1. The designer exports `companion.riv` and `professor.riv` to the paths in §1.
2. `flutter run -d chrome`. In debug, the console logs `rig: … lacks inputs: [...]` for any missing contract names.
3. Run acceptance tests A–G, then record the screen.
4. The supporting cast (Wry, Beat) reuses the same contract: add an entry to `RigContract.specs`.
