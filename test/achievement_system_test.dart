import 'package:cognitive_gym/routes/app_router.dart';
import 'package:flutter/services.dart';
import 'package:cognitive_gym/screens/account_screen.dart';
import 'package:cognitive_gym/screens/achievements_screen.dart';
import 'package:cognitive_gym/services/achievement_service.dart';
import 'package:cognitive_gym/services/auth_service.dart';
import 'package:cognitive_gym/services/database_service.dart';
import 'package:cognitive_gym/services/exercise_scoring_service.dart';
import 'package:cognitive_gym/services/progress_service.dart';
import 'package:cognitive_gym/services/reward_manager.dart';
import 'package:cognitive_gym/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await DatabaseService.resetForTesting(dbPath: inMemoryDatabasePath);
  });

  tearDownAll(() async {
    await DatabaseService.resetForTesting();
  });

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => null,
    );
    SharedPreferences.setMockInitialValues({});
    await DatabaseService.instance.close();
    await AuthService.instance.initialize();
    await ProgressService.instance.init();
    await ProgressService.instance.resetProgress();
    AchievementService.instance.resetForTesting();
    await AchievementService.instance.init();
    await RewardManager.instance.init();
  });

  group('PART 3: Achievement Tracking, Evaluation & Persistence Tests', () {
    test('Initial state: zero achievements unlocked and progress accurate', () async {
      final unlocked = await AchievementService.instance.getUnlockedAchievementIds();
      expect(unlocked, isEmpty);
      expect(AchievementService.instance.isUnlocked('first_lesson'), isFalse);
      expect(AchievementService.instance.isUnlocked('first_perfect_lesson'), isFalse);

      final progress = AchievementService.instance.getProgress('first_lesson');
      expect(progress, equals(0));
    });

    test('Test 1: Completing first lesson unlocks first_lesson achievement', () async {
      expect(AchievementService.instance.isUnlocked('first_lesson'), isFalse);

      // Record a lesson completion via RewardManager
      final pts = await RewardManager.instance.awardLesson(
        lessonId: 'test_lesson_1',
      );

      expect(pts, greaterThan(0));
      expect(ProgressService.instance.userProfile.totalLessonsCompleted, equals(1));

      // Achievement should now be unlocked automatically
      expect(AchievementService.instance.isUnlocked('first_lesson'), isTrue);
      expect(
        ProgressService.instance.userProfile.unlockedAchievements,
        contains('first_lesson'),
      );
      expect(AchievementService.instance.getProgress('first_lesson'), equals(1));
    });

    test('Test 2: Perfect score unlocks first_perfect_lesson achievement', () async {
      expect(AchievementService.instance.isUnlocked('first_perfect_lesson'), isFalse);

      // Record completion with 100% accuracy
      await ProgressService.instance.recordObservationChallengeCompletion(
        performanceScore: 100.0,
        accuracy: 100.0,
        durationSeconds: 30,
        difficulty: ObservationDifficulty.hard,
        idempotencyKey: 'test_obs_perfect',
      );

      expect(AchievementService.instance.isUnlocked('first_perfect_lesson'), isTrue);
      expect(
        ProgressService.instance.userProfile.unlockedAchievements,
        contains('first_perfect_lesson'),
      );
    });

    test('Test 3: Unlocking 5 distinct achievements unlocks high_five achievement', () async {
      expect(AchievementService.instance.isUnlocked('high_five'), isFalse);

      // Directly unlock 5 achievements
      await AchievementService.instance.unlockAchievement('first_lesson');
      await AchievementService.instance.unlockAchievement('speed_reader');
      await AchievementService.instance.unlockAchievement('vocab_starter');
      await AchievementService.instance.unlockAchievement('night_owl');
      await AchievementService.instance.unlockAchievement('daily_trio');

      final unlocked = await AchievementService.instance.getUnlockedAchievementIds();
      // Should contain the 5 manually unlocked plus 'high_five'
      expect(unlocked.length, greaterThanOrEqualTo(5));
      expect(AchievementService.instance.isUnlocked('high_five'), isTrue);
    });

    test('Test 4: Unlocking 10 achievements unlocks perfect_ten achievement', () async {
      expect(AchievementService.instance.isUnlocked('perfect_ten'), isFalse);

      final allIds = AchievementService.allAchievements.map((a) => a.id).toList();
      for (int i = 0; i < 9; i++) {
        await AchievementService.instance.unlockAchievement(allIds[i]);
      }
      expect(AchievementService.instance.isUnlocked('perfect_ten'), isFalse);

      // 10th achievement unlocked
      await AchievementService.instance.unlockAchievement(allIds[9]);
      expect(AchievementService.instance.isUnlocked('perfect_ten'), isTrue);
    });

    test('Test 5: Vocabulary achievements unlock at 10, 50, and 100 words learned', () async {
      expect(AchievementService.instance.isUnlocked('vocab_starter'), isFalse);
      expect(AchievementService.instance.isUnlocked('vocab_builder'), isFalse);
      expect(AchievementService.instance.isUnlocked('word_master'), isFalse);

      // Award 10 words
      await RewardManager.instance.awardWords(count: 10);
      expect(ProgressService.instance.userProfile.wordsLearnedCount, equals(10));
      expect(AchievementService.instance.isUnlocked('vocab_starter'), isTrue);
      expect(AchievementService.instance.isUnlocked('vocab_builder'), isFalse);

      // Award 40 more words -> total 50
      await RewardManager.instance.awardWords(count: 40);
      expect(ProgressService.instance.userProfile.wordsLearnedCount, equals(50));
      expect(AchievementService.instance.isUnlocked('vocab_builder'), isTrue);
      expect(AchievementService.instance.isUnlocked('word_master'), isFalse);

      // Award 50 more words -> total 100
      await RewardManager.instance.awardWords(count: 50);
      expect(ProgressService.instance.userProfile.wordsLearnedCount, equals(100));
      expect(AchievementService.instance.isUnlocked('word_master'), isTrue);
    });

    test('Test 6: Streaks of 3, 7, and 30 unlock respective streak achievements', () async {
      expect(AchievementService.instance.isUnlocked('streak_3'), isFalse);
      expect(AchievementService.instance.isUnlocked('streak_7'), isFalse);
      expect(AchievementService.instance.isUnlocked('streak_30'), isFalse);

      // Streak = 3
      ProgressService.instance.userProfile.currentStreak = 3;
      await AchievementService.instance.evaluateProgress(ProgressService.instance.userProfile);
      expect(AchievementService.instance.isUnlocked('streak_3'), isTrue);
      expect(AchievementService.instance.isUnlocked('streak_7'), isFalse);

      // Streak = 7
      ProgressService.instance.userProfile.currentStreak = 7;
      await AchievementService.instance.evaluateProgress(ProgressService.instance.userProfile);
      expect(AchievementService.instance.isUnlocked('streak_7'), isTrue);
      expect(AchievementService.instance.isUnlocked('streak_30'), isFalse);

      // Streak = 30
      ProgressService.instance.userProfile.currentStreak = 30;
      await AchievementService.instance.evaluateProgress(ProgressService.instance.userProfile);
      expect(AchievementService.instance.isUnlocked('streak_30'), isTrue);
    });

    test('Test 7: Completing a course unlocks course_complete achievement', () async {
      expect(AchievementService.instance.isUnlocked('course_complete'), isFalse);

      await RewardManager.instance.awardCourse(courseId: 'course_memory_101');
      expect(ProgressService.instance.userProfile.totalCoursesCompleted, equals(1));
      expect(AchievementService.instance.isUnlocked('course_complete'), isTrue);
    });

    test('Test 8: Unlocking an achievement awards its defined XP reward once (idempotent)', () async {
      final initialXp = ProgressService.instance.userProfile.totalXp;

      // Unlock 'first_lesson' (reward: 15 XP)
      final pts1 = await AchievementService.instance.unlockAchievement('first_lesson');
      expect(pts1, equals(15));
      expect(ProgressService.instance.userProfile.totalXp, equals(initialXp + 15));

      // Attempt to unlock again
      final pts2 = await AchievementService.instance.unlockAchievement('first_lesson');
      expect(pts2, equals(0));
      expect(ProgressService.instance.userProfile.totalXp, equals(initialXp + 15));
    });

    test('Test 9: Persistence in SQLite across service re-initialization', () async {
      await AchievementService.instance.unlockAchievement('first_lesson');
      await AchievementService.instance.unlockAchievement('vocab_starter');

      // Verify in DB directly
      final dbRecords = await DatabaseService.instance.getUnlockedAchievements();
      expect(dbRecords.length, equals(2));

      // Re-initialize AchievementService from SQLite
      AchievementService.instance.resetForTesting();
      expect(AchievementService.instance.unlockedAchievementsCount, equals(0));

      await AchievementService.instance.init();
      expect(AchievementService.instance.unlockedAchievementsCount, equals(2));
      expect(AchievementService.instance.isUnlocked('first_lesson'), isTrue);
      expect(AchievementService.instance.isUnlocked('vocab_starter'), isTrue);
    });
  });

  group('PART 1 & PART 2: AccountScreen & Dedicated AchievementsScreen Widget Tests', () {
    testWidgets('AccountScreen renders Achievement Showcase with progress bar and stats',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AccountScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Achievement Section Header
      expect(find.text('Achievements'), findsWidgets);
      expect(find.text('Explore Achievements'), findsOneWidget);

      // Verify Unlocked count pill and points are displayed
      expect(find.textContaining('Unlocked'), findsWidgets);
      expect(find.textContaining('pts'), findsWidgets);
    });

    testWidgets('AchievementsScreen renders clean status filters and authentic achievement cards',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Achievements'), findsOneWidget);

      // Simplified Filter tabs: only All, Unlocked, Locked
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Unlocked'), findsOneWidget);
      expect(find.text('Locked'), findsOneWidget);

      // Verify Milestone Journey section is removed
      expect(find.text('Milestone Journey'), findsNothing);
      expect(find.text('Every milestone tells a story.'), findsNothing);

      // Verify authentic achievements are rendered
      expect(find.text('First Step'), findsOneWidget);
      expect(find.text('Word Collector'), findsOneWidget);
      expect(find.text('Beginner Graduate'), findsOneWidget);
      expect(find.text('Hidden Achievement'), findsWidgets);
    });

    testWidgets('AchievementsScreen interactive filtering by status (All, Unlocked, Locked)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Unlock 1 achievement
      await AchievementService.instance.unlockAchievement('first_lesson');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AchievementsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Unlocked' filter tab
      await tester.tap(find.byKey(const Key('filter_tab_unlocked')));
      await tester.pumpAndSettle();

      // 'First Step' must be visible
      expect(find.text('First Step'), findsOneWidget);

      // Tap 'Locked' filter tab
      await tester.tap(find.byKey(const Key('filter_tab_locked')));
      await tester.pumpAndSettle();

      // 'First Step' must NOT be visible under locked filter
      expect(find.text('First Step'), findsNothing);

      // Tap 'All' filter tab
      await tester.tap(find.byKey(const Key('filter_tab_all')));
      await tester.pumpAndSettle();

      // 'First Step' must be visible again under All
      expect(find.text('First Step'), findsOneWidget);
      expect(find.text('Word Collector'), findsOneWidget);
    });

    testWidgets('Navigation: Tapping Explore Achievements on AccountScreen opens AchievementsScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Navigate to Account tab in bottom nav
      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Account'),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Tap 'Explore Achievements'
      await tester.tap(find.text('Explore Achievements'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Verify AchievementsScreen is displayed
      expect(find.byType(AchievementsScreen), findsOneWidget);
    });
  });
}
