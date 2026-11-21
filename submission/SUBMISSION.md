# Ethio-Linguo: Project Submission

> Learn from what you love. Understand it in your language. Speak it with confidence.

## Problem

Tens of millions of Ethiopians speak Amharic or Afaan Oromo as their first language. Most English-learning apps explain English in English, assume constant mobile data, and drill isolated words. Learners meet real English in video and conversation, but nothing helps them understand it in their own language or practise speaking it.

## Who it serves

Amharic and Afaan Oromo speakers learning English, from beginner to conversational, on affordable Android phones with unreliable data.

## Solution

A gamified English course taught through the learner's own language, built around one loop: **watch** a short real-life English scene, **understand** its expressions in Amharic or Afaan Oromo, **keep** them in My Words, and **speak** them with the Professor, an AI tutor who answers in English and coaches in the learner's language.

## What is new about it

- **Taught through Amharic and Afaan Oromo**, not English: every explanation, subtitle and coaching line is in the learner's language (labelled as AI-assisted drafts until reviewed by native speakers).
- **A spoken AI tutor that teaches**, not just chats: models a sentence, asks the learner to repeat it, checks every word on the phone instantly, corrects mistakes with an explanation in Amharic or Oromo, then moves on to using the expression in a roleplay.
- **Real-time feel on ordinary networks:** the Professor starts speaking as soon as the first line of his answer arrives; his Amharic/Oromo voice is prepared in parallel; the learner can cut in; a dropped connection is retried automatically.
- **Offline-first:** the whole learning journey except the live tutor works with no data.

## Technical implementation

- **App:** Flutter (Android first). Features depend only on interfaces (content, vocabulary, tutor, speech, voice, audio); all progress flows through one service. Network code lives in one file, enforced by a test.
- **AI relay:** a small Node service (no dependencies) that keeps the Addis AI key off the phone. It builds the teaching prompt from the scene, target expressions and conversation, streams Addis AI's answer, and synthesises (Addis voices Yohanes and Leta) and transcribes Amharic and Afaan Oromo speech.
- **Speech:** English is recognised and spoken by the phone; native-language questions and coaching use Addis AI.
- **Characters:** Spark and the Professor are original vector characters rigged in Rive, reacting to real app events. The Professor's mouth follows the measured loudness of his voice (not phoneme lip-sync).
- **Ethiopic script:** glyph-coverage tests make sure every Amharic and Oromo string renders.

## Offline and online

| Works with no internet | Needs internet |
|---|---|
| Onboarding, lessons, learning path, XP, streaks, quests, badges, Word Garden | The Professor (live AI tutor), his Amharic/Oromo voice and spoken-question transcription |
| Watch & learn scene with subtitles and expression cards | |
| My Words and spaced review | |

Without a connection the Professor's screen says so plainly and offers offline practice; it never fakes an AI reply.

## Demonstration flow

1. Choose Amharic (or Afaan Oromo) and a level.
2. Home: streak, XP, today's quests, and Spark.
3. A short lesson: answer, get instant feedback, earn XP.
4. Watch & learn: play the bus-stop scene with Amharic subtitles; tap "Long time no see" to see its meaning in context; save it to My Words.
5. Speak with the Professor: he greets you and models the phrase; you repeat it aloud; instant feedback; he coaches you in Amharic; you answer in the roleplay and get corrected.
6. Airplane mode: lessons, the scene and My Words still work.

## Evidence

- **Tests:** 144 Flutter tests pass (5 skipped: live-AI and screenshot suites, run on demand) and 17 relay tests pass (see `TEST_RESULTS.md`).
- **Android:** the release APK installs and launches on a TECNO KJ7 (Android 14). The relay log recorded live Professor turns from that phone with the first spoken line ready in 1.6–2.0 s.
- **Screenshots:** `screenshots/`.
- **Recordings:** `recordings/` (web runtime captures of the Rive characters and a live Addis session).

## Limitations

- The relay runs on a laptop over plain HTTP on the local network; production needs a hosted relay with HTTPS.
- AI response time depends on the network: about 1.5–2.8 s to the first spoken line on a good connection, 5–10 s on a slow one.
- Demo content: one video scene and one course unit.
- Tutor conversations are not saved between app restarts.
- The Professor's English voice is the phone's text-to-speech and varies by device.
- Rive character files are on Rive's free plan (watermarked).
- Amharic and Afaan Oromo text is AI-assisted and awaits native-speaker review.

## Future development

More scenes and units through the documented content pipeline; native-speaker review of all translations; a hosted HTTPS relay; saved tutor history; more Ethiopian languages (for example Tigrinya); music and short stories as new content types.

## Setup

See `README.md` (sections "Run" and "Limitations"). The Addis AI key goes only in `server/.env` on the relay machine and is never in the app or this package.
