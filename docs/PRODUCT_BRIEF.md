# Product Brief

> **Learn from what you love. Understand it in your language. Speak it with confidence.**
> Working title: *Ethio Linguo* (not final; the name lives in `lib/app/app_config.dart`).

## Problem

Millions of Ethiopians need English for school, work and migration. Mainstream apps teach English *through English* or through a handful of global languages:

- Amharic speakers get, at best, an English-only interface.
- Afaan Oromo speakers, the largest language community in Ethiopia, get nothing in their language.
- The apps assume cheap, always-on data. Many learners have neither.
- They teach isolated words and do not help learners understand the English they actually meet in films, video and conversation, or speak it back.

## Target user

- **Primary:** an Ethiopian learner aged 15 to 30 who speaks Amharic or Afaan Oromo and has beginner to lower-intermediate English. They use an entry-level Android phone with patchy or metered data and are motivated by a job, a university or diaspora family.
- **Secondary:** teachers and youth programmes that need offline-capable practice material.

## Product proposition

An offline-first app that teaches English **through Amharic or Afaan Oromo**. It is built around a **Media-to-Conversation Learning Engine**:

1. **Watch.** The learner watches a short English clip with synchronised English and native-language subtitles.
2. **Understand.** They tap any highlighted expression to get its meaning *in this scene*, explained in their language.
3. **Keep.** They save it to **My Words**, which stores the context it came from and works offline.
4. **Speak.** They practise it immediately in a voice roleplay with **the Professor**, an AI tutor who knows the scene and gives feedback.
5. **Grow.** They earn XP and streaks, and their Word Garden grows.

## Differentiation

| Typical language app | This product |
|---|---|
| Instruction in English or a few global languages | Amharic and Afaan Oromo are first-class: native scripts, bundled Ethiopic fonts, and no flags |
| Isolated, decontextualised words | Expressions learned *from a scene* and kept with that context |
| Speaking practice disconnected from content | The Professor roleplays the scene the learner just watched |
| Online-only | Lessons, media, saved words and progress all work offline |
| Generic mascot gamification | An original Ethiopian-rooted visual world (see `DESIGN_SYSTEM.md`) |

## Main user journey (hackathon demo)

1. The learner chooses **Amharic** or **Afaan Oromo**.
2. They open **Discover** and start a short English clip.
3. English subtitles appear with a synchronised native-language line underneath.
4. They tap a highlighted expression (chosen with the clip) and a contextual explanation opens in their language.
5. They tap **Save**. The expression appears in **My Words**.
6. They tap **Practise with the Professor**. A voice roleplay of the same scene starts and the Professor gives feedback.
7. The activity completes: XP is awarded, the streak updates and progress is saved.
8. In flight mode, the clip, subtitles, saved words and learning path all still work.

The full scope and its exclusions are defined in `MVP_SCOPE.md`.
