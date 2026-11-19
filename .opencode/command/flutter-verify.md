---
description: Verify Cognitive Gym changes with format, analysis, targeted tests, and responsive overflow checks.
agent: build
---

# Flutter Verify

Run the Cognitive Gym verification loop for: $ARGUMENTS

## Steps

1. Identify the Dart files changed for this task. Never format or rewrite
   unrelated files.
2. Format the changed files:
   `dart format <changed files>`
3. Analyze the changed files and their directly affected tests:
   `flutter analyze <changed lib files> <changed test files>`
   If the full `flutter analyze` run reports pre-existing issues outside this
   change, report them separately instead of masking or expanding the change.
4. Run targeted tests:
   - UI or layout changes: `flutter test test/games_screen_layout_test.dart`
   - Game logic changes: run the matching `test/<game>_test.dart`
   - Service or persistence changes: run the matching service test
5. For UI or layout changes, confirm all game cards render without `RenderFlex`
   overflow at 1440x900, 1280x720, 1024x768, 768x1024, and 390x844, in both
   light and dark themes.
6. If the full suite can compile and run, execute `flutter test` and report the
   remaining failures separately from this change.

## Output

Report:

- files changed
- commands run and their results
- remaining failures and whether they are pre-existing or caused by this change
- any layout viewports that were verified
