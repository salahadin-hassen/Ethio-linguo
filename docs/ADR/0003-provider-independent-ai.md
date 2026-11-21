# ADR 0003: Provider-independent AI interfaces

- **Status:** Accepted (2026-11-21)
- **Context:** The voice tutor is the differentiator, but providers, prices and credentials change. API keys must never ship in a mobile binary.
- **Decision:**
  - Split the work into three device-side contracts: `SpeechRecognizer`, `SpeechSynthesizer` and `TutorEngine` (plus `ExplanationProvider`). `TutorSessionController` orchestrates them and depends only on those interfaces.
  - The MVP implementations are on-device OS speech services and `RelayTutorEngine`, which calls our relay. The relay wraps one provider (Anthropic) behind an adapter.
  - The tutor always receives a **structured** `TutorContext`: learner language, level, scene, transcript, focus and target expressions. It is not used as a generic chatbot.
- **Consequences:**
  - Swapping providers means changing one adapter on the relay, or adding a new `TutorEngine`.
  - `UnavailableTutorEngine` is the honest default whenever no relay is configured.
