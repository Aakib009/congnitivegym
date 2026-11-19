import 'package:cognitive_gym/models/cognitive_analytics_model.dart';
import 'package:cognitive_gym/models/sequence_master.dart';
import 'package:cognitive_gym/services/analytics_repository.dart';
import 'package:cognitive_gym/services/analytics_service.dart';
import 'package:cognitive_gym/services/database_service.dart';
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

  group('Sequence Master progress', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await DatabaseService.instance.clearAllAnalyticsEvents();
      await ProgressService.instance.init();
      await ProgressService.instance.resetProgress();
    });

    test('perfect hard run awards hard XP and full logic gain', () async {
      final xp = await ProgressService.instance.recordSequenceMasterCompletion(
        performanceScore: 100,
        accuracy: 100,
        durationSeconds: 120,
        difficulty: SequenceMasterDifficulty.hard,
      );
      final profile = ProgressService.instance.userProfile;

      expect(xp, equals(35));
      expect(profile.logicPoints, equals(20));
      expect(profile.totalXp, equals(35));
      expect(profile.totalExercisesCompleted, equals(1));
      expect(profile.creativityPoints, equals(0));
      expect(profile.observationPoints, equals(0));
      expect(profile.decisionMakingPoints, equals(0));
    });

    test('zero-score easy run awards participation XP only', () async {
      final xp = await ProgressService.instance.recordSequenceMasterCompletion(
        performanceScore: 0,
        accuracy: 0,
        durationSeconds: 60,
        difficulty: SequenceMasterDifficulty.easy,
      );
      final profile = ProgressService.instance.userProfile;

      expect(xp, equals(20));
      expect(profile.logicPoints, equals(4));
      expect(profile.totalXp, equals(20));
      expect(profile.totalExercisesCompleted, equals(1));
    });

    test(
      'partial medium run uses the medium XP multiplier and middle gain',
      () async {
        final xp = await ProgressService.instance
            .recordSequenceMasterCompletion(
              performanceScore: 74,
              accuracy: 80,
              durationSeconds: 90,
              difficulty: SequenceMasterDifficulty.medium,
            );
        final profile = ProgressService.instance.userProfile;

        expect(xp, equals(24));
        expect(profile.logicPoints, equals(9));
        expect(profile.totalXp, equals(24));
      },
    );

    test('repeating the same attempt cannot award XP twice', () async {
      const key = 'sequence_attempt_001';
      final first = await ProgressService.instance
          .recordSequenceMasterCompletion(
            performanceScore: 100,
            accuracy: 100,
            durationSeconds: 120,
            difficulty: SequenceMasterDifficulty.hard,
            idempotencyKey: key,
          );
      final second = await ProgressService.instance
          .recordSequenceMasterCompletion(
            performanceScore: 100,
            accuracy: 100,
            durationSeconds: 120,
            difficulty: SequenceMasterDifficulty.hard,
            idempotencyKey: key,
          );

      expect(first, equals(35));
      expect(second, equals(0));
      expect(await ProgressService.instance.isCompletionProcessed(key), isTrue);
      expect(ProgressService.instance.userProfile.totalXp, equals(35));
      expect(ProgressService.instance.userProfile.logicPoints, equals(20));
      expect(
        ProgressService.instance.userProfile.totalExercisesCompleted,
        equals(1),
      );
    });

    test('concurrent duplicate submissions award rewards once', () async {
      const key = 'sequence_concurrent_001';
      final results = await Future.wait([
        ProgressService.instance.recordSequenceMasterCompletion(
          performanceScore: 100,
          accuracy: 100,
          durationSeconds: 120,
          difficulty: SequenceMasterDifficulty.hard,
          idempotencyKey: key,
        ),
        ProgressService.instance.recordSequenceMasterCompletion(
          performanceScore: 100,
          accuracy: 100,
          durationSeconds: 120,
          difficulty: SequenceMasterDifficulty.hard,
          idempotencyKey: key,
        ),
      ]);

      expect(results, containsAll([35, 0]));
      expect(ProgressService.instance.userProfile.totalXp, equals(35));
      expect(ProgressService.instance.userProfile.logicPoints, equals(20));
      expect(
        ProgressService.instance.userProfile.totalExercisesCompleted,
        equals(1),
      );
    });

    test('distinct attempts accumulate rewards', () async {
      final easy = await ProgressService.instance
          .recordSequenceMasterCompletion(
            performanceScore: 0,
            accuracy: 0,
            durationSeconds: 60,
            difficulty: SequenceMasterDifficulty.easy,
            idempotencyKey: 'sequence_attempt_easy',
          );
      final medium = await ProgressService.instance
          .recordSequenceMasterCompletion(
            performanceScore: 74,
            accuracy: 80,
            durationSeconds: 90,
            difficulty: SequenceMasterDifficulty.medium,
            idempotencyKey: 'sequence_attempt_medium',
          );

      expect(easy, equals(20));
      expect(medium, equals(24));
      expect(ProgressService.instance.userProfile.totalXp, equals(44));
      expect(ProgressService.instance.userProfile.logicPoints, equals(13));
      expect(
        ProgressService.instance.userProfile.totalExercisesCompleted,
        equals(2),
      );
    });

    test(
      'attempts without an idempotency key remain backward compatible',
      () async {
        final first = await ProgressService.instance
            .recordSequenceMasterCompletion(
              performanceScore: 100,
              accuracy: 100,
              durationSeconds: 120,
              difficulty: SequenceMasterDifficulty.hard,
            );
        final second = await ProgressService.instance
            .recordSequenceMasterCompletion(
              performanceScore: 100,
              accuracy: 100,
              durationSeconds: 120,
              difficulty: SequenceMasterDifficulty.hard,
            );

        expect(first, equals(35));
        expect(second, equals(35));
        expect(ProgressService.instance.userProfile.totalXp, equals(70));
      },
    );

    test(
      'records a sequence_master analytics event and breakdown count',
      () async {
        const key = 'sequence_analytics_001';
        await ProgressService.instance.recordSequenceMasterCompletion(
          performanceScore: 100,
          accuracy: 100,
          durationSeconds: 120,
          difficulty: SequenceMasterDifficulty.hard,
          idempotencyKey: key,
        );

        final repo = AnalyticsRepository();
        List<dynamic> events = const [];
        for (var attempt = 0; attempt < 20; attempt++) {
          events = await repo.getEvents();
          if (events.any((event) => event.exerciseType == 'sequence_master')) {
            break;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }

        final matching = events
            .where((event) => event.exerciseType == 'sequence_master')
            .toList();
        expect(matching.length, equals(1));
        expect(matching.single.id, equals('analytics_$key'));
        expect(matching.single.xpEarned, equals(35));
        expect(matching.single.score, equals(1.0));
        expect(matching.single.accuracy, equals(1.0));
        expect(matching.single.logicDelta, equals(20));

        await AnalyticsService.instance.loadAnalytics(
          timeRange: AnalyticsTimeRange.allTime,
        );
        expect(
          AnalyticsService
              .instance
              .analyticsData
              .exerciseBreakdown
              .sequenceMaster,
          equals(1),
        );
      },
    );
  });
}
