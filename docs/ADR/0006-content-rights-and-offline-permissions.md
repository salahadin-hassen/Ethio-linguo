# ADR 0006: Content rights and offline permissions are data

- **Status:** Accepted (2026-11-21)
- **Context:** Movies, music and books come with restrictive terms. Offline caching and derivative translations both need explicit permission.
- **Decision:**
  - Every manifest carries `rights`: creator, rights holder, licence type, attribution, source, and the flags `offlineUseAllowed` and `derivativeTranslationsAllowed`. It also lists third-party `components` (for example a speech model).
  - `BundledContentRepository` refuses to list bundled content that does not allow offline use. This is tested.
  - Translation provenance (draft or reviewed, with the reviewer) is stored per language and shown to learners.
- **Consequences:**
  - Governance is enforceable in code and in review.
  - The hackathon uses only original content: the team wrote the script and generated the animation, and the synthetic voices come from a CC BY 4.0 training set, which is attributed.
