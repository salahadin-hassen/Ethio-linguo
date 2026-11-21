# Character Rig Specification: Companion (Spark) & Professor

**Status (2026-11-21):**
- **Rive rigs authored with the official Rive CLI (1.10.0):** `companion.rml` and `professor.rml`. Both verify with 0 errors and were previewed headless state by state (§Rive CLI rigs).
- **Published and bundled:** `companion.riv` (32.8 KB) and `professor.riv` (36.0 KB) were built with `rive . --publish` after the owner approved `rive login`, on a Free workspace. The CLI reported both files as watermarked (Rive splash screen) because of the plan. The app now renders both characters from these files, and the interim code rig is used only if a `.riv` fails to load.
- **Engineering pipeline:** ready. A bundled `.riv` replaces the interim rig automatically.

## Rive CLI rigs (what was built)

| | Companion (Spark) | Professor |
|---|---|---|
| Source art (original vector) | `docs/design/characters/companion_art.svg` | `docs/design/characters/professor_art.svg` |
| Rive project | `assets/brand/characters/companion/` (`rive.yaml`, `companion.rml`) | `assets/brand/characters/professor/` (`rive.yaml`, `professor.rml`) |
| Artboard / state machine | `Companion` / `CompanionCharacter` | `Professor` / `ProfessorCharacter` |
| Verified states | `docs/design/characters/companion_states_rive_cli.png` | `docs/design/characters/professor_states_rive_cli.png` |

**Workflow:**
1. Each SVG was converted once with `rive svg`. Every `<g>` sits on its joint pivot, so it imports as a rig node.
2. The rig was then written by hand in RML, following `rive docs`: node ids, eye clips, look wrappers, lip-line vertices, view model, converters, state machine and animations.
3. Check with `rive . --verify` and `rive inspect .`.

**Skeleton (node hierarchy):**

```text
Root (feet, planted)
├── LegL
├── LegR
└── Body (hip pivot)
    ├── Torso
    ├── Neck
    ├── Head
    │   ├── Ears
    │   ├── EyeL / EyeR (clip) ── Look ── Pupil
    │   │                     └── Lid
    │   ├── Brows
    │   ├── Nose
    │   ├── Mouth ── LipLine (2 keyable bezier vertices)
    │   │         ├── MouthO
    │   │         └── Jaw
    │   └── Hair (+ Professor: Glasses, Moustache)
    └── ArmL / ArmR ── Forearm ── Hand
```

The ArmR / ArmL chains are two-bone, built from shoulder, elbow and wrist nodes.

**View model `Character`**, named exactly as in `RigContract`:
- **Numbers:** `emotion`, `gazeX`, `gazeY`, `mouthOpen`, `voiceAmplitude`, `idleVariant`
- **Booleans:** `isListening`, `isSpeaking`, `isThinking`, `isHappy`, `reducedMotion`
- **Triggers (both):** `tapReaction`, `celebrate`, `wave`, `laugh`, `correctAnswer`, `incorrectAnswer`, `achievementUnlocked`, `wakeUp`
- **Professor-only triggers:** `explain`, `pointToExample`, `nod`, `goodbye`

**State machine: five layers, applied in order:**
1. **Body:**
   - Three idle behaviours (rest/breathing, look-around, playful) chained at random by exit-time transitions with weights 3/2/1. Each idle is 3.5–5 s, so the 30 s loop is never one obvious cycle.
   - `reducedMotion` → a still pose.
2. **Face:**
   - `emotion` 0–7 → brow pose plus lip-vertex deformation: neutral, happy, curious, thinking, surprised (O-mouth), encouraging, gently disappointed, sleepy. Transitions blend over 160–400 ms.
   - `isHappy` turns neutral into happy.
3. **Blink:**
   - Random short or long open holds, single blinks and double blinks.
   - `emotion==7` closes the eyes (sleep).
4. **Gesture:**
   - One-shot triggers via Any State, each with anticipation → action → follow-through → recovery, returning to rest after exit time.
   - `tapReaction` picks its variant from `idleVariant` (0 surprise-giggle, 1 wave, 2 thumbs-up).
   - `isThinking` / `isListening` hold poses (hand to chin; attentive lean) and have dedicated return animations.
5. **Speech:**
   - Mouth closed when not speaking.
   - Authored talk loop when `isSpeaking` and no level is reported.
   - When `voiceAmplitude > 0.01`, a 1D blend (`mouthOpen` 0..1 through a range-mapper converter) drives the jaw between closed and open. On the Professor the moustache lifts with the jaw.
   - **Gaze:** `gazeX/gazeY` are data-bound to the pupil positions through a −1..1 → −6..6 px converter.

**No whole-image motion:** the feet never move. Everything else is part-based motion of the Body/Head/Arm/Face nodes. Nothing translates, scales or rotates the character as a whole.

