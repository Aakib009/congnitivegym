import 'package:cognitive_gym/screens/observation_challenge_screen.dart';
import 'package:cognitive_gym/services/database_service.dart';
import 'package:cognitive_gym/services/observation_challenge_service.dart';
import 'package:cognitive_gym/services/progress_service.dart';
import 'package:cognitive_gym/utils/app_theme.dart';
import 'package:cognitive_gym/widgets/observation_scene_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    DatabaseService.initializeFactory();
    await DatabaseService.resetForTesting(dbPath: inMemoryDatabasePath);
  });

  tearDownAll(() async {
    await DatabaseService.resetForTesting();
  });

  group('ObservationChallengeService Unit Tests', () {
    test('getAllChallenges returns 9 predefined challenges', () {
      final challenges = ObservationChallengeService.getAllChallenges();
      expect(challenges.length, equals(9));
    });

    test('Each challenge contains valid questions, correct options, and imagePath', () {
      final challenges = ObservationChallengeService.getAllChallenges();
      for (final challenge in challenges) {
        expect(challenge.title, isNotEmpty);
        expect(challenge.sceneType, isNotEmpty);
        expect(challenge.imagePath, isNotEmpty);
        expect(challenge.imagePath, startsWith('assets/images/observation/'));
        expect(challenge.questions.length, equals(5));

        for (final q in challenge.questions) {
          expect(q.questionText, isNotEmpty);
          expect(q.options.length, equals(4));
          expect(q.correctOptionIndex, greaterThanOrEqualTo(0));
          expect(q.correctOptionIndex, lessThan(4));
          expect(q.correctAnswer, isNotEmpty);
        }
      }
    });

    test('getRandomChallenge returns a valid ObservationChallenge', () {
      final random = ObservationChallengeService.getRandomChallenge();
      expect(random.id, isNotEmpty);
      expect(random.imagePath, isNotEmpty);
      expect(random.questions, isNotEmpty);
    });
  });

  group('ObservationSceneWidget Tests', () {
    testWidgets('Renders ObservationSceneWidget for cafe scenario',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ObservationSceneWidget(
              sceneType: 'cafe',
              imagePath: 'assets/images/observation/CafeProject.jpeg',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ObservationSceneWidget), findsOneWidget);
    });
  });

  group('ObservationChallengeScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });
    testWidgets('Renders intro stage with title, rules, and start button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ObservationChallengeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Challenge rules'), findsOneWidget);
      expect(find.text('Start observation'), findsOneWidget);
    });

    testWidgets('Tapping Start Observation opens single difficulty dialog and selecting option starts challenge',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ObservationChallengeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Start Observation
      final startBtn = find.text('Start observation');
      await tester.ensureVisible(startBtn);
      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      // Verify single popup dialog appears with difficulty options
      expect(find.text('Select difficulty'), findsOneWidget);
      expect(find.text('Easy'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.text('Hard'), findsOneWidget);

      // Tap Medium option in difficulty dialog
      final mediumOption = find.text('Medium');
      await tester.tap(mediumOption);
      await tester.pumpAndSettle();

      // Verify immediate transition to memorize stage
      expect(find.text('Observe carefully'), findsOneWidget);
      expect(find.byType(ObservationSceneWidget), findsOneWidget);
    });

    testWidgets('Double-tap submit challenge on final question prevents duplicate XP awards',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await ProgressService.instance.resetProgress();
      final initialExercises =
          ProgressService.instance.userProfile.totalExercisesCompleted;
      final initialXp = ProgressService.instance.userProfile.totalXp;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ObservationChallengeScreen(initialDifficulty: 2), // Hard (8s)
        ),
      );
      await tester.pumpAndSettle();

      // Start challenge
      await tester.tap(find.text('Start observation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hard'));
      await tester.pumpAndSettle();

      // Advance through the 8-second countdown timer to enter quiz stage
      for (int i = 0; i < 9; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await tester.pumpAndSettle();

      expect(find.text('Question 1 of 5'), findsOneWidget);

      // Answer questions 1 through 4
      for (int q = 1; q <= 4; q++) {
        expect(find.text('Question $q of 5'), findsOneWidget);
        await tester.tap(find.text('A').first);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Next question'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Next question'));
        await tester.pumpAndSettle();
      }

      // Question 5 (final question)
      expect(find.text('Question 5 of 5'), findsOneWidget);
      await tester.tap(find.text('A').first);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Submit challenge'));
      await tester.pumpAndSettle();

      // Rapidly double tap
      await tester.tap(find.text('Submit challenge'));
      await tester.tap(find.text('Submit challenge'));
      await tester.pumpAndSettle();

      expect(find.text('Observation complete'), findsOneWidget);

      final finalExercises =
          ProgressService.instance.userProfile.totalExercisesCompleted;
      final finalXp = ProgressService.instance.userProfile.totalXp;

      // Exactly 1 completion recorded, not 2
      expect(finalExercises - initialExercises, equals(1));
      expect(finalXp, greaterThan(initialXp));
    });
  });
}
