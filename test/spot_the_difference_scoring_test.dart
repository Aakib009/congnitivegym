import 'package:cognitive_gym/models/spot_the_difference.dart';
import 'package:cognitive_gym/services/exercise_scoring_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Spot the Difference Scoring Tests', () {
    test('perfect easy run awards base XP and scaled observation points', () {
      final result = ExerciseScoringService.scoreSpotTheDifference(
        totalDifferences: 4,
        discoveredDifferences: 4,
        incorrectTaps: 0,
        difficulty: SpotDifferenceDifficulty.easy,
        durationSeconds: 45,
      );

      expect(result.accuracy, equals(100.0));
      expect(result.performanceScore, equals(85.0));
      expect(
        result.xpEarned,
        equals(20),
      ); // 20 * 1.0, no excellence bonus since < 90
      expect(result.skillGainMultiplier, equals(0.7)); // 85 >= 75 -> 0.7
    });

    test(
      'perfect medium run awards medium multiplier and excellence bonus',
      () {
        final result = ExerciseScoringService.scoreSpotTheDifference(
          totalDifferences: 4,
          discoveredDifferences: 4,
          incorrectTaps: 0,
          difficulty: SpotDifferenceDifficulty.medium,
          durationSeconds: 40,
        );

        expect(result.accuracy, equals(100.0));
        expect(result.performanceScore, equals(95.0)); // 70 + 15 + 10 = 95
        expect(
          result.xpEarned,
          equals(29),
        ); // round(20 * 1.2) + 5 = 24 + 5 = 29
        expect(result.skillGainMultiplier, equals(1.0)); // 95 >= 90 -> 1.0
      },
    );

    test('perfect hard run awards hard multiplier and maximum score 100', () {
      final result = ExerciseScoringService.scoreSpotTheDifference(
        totalDifferences: 4,
        discoveredDifferences: 4,
        incorrectTaps: 0,
        difficulty: SpotDifferenceDifficulty.hard,
        durationSeconds: 30,
      );

      expect(result.accuracy, equals(100.0));
      expect(
        result.performanceScore,
        equals(100.0),
      ); // 70 + 15 + 20 = 105 -> clamped to 100
      expect(result.xpEarned, equals(35)); // round(20 * 1.5) + 5 = 30 + 5 = 35
      expect(result.skillGainMultiplier, equals(1.0));
    });

    test(
      'partial discoveries with incorrect attempts calculate accurate metrics',
      () {
        // Found 2 of 4 with 2 mistakes: completion = 50%, accuracy = 2 / 4 = 50%
        final result = ExerciseScoringService.scoreSpotTheDifference(
          totalDifferences: 4,
          discoveredDifferences: 2,
          incorrectTaps: 2,
          difficulty: SpotDifferenceDifficulty.medium,
          durationSeconds: 50,
        );

        // performance = 0.70 * 50 + 0.15 * 50 + 10 = 35 + 7.5 + 10 = 52.5
        expect(result.accuracy, equals(50.0));
        expect(result.performanceScore, closeTo(52.5, 0.01));
        expect(result.xpEarned, equals(24)); // 20 * 1.2, no excellence
        expect(result.skillGainMultiplier, equals(0.2)); // < 60 -> 0.2
      },
    );

    test('zero discoveries awards minimum score and participation XP only', () {
      final result = ExerciseScoringService.scoreSpotTheDifference(
        totalDifferences: 4,
        discoveredDifferences: 0,
        incorrectTaps: 3,
        difficulty: SpotDifferenceDifficulty.easy,
        durationSeconds: 60,
      );

      expect(result.accuracy, equals(0.0));
      expect(result.performanceScore, equals(0.0));
      expect(result.xpEarned, equals(20)); // participation base XP
      expect(result.skillGainMultiplier, equals(0.2));
    });

    test('duration does not penalize score', () {
      final fast = ExerciseScoringService.scoreSpotTheDifference(
        totalDifferences: 4,
        discoveredDifferences: 4,
        incorrectTaps: 0,
        difficulty: SpotDifferenceDifficulty.easy,
        durationSeconds: 10,
      );
      final slow = ExerciseScoringService.scoreSpotTheDifference(
        totalDifferences: 4,
        discoveredDifferences: 4,
        incorrectTaps: 0,
        difficulty: SpotDifferenceDifficulty.easy,
        durationSeconds: 300,
      );

      expect(fast.performanceScore, equals(slow.performanceScore));
      expect(fast.xpEarned, equals(slow.xpEarned));
      expect(fast.accuracy, equals(slow.accuracy));
    });

    test('rejects invalid inputs with ArgumentError', () {
      expect(
        () => ExerciseScoringService.scoreSpotTheDifference(
          totalDifferences: 0,
          discoveredDifferences: 0,
          incorrectTaps: 0,
          difficulty: SpotDifferenceDifficulty.easy,
          durationSeconds: 10,
        ),
        throwsArgumentError,
      );
      expect(
        () => ExerciseScoringService.scoreSpotTheDifference(
          totalDifferences: 4,
          discoveredDifferences: -1,
          incorrectTaps: 0,
          difficulty: SpotDifferenceDifficulty.easy,
          durationSeconds: 10,
        ),
        throwsArgumentError,
      );
      expect(
        () => ExerciseScoringService.scoreSpotTheDifference(
          totalDifferences: 4,
          discoveredDifferences: 2,
          incorrectTaps: -1,
          difficulty: SpotDifferenceDifficulty.easy,
          durationSeconds: 10,
        ),
        throwsArgumentError,
      );
      expect(
        () => ExerciseScoringService.scoreSpotTheDifference(
          totalDifferences: 4,
          discoveredDifferences: 2,
          incorrectTaps: 0,
          difficulty: SpotDifferenceDifficulty.easy,
          durationSeconds: -5,
        ),
        throwsArgumentError,
      );
    });
  });
}
