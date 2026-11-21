# Ethio Linguo (working title)

An Ethiopian-first, offline-first language-learning app. Speakers of Amharic or Afaan Oromo learn English through their own language.

> The product name is **not final**. It lives in one constant: `lib/app/app_config.dart`.

## Milestone 1: frontend foundation

- Welcome / onboarding → language selection → home dashboard → learning path → interactive lesson → lesson completion
- Word Garden, badges and progress, daily quests, streak, XP and levels, hearts
- Original mascot ("Gela", placeholder name) with 8 expressions, drawn in vector
- 100% offline: course content is bundled, validation is local, progress is stored on the device

See `docs/design/DESIGN_SYSTEM.md`, `docs/design/MASCOT.md` and `docs/screenshots/`.

## Run

```bash
flutter pub get
flutter run                 # Android device/emulator, or -d linux / -d chrome
```

## Quality checks

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test                                   # unit + widget + offline + Ethiopic tests
flutter test test/screenshots --run-skipped --update-goldens   # regenerate screenshots
flutter build apk --release
```

## Structure

```
lib/
  app/            app widget, routes wiring, AppController (state + rules), AppScope, config
  core/           theme tokens, motion, navigation, reusable components
  data/
    models/       language, course, exercise, progress, gamification
    local/        bundled demo course, instructions, ProgressStore (SharedPreferences)
  features/
    onboarding/ language_selection/ home/ learning_path/
    lessons/      screen, exercise views, logic (builder, validator, session)
    word_garden/ achievements/ mascot/
test/
  unit/ widget/ screenshots/ helpers/
```

State management uses a single `ChangeNotifier` (`AppController`) exposed through an `InheritedNotifier`. There is no state-management package. Persistence sits behind the `ProgressStore` interface so SQLite/Drift can replace SharedPreferences later.
