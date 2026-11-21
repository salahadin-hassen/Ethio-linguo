# ADR 0005: Learning-content translation is separate from UI localisation

- **Status:** Accepted (2026-11-21)
- **Context:** The UI language and the content-translation language are different concerns. Flutter's Material localisations do not support Afaan Oromo (`om`).
- **Decision:**
  - **Content translation** is data: `translations/<code>.json`, with a per-language review status in the manifest.
  - **UI localisation** works like this. The interface is English, the language being learned. Key labels carry a short support line in the learner's language, served from `core/l10n/app_strings.dart` and keyed by `S`. A missing entry falls back to English with no support line.
  - `LanguageInfo` carries the script, text direction and capabilities, so right-to-left languages can be added.
  - Dates are relative ("Today", "3 days ago") and calendar-neutral. Ethiopian-calendar display is future work.
- **Consequences:**
  - Each concern can be reviewed and shipped independently.
  - Milestone-1 widgets that predate this layer still embed some Amharic and Oromo. The architecture test lists those files, so new debt fails the build.
