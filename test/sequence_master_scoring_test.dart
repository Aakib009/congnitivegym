import 'package:cognitive_gym/models/sequence_master.dart';
import 'package:cognitive_gym/services/exercise_scoring_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sequence Master scoring', () {
    test('perfect hard performance is 100 and awards hard XP', () {
      final result = ExerciseScoringService.scoreSequenceMaster(
        totalQuestions: 12,
        correctAnswers: 12,
        difficulty: SequenceMasterDifficulty.hard,
        durationSeconds: 120,
      );

      expect(result.accuracy, equals(100.0));
      expect(result.performanceScore, equals(100.0));
      expect(result.skillGainMultiplier, equals(1.0));
      expect(result.xpEarned, equals(35));
    });

    test(
      'perfect medium performance is 90 and receives the excellence bonus',
      () {
        final result = ExerciseScoringService.scoreSequenceMaster(
          totalQuestions: 10,
          correctAnswers: 10,
          difficulty: SequenceMasterDifficulty.medium,
          durationSeconds: 120,
        );

        expect(result.accuracy, equals(100.0));
        expect(result.performanceScore, equals(90.0));
        expect(result.skillGainMultiplier, equals(1.0));
        expect(result.xpEarned, equals(29));
      },
    );

    test('perfect easy performance is 80 and awards participation XP only', () {
      final result = ExerciseScoringService.scoreSequenceMaster(
        totalQuestions: 8,
        correctAnswers: 8,
        difficulty: SequenceMasterDifficulty.easy,
        durationSeconds: 120,
      );

      expect(result.accuracy, equals(100.0));
      expect(result.performanceScore, equals(80.0));
      expect(result.skillGainMultiplier, equals(0.7));
      expect(result.xpEarned, equals(20));
    });

    test('zero correct on easy still awards participation XP', () {
      final result = ExerciseScoringService.scoreSequenceMaster(
        totalQuestions: 8,
        correctAnswers: 0,
        difficulty: SequenceMasterDifficulty.easy,
        durationSeconds: 120,
      );

      expect(result.accuracy, equals(0.0));
      expect(result.performanceScore, equals(0.0));
      expect(result.skillGainMultiplier, equals(0.2));
      expect(result.xpEarned, equals(20));
    });

    test('same accuracy produces the expected difficulty spread', () {
      double scoreFor(SequenceMasterDifficulty difficulty) =>
          ExerciseScoringService.scoreSequenceMaster(
            totalQuestions: 10,
            correctAnswers: 8,
            difficulty: difficulty,
            durationSeconds: 60,
          ).performanceScore;

      expect(scoreFor(SequenceMasterDifficulty.easy), closeTo(64, 0.001));
      expect(scoreFor(SequenceMasterDifficulty.medium), closeTo(74, 0.001));
      expect(scoreFor(SequenceMasterDifficulty.hard), closeTo(84, 0.001));
    });

    test('partial hard run scores accuracy and uses the hard multiplier', () {
      final result = ExerciseScoringService.scoreSequenceMaster(
        totalQuestions: 12,
        correctAnswers: 6,
        difficulty: SequenceMasterDifficulty.hard,
        durationSeconds: 90,
      );

      expect(result.accuracy, equals(50.0));
      expect(result.performanceScore, equals(60.0));
      expect(result.skillGainMultiplier, equals(0.45));
      expect(result.xpEarned, equals(30));
    });

    test('speed does not affect the score', () {
      final fast = ExerciseScoringService.scoreSequenceMaster(
        totalQuestions: 12,
        correctAnswers: 9,
        difficulty: SequenceMasterDifficulty.hard,
        durationSeconds: 5,
      );
      final slow = ExerciseScoringService.scoreSequenceMaster(
        totalQuestions: 12,
        correctAnswers: 9,
        difficulty: SequenceMasterDifficulty.hard,
        durationSeconds: 600,
      );

      expect(fast.performanceScore, slow.performanceScore);
      expect(fast.accuracy, slow.accuracy);
      expect(fast.xpEarned, slow.xpEarned);
    });

    test('correct answers are clamped to the question count', () {
      final result = ExerciseScoringService.scoreSequenceMaster(
        totalQuestions: 12,
        correctAnswers: 30,
        difficulty: SequenceMasterDifficulty.hard,
        durationSeconds: 60,
      );

      expect(result.accuracy, equals(100.0));
      expect(result.performanceScore, equals(100.0));
      expect(result.xpEarned, equals(35));
    });

    test('rejects invalid scoring inputs', () {
      expect(
        () => ExerciseScoringService.scoreSequenceMaster(
          totalQuestions: 0,
          correctAnswers: 0,
          difficulty: SequenceMasterDifficulty.easy,
          durationSeconds: 10,
        ),
        throwsArgumentError,
      );
      expect(
        () => ExerciseScoringService.scoreSequenceMaster(
          totalQuestions: 8,
          correctAnswers: -1,
          difficulty: SequenceMasterDifficulty.easy,
          durationSeconds: 10,
        ),
        throwsArgumentError,
      );
      expect(
        () => ExerciseScoringService.scoreSequenceMaster(
          totalQuestions: 8,
          correctAnswers: 4,
          difficulty: SequenceMasterDifficulty.easy,
          durationSeconds: -1,
        ),
        throwsArgumentError,
      );
    });
  });
}
