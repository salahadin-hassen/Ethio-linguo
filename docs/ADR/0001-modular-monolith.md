# ADR 0001: Modular monolith over microservices

- **Status:** Accepted (2026-11-21)
- **Context:** Six-hour hackathon, four people, offline-first mobile product. The only thing that has to run server-side is AI credential handling.
- **Decision:** One Flutter app with feature folders, separating presentation, application controllers, domain models and repositories. The only backend is a stateless relay of about 150 lines (`server/`). There is no message bus, no service mesh and no database server.
- **Consequences:**
  - Fast to build and easy to demo, and the layering is still testable.
  - Boundaries are enforced by `architecture_test.dart` rather than by deployment units.
  - Features can be split out later along the repository interfaces if a team needs that.