**Verified with the CLI's headless renderer** (`rive . --data=… --advance=… --screenshot=…`):
- **Companion:** idle, gaze, happy, surprised, disappointed, celebrate, wave, thinking, talk loop, mouth driven to 1.0 and to 0.3, sleep.
- **Professor:** idle, listening, thinking, explain, point to example, speaking (audio-driven), correction, celebration, nod, goodbye, `isHappy`, gaze.
- **30 s idle check:** frames 3 s apart differ by 15–22% of pixels for both characters (never static).
- **Reduced motion:** 0% difference between frames 3 s apart.

**Mouth and Addis audio (honest scope):**
- The relay asks Addis for `pcm_16000`, which comes back as a 16 kHz WAV. It returns a 50 ms RMS loudness **envelope** with the clip.
- While the clip plays, the app samples the envelope at the real playback position (audioplayers position events, interpolated). It sends the result as `voiceAmplitude` (≥ 0.02 while playing) and `mouthOpen`.
- This is **amplitude-driven jaw motion, not phoneme or viseme lip-sync.**
- English lines use on-device TTS, which reports no level. For those the rig plays its authored talk loop while `isSpeaking`.

**Known limits:**
- **No bones or meshes:** these are node-transform rigs. Limbs bend at joints and faces deform through keyed bezier vertices. A Rive-editor rig with bones and meshes would bend sleeves smoothly; here the shoulder joint shows a seam in big arm raises.
- **Headless preview bug:** in the CLI's `--commands` mode, only the first capture of a session rendered on this machine. Each verification frame was therefore captured in its own process.
- **Splash screen:** per Rive's plans, files published on the free plan show a Rive splash/watermark, and a paid plan (Cadet or above) removes it. No plan was purchased; upgrading needs the owner's approval.

**Rebuild after editing an `.rml`:**
1. Run `rive . --publish` in its folder. This writes `build/<name>.riv`.
2. Copy that file next to the `.rml` (the path in `RigContract`).
3. Rebuild the app.

**Runtime evidence (release web build, headless Chrome):**
- **`docs/recordings/spark_rive_welcome_web_runtime.mp4`:** the welcome screen rendered from `companion.riv`. Gaze, head turns and blinks are visible.
- **`docs/recordings/professor_rive_live_addis_session_web_runtime.mp4`:** a real Addis session through thinking → speaking → listening, rendered from `professor.riv`.
- **`docs/recordings/professor_rive_mouth_speaking_vs_listening.jpg`:** close-up crops from that session. The mouth opens and closes while speaking and stays shut while listening. These frames do not separate the envelope-driven jaw from the fallback talk loop. The envelope path is covered by `tutor_test.dart` ("native clip drives the jaw…") and by a live relay call: a 2.2 s Amharic clip gave a 45-frame envelope.
- **Watermark:** no Rive splash was visible in these web captures, although the CLI says the files are watermarked. Check on a device before relying on it; removing it requires a paid plan and the owner's approval.
- **No art-style swap during load:** while the manifest and `.riv` load, the avatar area is blank, and the rig then fades in over 180 ms (instantly under reduced motion). The code-drawn puppet appears only if loading fails.

## Interim code rig (what exists today)

**Parts:** head, ears, eyes with pupils, lids and highlight, brows, nose, mouth (open, smile, round, teeth and tongue), cheeks, neck, torso, shoulders, two-bone arms with hand shapes (relaxed, open, point, thumb, fist, chin), legs and shoes. Spark also has his hair block. The Professor also has his cloud hair, glasses, moustache, beard and scarf.

**Layers** (`PuppetMotor`):
- **Expression:** emotion targets.
- **Sustained states:** listening lean with occasional nods; hand to chin while thinking, with the eyes up and away.
- **Gaze:** the eyes lead, the head follows.
- **Speech:** while `isSpeaking` is true, an authored syllable pattern plus head emphasis drives the mouth, and the Professor gestures with the dialogue (explain, point, nod).
- **Gestures:** keyframed with anticipation, action, follow-through and recovery, blended in and out.
- **Idle:** three variants on an irregular 7–16 s schedule.
- **Breathing:** torso and shoulder deformation.
- **Blinks:** irregular, every 2.2–6.5 s, with an 18% chance of a double blink.
- **Secondary:** hair and scarf lag behind the head and body.

**Overlapping action:** each body part has its own spring stiffness. The pupils are fastest, then the head, then the torso and hair.

**Constraints:**
- The feet stay planted. The character as a whole never translates, scales or rotates.
- Reduced motion: event-driven only, with no continuous ticking.

**Evidence** (`docs/recordings/`), recorded from the release web build in Chrome over the DevTools protocol:
- `spark_idle_web_runtime.mp4`: 14 s untouched home and welcome screen. Zero identical consecutive frames; gaze, a blink, a head tilt and the playful idle are visible.
- `professor_live_addis_session_web_runtime.mp4`: a real Addis session going thinking → speaking (mouth and gestures during playback) → listening.

**Limits** (why the Rive rigs below are still wanted):
- The art is code-drawn: flat vector with simple shading. It is not mesh-deformed and not illustrator-grade.
- Mouth movement is an authored pattern while audio plays. It is not lip-sync.

## 0. Blocker (historical — superseded by the Rive CLI rigs above)

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
