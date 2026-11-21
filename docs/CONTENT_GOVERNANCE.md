# Content Governance

The rules for every piece of learning content: video, song, book, article, audio story or podcast.

## Required metadata (`manifest.json` → `rights`, `translations`)

| Field | Meaning |
|---|---|
| `rights.creator` | Who made the work |
| `rights.rightsHolder` | Who can grant permission |
| `rights.source` | Where it came from (URL, or our generator script) |
| `rights.licenseType` | `original`, or an SPDX id (`CC-BY-4.0`, …) |
| `rights.attribution` | The exact credit line to display |
| `rights.offlineUseAllowed` | We may bundle or cache it on devices. **Required for bundled content.** Enforced in code |
| `rights.derivativeTranslationsAllowed` | We may publish our translations and subtitles of it |
| `rights.components[]` | Third-party parts with their own terms, such as voice models or music |
| `translations.<code>.status` | `draft` or `reviewed` |
| `translations.<code>.translator / reviewer / reviewedAt` | Provenance |
| `contentVersion`, `schemaVersion` | For updates and migrations |

## Current content

| id | Type | Licence | Offline | Translations |
|---|---|---|---|---|
| `bus_stop_hello` | video, 15.7 s | Original. The team wrote the script and generated the animation (`tool/content/make_bus_stop_clip.py`). The voices come from Piper with the LibriTTS-R voice (CC BY 4.0, attributed) | yes | am: **draft**, om: **draft** |

The Amharic and Afaan Oromo subtitles and explanations were written by the team. They have **not yet been reviewed by a native speaker**, and the app shows a "Draft translation" chip on them. Before any public release, a native speaker must review each language and set `status: "reviewed"` with their name. The test suite checks that `reviewed` always has a reviewer.

## Rules

1. Use only original, public-domain or explicitly licensed content. Do not use clips from films or series, or song lyrics, without a written licence.
2. Never assume a provider's terms allow downloading, caching, clipping or translating. Record each permission explicitly.
3. Unreviewed machine or AI translations must never be presented as authoritative teaching content.
4. Every content change bumps `contentVersion`.
5. UI strings (`app_strings.dart`) follow the same review rule. They are currently drafts too.

## Native-speaker review checklist

- [ ] Each segment's translation is natural, and its register fits the scene (informal, between friends).
- [ ] The gender agreement is correct. For example, Dawit addresses Liya, and the Amharic uses the feminine form ከረምሽ.
- [ ] The meaning and explanation of each expression are accurate and easy for a beginner to follow.
- [ ] The example sentences are natural.
- [ ] The time expressions use the local convention where the text shows it, such as ሰባት ሰዓት for 1 pm.
- [ ] Record the reviewer's name and date in the manifest.
