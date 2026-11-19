import 'dart:math';

import 'package:cognitive_gym/models/sequence_master.dart';
import 'package:cognitive_gym/screens/sequence_master_screen.dart';
import 'package:cognitive_gym/services/database_service.dart';
import 'package:cognitive_gym/services/progress_service.dart';
import 'package:cognitive_gym/services/sequence_master_service.dart';
import 'package:cognitive_gym/services/theme_service.dart';
import 'package:cognitive_gym/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    DatabaseService.initializeFactory();
    await DatabaseService.resetForTesting(dbPath: inMemoryDatabasePath);
  });

  tearDownAll(() async {
    await DatabaseService.resetForTesting();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DatabaseService.instance.clearAllAnalyticsEvents();
    await ProgressService.instance.init();
    await ProgressService.instance.resetProgress();
  });

  const viewports = <Size>[
    Size(1440, 900),
    Size(1280, 720),
    Size(1024, 768),
    Size(768, 1024),
    Size(390, 844),
  ];

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(800, 1200),
    AppThemeMode mode = AppThemeMode.light,
    SequenceMasterDifficulty difficulty = SequenceMasterDifficulty.easy,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getThemeData(mode),
        home: SequenceMasterScreen(
          initialDifficulty: difficulty,
          randomSeed: 42,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> startSession(WidgetTester tester) async {
    final start = find.byKey(const ValueKey('sequence-start-button'));
    await tester.ensureVisible(start);
    await tester.pump();
    await tester.tap(start);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> chooseOption(WidgetTester tester, int index) async {
    final option = find.byKey(ValueKey('sequence-option-$index'));
    await tester.ensureVisible(option);
    await tester.pump();
    await tester.tap(option);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> tapNext(WidgetTester tester) async {
    final next = find.byKey(const ValueKey('sequence-next-button'));
    await tester.ensureVisible(next);
    await tester.pump();
    await tester.tap(next);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var attempt = 0; attempt < 200; attempt++) {
      if (finder.evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 25));
    }
    fail('Timed out waiting for $finder');
  }

  Future<void> completeRun(
    WidgetTester tester,
    List<SequenceMasterQuestion> questions,
  ) async {
    for (var index = 0; index < questions.length; index++) {
      expect(
        find.text('Sequence ${index + 1} of ${questions.length}'),
        findsOneWidget,
      );
      await chooseOption(tester, questions[index].correctOptionIndex);
      expect(find.byKey(const ValueKey('sequence-feedback')), findsOneWidget);
      expect(find.text('Correct'), findsOneWidget);
      await tapNext(tester);
    }
    await waitFor(tester, find.text('Sequence complete'));
  }

  Future<void> disposeScreen(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  }

  Future<void> drainBackgroundWork(WidgetTester tester) async {
    for (var cycle = 0; cycle < 5; cycle++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
    }
  }

  List<String> visibleSequence(WidgetTester tester) {
    final tokens = <String>[];
    for (var index = 0; ; index++) {
      final token = find.byKey(ValueKey('sequence-token-$index'));
      if (token.evaluate().isEmpty) break;
      final text = find.descendant(of: token, matching: find.byType(Text));
      tokens.add(tester.widget<Text>(text.first).data!);
    }
    return tokens;
  }

  group('Sequence Master screen', () {
    testWidgets('intro selects a difficulty and starts a four-option run', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('How it works'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('sequence-difficulty-easy')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('sequence-difficulty-medium')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('sequence-difficulty-hard')),
        findsOneWidget,
      );

      final hard = find.byKey(const ValueKey('sequence-difficulty-hard'));
      await tester.ensureVisible(hard);
      await tester.pump();
      await tester.tap(hard);
      await tester.pumpAndSettle();
      await startSession(tester);

      expect(find.text('Sequence 1 of 12'), findsOneWidget);
      for (var index = 0; index < 4; index++) {
        expect(find.byKey(ValueKey('sequence-option-$index')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('sequence-timer')), findsOneWidget);
      expect(
        find.text(
          'Two values are hidden. Choose the pair that completes the pattern.',
        ),
        findsOneWidget,
      );

      await disposeScreen(tester);
    });

    testWidgets('wrong and correct answers show immediate feedback', (
      tester,
    ) async {
      await pumpScreen(tester);
      await startSession(tester);

      final questions = SequenceMasterService.generateQuestions(
        difficulty: SequenceMasterDifficulty.easy,
        random: Random(42),
      );
      final first = questions.first;
      final wrongIndex = (first.correctOptionIndex + 1) % 4;

      await chooseOption(tester, wrongIndex);
      expect(find.text('Not quite'), findsOneWidget);
      expect(
        find.text('You chose ${first.options[wrongIndex]}.'),
        findsOneWidget,
      );
      expect(
        find.text('Correct answer: ${first.correctAnswer}'),
        findsOneWidget,
      );

      await tapNext(tester);
      await chooseOption(tester, questions[1].correctOptionIndex);
      expect(find.text('Correct'), findsOneWidget);
      expect(
        find.text('Correct answer: ${questions[1].correctAnswer}'),
        findsOneWidget,
      );

      await disposeScreen(tester);
    });

    testWidgets('hard question timer marks the run timed out', (tester) async {
      await pumpScreen(tester, difficulty: SequenceMasterDifficulty.hard);
      await startSession(tester);

      for (var second = 0; second < 20; second++) {
        await tester.pump(const Duration(seconds: 1));
      }

      expect(find.text("Time's up"), findsOneWidget);
      await tapNext(tester);
      expect(find.text('Sequence 2 of 12'), findsOneWidget);

      await disposeScreen(tester);
    });

    testWidgets(
      'perfect easy run rewards once and supports replay and difficulty change',
      (tester) async {
        await pumpScreen(tester, size: const Size(390, 844));
        final initialXp = ProgressService.instance.userProfile.totalXp;
        final initialExercises =
            ProgressService.instance.userProfile.totalExercisesCompleted;

        final random = Random(42);
        final firstRun = SequenceMasterService.generateQuestions(
          difficulty: SequenceMasterDifficulty.easy,
          random: random,
        );
        final secondRun = SequenceMasterService.generateQuestions(
          difficulty: SequenceMasterDifficulty.easy,
          random: random,
          excludeIds: firstRun.map((question) => question.id).toSet(),
        );

        await startSession(tester);
        await completeRun(tester, firstRun);

        expect(find.text('8 / 8'), findsOneWidget);
        expect(find.text('100% accuracy • Easy difficulty'), findsOneWidget);
        expect(find.text('Performance 80/100'), findsOneWidget);
        expect(find.text('+20 XP'), findsOneWidget);
        expect(find.text('+14 logic points'), findsOneWidget);
        for (var index = 0; index < 8; index++) {
          expect(
            find.byKey(ValueKey('sequence-review-$index')),
            findsOneWidget,
          );
        }

        expect(ProgressService.instance.userProfile.totalXp, initialXp + 20);
        expect(
          ProgressService.instance.userProfile.totalExercisesCompleted,
          initialExercises + 1,
        );
        await drainBackgroundWork(tester);

        final replay = find.byKey(const ValueKey('sequence-replay-button'));
        await tester.ensureVisible(replay);
        await tester.pump();
        await tester.tap(replay);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Sequence 1 of 8'), findsOneWidget);
        expect(visibleSequence(tester), equals(secondRun.first.sequence));

        await completeRun(tester, secondRun);
        expect(ProgressService.instance.userProfile.totalXp, initialXp + 40);
        expect(
          ProgressService.instance.userProfile.totalExercisesCompleted,
          initialExercises + 2,
        );

        final change = find.byKey(
          const ValueKey('sequence-change-difficulty-button'),
        );
        await tester.ensureVisible(change);
        await tester.pump();
        await tester.tap(change);
        await tester.pumpAndSettle();

        expect(find.text('Choose your difficulty'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('sequence-start-button')),
          findsOneWidget,
        );
        await drainBackgroundWork(tester);
      },
    );

    testWidgets('back to games returns through the app router', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => context.push('/sequence-master'),
                  child: const Text('Open sequence master'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/sequence-master',
            builder: (context, state) => const SequenceMasterScreen(
              initialDifficulty: SequenceMasterDifficulty.easy,
              randomSeed: 42,
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router, theme: AppTheme.lightTheme),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open sequence master'));
      await tester.pumpAndSettle();

      final questions = SequenceMasterService.generateQuestions(
        difficulty: SequenceMasterDifficulty.easy,
        random: Random(42),
      );
      await startSession(tester);
      await completeRun(tester, questions);

      final games = find.byKey(const ValueKey('sequence-games-button'));
      await tester.ensureVisible(games);
      await tester.pump();
      await tester.tap(games);
      await tester.pumpAndSettle();

      expect(find.text('Open sequence master'), findsOneWidget);
      expect(find.text('Sequence complete'), findsNothing);
      await drainBackgroundWork(tester);
    });

    for (final size in viewports) {
      for (final mode in [AppThemeMode.light, AppThemeMode.dark]) {
        testWidgets(
          'lays out without overflow at '
          '${size.width.toInt()}x${size.height.toInt()} in ${mode.name} theme',
          (tester) async {
            await pumpScreen(tester, size: size, mode: mode);
            expect(tester.takeException(), isNull);

            await startSession(tester);
            expect(tester.takeException(), isNull);
            expect(find.text('Sequence 1 of 8'), findsOneWidget);
            for (var index = 0; index < 4; index++) {
              expect(
                find.byKey(ValueKey('sequence-option-$index')),
                findsOneWidget,
              );
            }

            await disposeScreen(tester);
          },
        );
      }
    }
  });
}
