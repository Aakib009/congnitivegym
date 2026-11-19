# Cognitive Gym

Flutter application for four cognitive-training games: Observation Challenge,
Scenario Lab, Story Builder, and Debate Arena. The app also includes a journal,
analytics, rank progression, achievements, and a local account system.

## Stack

- Flutter/Dart (SDK `^3.12.0`), Material 3, `go_router`, Google Fonts.
- State: singleton services extending `ChangeNotifier`, consumed with
  `ListenableBuilder`.
- Persistence: SQLite through `sqflite_common_ffi` (tests and desktop) and
  `shared_preferences` for lightweight preferences.
- Auth: PBKDF2-HMAC-SHA256 with per-user salts and constant-time comparison.

## Commands

- `flutter pub get` - install dependencies.
- `flutter analyze` - full analysis. If unrelated pre-existing issues appear,
  verify changed files directly with `flutter analyze <file> [<file>...]`.
- `flutter test` - full suite.
- `flutter test test/<name>_test.dart` - targeted suite.
- `flutter run -d windows` or `flutter run -d chrome` - run the app.
- `dart format <file> [<file>...]` - format changed Dart files.

## Project layout

- `lib/screens/` - feature screens and game flows.
- `lib/widgets/` - shared UI, including `GymCard`.
- `lib/services/` - scoring, persistence, auth, audio, and progression logic.
- `lib/routes/app_router.dart` - route names and `go_router` configuration.
- `lib/utils/app_colors.dart` and `lib/utils/app_theme.dart` - design tokens and themes.
- `design.md` - visual design specification; `.planning/` - project state and roadmap.
- `assets/images/` - game and brand imagery.

## UI conventions

- Use `AppColors` and the active theme rather than introducing new hardcoded colors.
- Preserve the typography stack: Barlow Condensed, Plus Jakarta Sans, Space Grotesk, and Rajdhani.
- The games screen uses two columns at width >= 720 and one column below it.
- Paired cards share height per row; cards must grow with content instead of relying on fixed heights or clipping.
- Keep labels and footers flexible and ellipsized so narrow widths never overflow.
- Verify layouts at 1440x900, 1280x720, 1024x768, 768x1024, and 390x844 in light and dark themes.

## Testing conventions

- Set `GoogleFonts.config.allowRuntimeFetching = false` in widget tests.
- For tests touching persistence, initialize `sqflite_common_ffi` and use
  `DatabaseService.resetForTesting(dbPath: inMemoryDatabasePath)`.
- Keep layout regressions covered by `test/games_screen_layout_test.dart`.
- Exercise completion and XP rewards must stay idempotent; do not weaken the
  duplicate-submission guards in `ProgressService`.

## ECC integration

- ECC is installed globally in `~/.config/opencode` and provides the
  `/flutter-build`, `/flutter-test`, `/flutter-review`, `/verify`, and
  `/quality-gate` commands plus the `dart-flutter-patterns` and
  `flutter-dart-code-review` skills.
- Use `/flutter-verify` for this project's format, analysis, and responsive-test loop.
- Prefer targeted changes with targeted verification over whole-suite rewrites.
- OpenCode reads this file automatically. After editing OpenCode config or
  project instruction files, restart OpenCode so the new configuration loads.
