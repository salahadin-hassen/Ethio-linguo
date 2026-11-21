# Design System

Direction: **premium, playful and distinctly Ethiopian.** All tokens live in `lib/core/theme/` and `lib/core/motion/`. Screens never hard-code colours or durations.

## Colour

### Brand tokens (from the brief)

| Token | Hex | Role |
|---|---|---|
| `indigo` | `#242443` | Primary text, dark hero surfaces |
| `ivory` | `#FFF8EF` | App background |
| `coral` | `#FF705B` | Primary call to action, hearts, "try again" |
| `teal` | `#20B8A6` | Correct, progress, Word Garden |
| `gold` | `#F4BD50` | XP, levels, completed nodes, mascot |
| `periwinkle` | `#7183F5` | Selection, XP icon, secondary accent |

### Accessibility finding and the rule that follows

Measured WCAG 2.x contrast:

| Foreground | on ivory | white text on it | indigo text on it |
|---|---|---|---|
| coral | 2.58 ✗ | 2.72 ✗ | **5.48 ✓** |
| teal | 2.35 ✗ | 2.48 ✗ | **6.01 ✓** |
| gold | 1.63 ✗ | 1.72 ✗ | **8.69 ✓** |
| periwinkle | 3.18 ✗ | 3.35 ✗ | 4.45 (passes for large/bold text) |
| indigo | **14.15 ✓** | — | — |

Rule:

1. Brand colours are **fills**. Text on top of them is always **indigo**. That is why CTAs read "coral button, indigo label".
2. Coloured **text** on light surfaces uses the darker *ink* tokens:

| Ink token | Hex | Contrast on ivory |
|---|---|---|
| `coralInk` | `#C23D2A` | 4.99 |
| `tealInk` | `#0B6E63` | 5.82 |
| `goldInk` | `#8A5A00` | 5.62 |
| `periwinkleInk` | `#4F5FD6` | 5.06 |
| `textMuted` | `#6B6A85` | 4.95 |
| `onIndigoMuted` (on indigo) | `#C9C8E6` | ~9.0 |

### Surfaces

The app is light (ivory). Dark **indigo** is used on purpose for hero areas: the dashboard header, the level card and the completion progress card. Those areas use ivory, gold and `onIndigoMuted` text. A full dark theme is future work.

## Typography

- **Nunito** (bundled, OFL) is the UI typeface, used for English and Afaan Oromo (Latin/Qubee).
- **Noto Sans Ethiopic** (bundled, OFL) is declared as `fontFamilyFallback` on every text style, so Amharic always renders from bundled glyphs and never from device fonts.
- Verified by `test/widget/ethiopic_rendering_test.dart`:
  - The bundled Ethiopic font's `cmap` covers **every** Ethiopic character in `lib/`, in all four weights.
  - Every non-ASCII character in `lib/` is covered by Nunito or the fallback.
  - Ethiopic advance widths through the fallback chain equal those of Noto Sans Ethiopic directly, which proves the glyphs are real and not tofu boxes.
- Line heights are 1.3–1.45 with `TextLeadingDistribution.even`, because Ethiopic glyphs are taller than Latin x-height.

| Style | Size / weight | Use |
|---|---|---|
| display | 34 / 900 | Hero headlines |
| headline | 26 / 900 | Card titles, instructions |
| title | 20 / 800 | Section titles |
| prompt | 28 / 800, line height 1.4 | Words being learned (often Ethiopic) |
| body | 16 / 600 | Copy |
| label | 15 / 800, uppercase on buttons | Buttons, tiles |
| caption / overline | 12–12.5 / 700–900 | Meta text, eyebrows |

## Spacing, shape and depth

- 4-pt spacing scale (`Space`). Page gutter 20.
- Radii 12 / 16 / 22 / 28 / pill.
- **Tactile depth:** pressable surfaces sit on a darker 4–6 px "lip" that sinks when pressed (`Pressable`). The same physical language is used for buttons, answer tiles, language cards, path nodes and garden plots.

## Motion (`Motion`)

| Token | Value | Use |
|---|---|---|
| fast | 140 ms | Press feedback, tile states |
| medium | 260 ms | Page transitions, expression changes |
| slow | 420 ms | Progress fills, count-ups |
| celebrate | 1600 ms | Confetti, level and unit bars on completion |

- Every animated component checks `Motion.reduced(context)` (the OS reduce/remove-animations setting). Loops stop and transitions become instant.
- Confetti is one painter with about 48 particles, inside a `RepaintBoundary`. There are no per-particle widgets, so it stays cheap on low-end Android.

## Components (`lib/core/components/`)

| Component | Purpose |
|---|---|
| `Pressable` | 3D press surface with haptic tick, semantics and selected state |
| `AppButton` | Single button: primary / success / danger / secondary / dark / ghost, plus a disabled state |
| `AppCard`, `SectionHeader` | Standard raised surface and heading |
| `StatPill` | Streak, XP and hearts with an animated count |
| `BrandIcon` | Custom-drawn flame, XP, heart, gem, leaf, lock, check, crown, star |
| `AppProgressBar`, `ProgressRing` | Animated linear and circular progress (with an optional fill-from value) |
| `AnimatedCount` | Count-up numbers |
| `SpeechBubble` | Brand metaphor for communication |
| `TibebBand` | Woven-border cultural signature |
| `Entrance` | Staggered fade-and-rise for screen entrances |
| `Shake` | Wrong-answer shake |
| `ConfettiBurst` | One-shot celebration |
| `EmptyState` | Mascot + message + action, for empty and error states |
| `showAppSheet` | Bottom sheet that scrolls instead of overflowing |

Feature components: `Mascot`, `PathNodeButton`, `UnitHeader`, `AnswerTile`, `FeedbackPanel`, `LessonTopBar`, `WordPlant`, `GardenPlot`, `LanguageOptionCard`.

## Language identity

Languages are identified by **their own script and name**, never by flags:

- **አ** · አማርኛ (Amharic)
- **Q** · Afaan Oromoo (Qubee)
- **Aa** · English

(Ethiopic **ሀ** was tried first. At card size it reads as a Latin "U", so it was replaced with **አ**, the first letter of አማርኛ.)
