import 'package:cognitive_gym/services/analytics_repository.dart';
import 'package:cognitive_gym/services/database_service.dart';
import 'package:cognitive_gym/services/exercise_scoring_service.dart';
import 'package:cognitive_gym/services/progress_service.dart';
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

  group('ProgressService Unit Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await DatabaseService.instance.clearAllAnalyticsEvents();
      await ProgressService.instance.init();
      await ProgressService.instance.resetProgress();
    });

    test('Initial user profile contains zero points and default values', () {
      final profile = ProgressService.instance.userProfile;
      expect(profile.creativityPoints, equals(0));
      expect(profile.observationPoints, equals(0));
      expect(profile.logicPoints, equals(0));
      expect(profile.decisionMakingPoints, equals(0));
      expect(profile.knowledgePoints, equals(0));
      expect(profile.totalXp, equals(0));
      expect(profile.totalExercisesCompleted, equals(0));
    });

    test('Story Builder completion (excellent) awards full Creativity gain + excellence XP',
        () async {
      final xp = await ProgressService.instance.recordStoryBuilderCompletion(
        performanceScore: 100,
        accuracy: 100,
        durationSeconds: 120,
      );
      final profile = ProgressService.instance.userProfile;

      expect(xp, equals(20)); // 15 participation + 5 excellence bonus
      expect(profile.creativityPoints, equals(15)); // 15 * 1.0 tier
      expect(profile.totalXp, equals(20));
      expect(profile.totalExercisesCompleted, equals(1));
      expect(profile.observationPoints, equals(0));
      expect(profile.logicPoints, equals(0));
      expect(profile.decisionMakingPoints, equals(0));
    });

    test('Story Builder completion (poor) awards minimal Creativity gain and no bonus XP',
        () async {
      final xp = await ProgressService.instance.recordStoryBuilderCompletion(
        performanceScore: 40,
        accuracy: 100,
        durationSeconds: 60,
      );
      final profile = ProgressService.instance.userProfile;

      expect(xp, equals(15)); // Participation XP only (no excellence bonus)
      expect(profile.creativityPoints, equals(3)); // 15 * 0.2 minimal tier
      expect(profile.totalXp, equals(15));
    });

    test('Observation Challenge completion (perfect, hard) awards full Observation gain and hard-difficulty XP',
        () async {
      final xp = await ProgressService.instance
          .recordObservationChallengeCompletion(
        performanceScore: 100,
        accuracy: 100,
        durationSeconds: 75,
        difficulty: ObservationDifficulty.hard,
      );
      final profile = ProgressService.instance.userProfile;

      // Hard XP: 15 * 1.5 = 22.5 -> 23, + 5 excellence bonus (score 100 >= 90)
      expect(xp, equals(28));
      expect(profile.observationPoints, equals(15)); // 15 * 1.0 tier
      expect(profile.totalXp, equals(28));
      expect(profile.totalExercisesCompleted, equals(1));
      expect(profile.creativityPoints, equals(0));
    });

    test('Observation Challenge XP scales with difficulty for the same performance',
        () async {
      final easyXp = await ProgressService.instance
          .recordObservationChallengeCompletion(
        performanceScore: 70,
        accuracy: 87.5,
        durationSeconds: 40,
        difficulty: ObservationDifficulty.easy,
      );
      final mediumXp = await ProgressService.instance
          .recordObservationChallengeCompletion(
        performanceScore: 80,
        accuracy: 87.5,
        durationSeconds: 40,
        difficulty: ObservationDifficulty.medium,
      );
      final hardXp = await ProgressService.instance
          .recordObservationChallengeCompletion(
        performanceScore: 90,
        accuracy: 87.5,
        durationSeconds: 40,
        difficulty: ObservationDifficulty.hard,
      );

      expect(easyXp, equals(15)); // 15 * 1.0, score 70 < 90 -> no bonus
      expect(mediumXp, equals(18)); // 15 * 1.2 = 18, score 80 < 90
      expect(hardXp, equals(28)); // 15 * 1.5 -> 23 + 5 bonus
    });

    test('Scenario Lab completion (engaged deliberation) awards full Decision Making gain',
        () async {
      final xp = await ProgressService.instance.recordScenarioLabCompletion(
        performanceScore: 100,
        durationSeconds: 90,
      );
      final profile = ProgressService.instance.userProfile;

      expect(xp, equals(25)); // 20 participation + 5 excellence bonus
      expect(profile.decisionMakingPoints, equals(15)); // 15 * 1.0 tier
      expect(profile.logicPoints, equals(10)); // 10 * 1.0 tier
      expect(profile.totalXp, equals(25));
      expect(profile.totalExercisesCompleted, equals(1));
    });

    test('Scenario Lab completion (rushed deliberation) awards minimal skill gain',
        () async {
      final xp = await ProgressService.instance.recordScenarioLabCompletion(
        performanceScore: 10,
        durationSeconds: 3,
      );
      final profile = ProgressService.instance.userProfile;

      expect(xp, equals(20)); // Participation XP is not score-dependent
      expect(profile.decisionMakingPoints, equals(3)); // 15 * 0.2
      expect(profile.logicPoints, equals(2)); // 10 * 0.2
    });

    test('Debate Arena completion (excellent) awards full Logic gain + excellence XP',
        () async {
      final xp = await ProgressService.instance.recordDebateArenaCompletion(
        performanceScore: 95,
        durationSeconds: 300,
      );
      final profile = ProgressService.instance.userProfile;

      expect(xp, equals(35)); // 30 participation + 5 excellence bonus
      expect(profile.logicPoints, equals(25)); // 25 * 1.0 tier
      expect(profile.totalXp, equals(35));
      expect(profile.totalExercisesCompleted, equals(1));
    });

    test('Debate Arena completion (weak) awards minimal Logic gain and base XP',
        () async {
      final xp = await ProgressService.instance.recordDebateArenaCompletion(
        performanceScore: 50,
        durationSeconds: 240,
      );
      final profile = ProgressService.instance.userProfile;

      expect(xp, equals(30)); // Participation XP only
      expect(profile.logicPoints, equals(5)); // 25 * 0.2
    });

    test('Skill gains strictly increase with performance tier boundaries',
        () async {
      // Minimal tier (< 60)
      await ProgressService.instance.recordStoryBuilderCompletion(
        performanceScore: 59.9,
        accuracy: 100,
        durationSeconds: 30,
      );
      // Small tier (60-74.9)
      await ProgressService.instance.recordStoryBuilderCompletion(
        performanceScore: 60,
        accuracy: 100,
        durationSeconds: 30,
      );
      // Moderate tier (75-89.9)
      await ProgressService.instance.recordStoryBuilderCompletion(
        performanceScore: 75,
        accuracy: 100,
        durationSeconds: 30,
      );
      // Strong tier (>= 90)
      await ProgressService.instance.recordStoryBuilderCompletion(
        performanceScore: 90,
        accuracy: 100,
        durationSeconds: 30,
      );

      final creativity = ProgressService.instance.userProfile.creativityPoints;
      // 3 + 7 + 11 + 15 (15*0.2=3, 15*0.45=6.75->7, 15*0.7=10.5->11, 15*1.0=15)
      expect(creativity, equals(36));
    });

    test('Multiple exercise completions accumulate total statistics and derive level accurately',
        () async {
      // 1x Story Builder (100): +15 Creativity, +20 XP, +1 Exercise
      await ProgressService.instance.recordStoryBuilderCompletion(
        performanceScore: 100,
        accuracy: 100,
        durationSeconds: 120,
      );
      // 1x Observation (easy, 100): +15 Observation, +20 XP, +1 Exercise
      await ProgressService.instance.recordObservationChallengeCompletion(
        performanceScore: 100,
        accuracy: 100,
        durationSeconds: 60,
        difficulty: ObservationDifficulty.easy,
      );
      // 4x Scenario Lab (100): 4 * (+15 Decision, +10 Logic, +25 XP, +1 Exercise)
      for (int i = 0; i < 4; i++) {
        await ProgressService.instance.recordScenarioLabCompletion(
          performanceScore: 100,
          durationSeconds: 90,
        );
      }

      final profile = ProgressService.instance.userProfile;

      expect(profile.creativityPoints, equals(15));
      expect(profile.observationPoints, equals(15));
      expect(profile.logicPoints, equals(40));
      expect(profile.decisionMakingPoints, equals(60));
      expect(profile.totalXp, equals(20 + 20 + 100)); // 140 XP
      expect(profile.totalExercisesCompleted, equals(6));
      expect(profile.level, equals(2)); // 1 + (140 ~/ 100) = 2
      expect(profile.currentXp, equals(40)); // 140 % 100 = 40
    });

    test('Profile persists locally and reloads cleanly after app restart',
        () async {
      await ProgressService.instance.recordStoryBuilderCompletion(
        performanceScore: 100,
        accuracy: 100,
        durationSeconds: 120,
      );
      await ProgressService.instance.recordScenarioLabCompletion(
        performanceScore: 100,
        durationSeconds: 90,
      );

      // Simulate app restart by re-initializing ProgressService instance
      await ProgressService.instance.init();
      final reloaded = ProgressService.instance.userProfile;

      expect(reloaded.creativityPoints, equals(15));
      expect(reloaded.decisionMakingPoints, equals(15));
      expect(reloaded.logicPoints, equals(10));
      expect(reloaded.totalXp, equals(45));
      expect(reloaded.totalExercisesCompleted, equals(2));
    });

    test('Notifies listeners when progress updates', () async {
      bool notified = false;
      void listener() {
        notified = true;
      }

      ProgressService.instance.addListener(listener);
      await ProgressService.instance.recordStoryBuilderCompletion(
        performanceScore: 100,
        accuracy: 100,
        durationSeconds: 120,
      );
      expect(notified, isTrue);

      ProgressService.instance.removeListener(listener);
    });

    group('Service-Level XP Idempotency Tests', () {
      test('First completion awards expected XP', () async {
        final xp = await ProgressService.instance.recordStoryBuilderCompletion(
          performanceScore: 100,
          accuracy: 100,
          durationSeconds: 120,
          idempotencyKey: 'story_attempt_001',
        );

        expect(xp, equals(20));
        final profile = ProgressService.instance.userProfile;
        expect(profile.totalXp, equals(20));
        expect(profile.creativityPoints, equals(15));
        expect(profile.totalExercisesCompleted, equals(1));
        expect(
            await ProgressService.instance
                .isCompletionProcessed('story_attempt_001'),
            isTrue);
      });

      test('Repeating the same completion awards no additional XP', () async {
        final firstXp =
            await ProgressService.instance.recordStoryBuilderCompletion(
          performanceScore: 100,
          accuracy: 100,
          durationSeconds: 120,
          idempotencyKey: 'story_attempt_002',
        );
        expect(firstXp, equals(20));

        // Attempt repeating the exact same completion
        final secondXp =
            await ProgressService.instance.recordStoryBuilderCompletion(
          performanceScore: 100,
          accuracy: 100,
          durationSeconds: 120,
          idempotencyKey: 'story_attempt_002',
        );
        expect(secondXp, equals(0));

        // Profile stats remain completely unchanged
        final profile = ProgressService.instance.userProfile;
        expect(profile.totalXp, equals(20));
        expect(profile.creativityPoints, equals(15));
        expect(profile.totalExercisesCompleted, equals(1));
      });

      test('Two different completions both award their legitimate rewards',
          () async {
        final storyXp =
            await ProgressService.instance.recordStoryBuilderCompletion(
          performanceScore: 100,
          accuracy: 100,
          durationSeconds: 120,
          idempotencyKey: 'story_attempt_003',
        );
        final obsXp = await ProgressService.instance
            .recordObservationChallengeCompletion(
          performanceScore: 100,
          accuracy: 100,
          durationSeconds: 60,
          difficulty: ObservationDifficulty.hard,
          idempotencyKey: 'obs_attempt_001',
        );

        expect(storyXp, equals(20));
        expect(obsXp, equals(28));
        final profile = ProgressService.instance.userProfile;
        expect(profile.totalXp, equals(48));
        expect(profile.creativityPoints, equals(15));
        expect(profile.observationPoints, equals(15));
        expect(profile.totalExercisesCompleted, equals(2));
      });

      test('Concurrent duplicate submissions cannot award XP twice', () async {
        // Trigger two simultaneous completions with the exact same idempotency key
        final results = await Future.wait([
          ProgressService.instance.recordScenarioLabCompletion(
            performanceScore: 100,
            durationSeconds: 90,
            idempotencyKey: 'scenario_concurrent_001',
          ),
          ProgressService.instance.recordScenarioLabCompletion(
            performanceScore: 100,
            durationSeconds: 90,
            idempotencyKey: 'scenario_concurrent_001',
          ),
        ]);

        // Exactly one call should succeed and award 25 XP; the other should return 0 XP
        expect(results.length, equals(2));
        expect(results, containsAll([25, 0]));
        final profile = ProgressService.instance.userProfile;
        expect(profile.totalXp, equals(25));
        expect(profile.decisionMakingPoints, equals(15));
        expect(profile.totalExercisesCompleted, equals(1));
      });

      test('A failed or interrupted operation can be retried safely', () async {
        const retryKey = 'debate_retry_001';
        // Before execution, key is not processed
        expect(await ProgressService.instance.isCompletionProcessed(retryKey),
            isFalse);

        // First attempt succeeds
        final xp = await ProgressService.instance.recordDebateArenaCompletion(
          performanceScore: 90,
          durationSeconds: 180,
          idempotencyKey: retryKey,
        );
        expect(xp, equals(35));
        expect(await ProgressService.instance.isCompletionProcessed(retryKey),
            isTrue);

        // Safe retry returns 0 XP without side-effects
        final retryXp =
            await ProgressService.instance.recordDebateArenaCompletion(
          performanceScore: 90,
          durationSeconds: 180,
          idempotencyKey: retryKey,
        );
        expect(retryXp, equals(0));
        expect(ProgressService.instance.userProfile.totalXp, equals(35));
      });

      test(
          'Analytics events are not duplicated for the same logical completion',
          () async {
        const testKey = 'analytics_dedup_001';
        final repo = AnalyticsRepository();

        await ProgressService.instance.recordStoryBuilderCompletion(
          performanceScore: 100,
          accuracy: 100,
          durationSeconds: 120,
          idempotencyKey: testKey,
        );

        // Repeat completion with identical key
        await ProgressService.instance.recordStoryBuilderCompletion(
          performanceScore: 100,
          accuracy: 100,
          durationSeconds: 120,
          idempotencyKey: testKey,
        );

        final events = await repo.getEvents();
        final matching =
            events.where((e) => e.id == 'analytics_$testKey').toList();
        expect(matching.length, equals(1));
      });

      test('Existing callers without idempotencyKey remain backward compatible',
          () async {
        final xp1 = await ProgressService.instance.recordStoryBuilderCompletion(
          performanceScore: 100,
          accuracy: 100,
          durationSeconds: 120,
        );
        final xp2 = await ProgressService.instance.recordStoryBuilderCompletion(
          performanceScore: 100,
          accuracy: 100,
          durationSeconds: 120,
        );

        expect(xp1, equals(20));
        expect(xp2, equals(20));
        expect(ProgressService.instance.userProfile.totalXp, equals(40));
        expect(ProgressService.instance.userProfile.totalExercisesCompleted,
            equals(2));
      });

      test(
          'Persistence across service re-initialization retains idempotency records',
          () async {
        const persistKey = 'restart_test_001';
        final xp = await ProgressService.instance
            .recordObservationChallengeCompletion(
          performanceScore: 80,
          accuracy: 80,
          durationSeconds: 45,
          difficulty: ObservationDifficulty.medium,
          idempotencyKey: persistKey,
        );
        expect(xp, equals(18));

        // Re-initialize ProgressService (simulating restart)
        await ProgressService.instance.init();
        expect(
            await ProgressService.instance.isCompletionProcessed(persistKey),
            isTrue);

        final repeatedXp = await ProgressService.instance
            .recordObservationChallengeCompletion(
          performanceScore: 80,
          accuracy: 80,
          durationSeconds: 45,
          difficulty: ObservationDifficulty.medium,
          idempotencyKey: persistKey,
        );
        expect(repeatedXp, equals(0));
      });
    });
  });
}
