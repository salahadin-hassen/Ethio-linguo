# Future Roadmap (post-hackathon)

The architecture already has a seam for each item. Most of them are *content plus an adapter*, not rewrites.

| Theme | What | Seam that already exists |
|---|---|---|
| **Music learning** | Licensed songs with time-synced lyrics, a line-by-line meaning layer and sing-along pronunciation | `MediaItem` + `SubtitleSegment` already model timed lines. Add `kind: "song"` and an audio-only player. Lyrics need publisher licences: **no unlicensed lyrics** |
| **Book learning** | Graded readers and articles with tap-to-explain | `Expression` + `Translations` reused. Add a `TextItem` with paragraphs instead of segments |
| **More Ethiopian languages** | Tigrinya, Somali, Sidaama, Wolaytta… | `Translations` is keyed by language code. Add a `NativeLanguage` entry, content and native-speaker review. Fonts already cover Ethiopic |
| **More AI characters** | The full cast (Explorer, Sound Coach, Trickster) with distinct roles | `character` field in the relay request. Personas live server-side as data |
| **Personalised learning** | Spaced repetition over My Words + Word Garden; difficulty from tutor feedback | `reviewCount`, `WordProgress.strength` and `TutorFeedback.kind` are already recorded |
| **Content creator partnerships** | Ethiopian creators publish rights-cleared clips with revenue share | Versioned manifests + `MediaLicense`. Add downloadable content packs (`OFFLINE_STRATEGY.md`) |
| Downloadable packs and sync | Content packs, accounts, cross-device progress | `MediaRepository` / `ProgressStore` / `VocabularyRepository` interfaces |
| Real pronunciation scoring | Phoneme-level feedback | Add `kind: "pronunciation"` with a scoring service behind the relay |
| Classroom mode | Teacher dashboards for youth programmes | Separate web app over the synced data |
