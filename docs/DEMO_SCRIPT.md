# Demo Script (≈ 4 minutes)

> Device: an Android phone with the release APK from `main` (tag `demo-v1`), mirrored to the screen.
> Before going on stage: progress reset, language not yet chosen, demo Wi-Fi connected, tutor relay health-checked.
> Have a second phone ready in flight mode with the same build already onboarded.

## 1. Problem (30 s)

"Tens of millions of Ethiopians speak Amharic or Afaan Oromo. Most English apps teach in English, assume constant data, and drill isolated words. Learners meet real English in video and conversation, and nothing helps them understand it *in their own language* or say it back."

## 2. Demonstration (2 min 30 s)

| # | Action | Say |
|---|---|---|
| 1 | Welcome → choose **Afaan Oromo** (or Amharic) | "Instruction is in your language and your script. No flags. Fonts are bundled, so Ethiopic always renders." |
| 2 | Home → **Discover** → open the clip | "Learn from what you love. This is an original scene our team wrote and produced." |
| 3 | Play. Point at both subtitle lines | "English, and right under it, the meaning in Afaan Oromo, in sync." |
| 4 | Tap the highlighted expression | "Not a dictionary entry: why they say it *in this scene*, explained in Oromo." |
| 5 | **Save** → glance at My Words | "It's kept with its context, offline." |
| 6 | **Practise with the Professor** → hold the mic, speak the line | "The Professor knows the scene I just watched. This is a live AI turn: my speech, a real model, a spoken reply." |
| 7 | Show the feedback card, then finish | "Feedback on what I actually said, with a note in my language." |
| 8 | Reward screen: XP and streak | "Progress, streak and the Word Garden all update." |
| 9 | Second phone, **flight mode**: Discover, clip and My Words all work | "Everything except the live Professor works with no data at all." |

**If the tutor is down:** show the "Professor is offline" state and say exactly that: "The live tutor needs a connection. Here is what the learner sees when there isn't one." Never fake it.

## 3. Key differentiators (30 s)

1. Ethiopian languages are first-class, not translations bolted on.
2. The Media-to-Conversation loop: **watch → understand → keep → speak**.
3. It is offline-first by design, for real phones and real data budgets.

## 4. Technical explanation (20 s)

"Flutter, one codebase. Content is a versioned JSON manifest per clip, so adding media is adding data. The AI tutor sits behind a provider-agnostic interface and a small relay that keeps keys off the phone. Progress and words are stored on the device. There are 88+ automated tests, including glyph-coverage tests for Ethiopic."

## 5. Closing pitch (10 s)

"Learn from what you love. Understand it in your language. Speak it with confidence. Next: music, books and more Ethiopian languages, as content, not rewrites."
