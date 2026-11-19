import 'package:cognitive_gym/services/exercise_scoring_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Shared scoring rules', () {
    test('clampScore bounds values into 0-100 and handles NaN', () {
      expect(ExerciseScoringService.clampScore(-5), equals(0.0));
      expect(ExerciseScoringService.clampScore(0), equals(0.0));
      expect(ExerciseScoringService.clampScore(42.5), equals(42.5));
      expect(ExerciseScoringService.clampScore(100), equals(100.0));
      expect(ExerciseScoringService.clampScore(150), equals(100.0));
      expect(ExerciseScoringService.clampScore(double.nan), equals(0.0));
    });

    test('skillGainMultiplier maps performance tiers exactly', () {
      expect(ExerciseScoringService.skillGainMultiplier(100), equals(1.0));
      expect(ExerciseScoringService.skillGainMultiplier(90), equals(1.0));
      expect(ExerciseScoringService.skillGainMultiplier(89.9), equals(0.7));
      expect(ExerciseScoringService.skillGainMultiplier(75), equals(0.7));
      expect(ExerciseScoringService.skillGainMultiplier(74.9), equals(0.45));
      expect(ExerciseScoringService.skillGainMultiplier(60), equals(0.45));
      expect(ExerciseScoringService.skillGainMultiplier(59.9), equals(0.2));
      expect(ExerciseScoringService.skillGainMultiplier(0), equals(0.2));
    });

    test('scaledGain is monotonic and never negative', () {
      // Negative scores clamp to the minimal tier (0.2) rather than zeroing out.
      expect(ExerciseScoringService.scaledGain(15, -10), equals(3));
      expect(ExerciseScoringService.scaledGain(0, 100), equals(0));
      expect(ExerciseScoringService.scaledGain(25, 100), equals(25));
      expect(
        ExerciseScoringService.scaledGain(25, 50),
        lessThan(ExerciseScoringService.scaledGain(25, 70)),
      );
      expect(
        ExerciseScoringService.scaledGain(25, 70),
        lessThan(ExerciseScoringService.scaledGain(25, 95)),
      );
    });

    test('excellence XP bonus only applies at or above the 90 threshold', () {
      expect(ExerciseScoringService.excellenceBonusXp(89.9), equals(0));
      expect(ExerciseScoringService.excellenceBonusXp(90), equals(5));
      expect(ExerciseScoringService.excellenceBonusXp(100), equals(5));
    });
  });

  group('Observation Challenge scoring', () {
    test('perfect performance scores 100 on hard', () {
      final result = ExerciseScoringService.scoreObservationChallenge(
        totalQuestions: 5,
        correctAnswers: 5,
        difficulty: ObservationDifficulty.hard,
        durationSeconds: 60,
      );
      expect(result.accuracy, equals(100.0));
      expect(result.performanceScore, equals(100.0));
      expect(result.skillGainMultiplier, equals(1.0));
      // Hard XP: 15 * 1.5 = 23 (22.5 rounds away from zero) + 5 bonus.
      expect(result.xpEarned, equals(28));
    });

    test('same accuracy produces meaningfully different scores per difficulty', () {
      double scoreFor(ObservationDifficulty d) =>
          ExerciseScoringService.scoreObservationChallenge(
            totalQuestions: 10,
            correctAnswers: 8,
            difficulty: d,
            durationSeconds: 30,
          ).performanceScore;

      expect(scoreFor(ObservationDifficulty.easy), closeTo(64.0, 0.001));
      expect(scoreFor(ObservationDifficulty.medium), closeTo(74.0, 0.001));
      expect(scoreFor(ObservationDifficulty.hard), closeTo(84.0, 0.001));
      expect(
        scoreFor(ObservationDifficulty.hard) -
            scoreFor(ObservationDifficulty.easy),
        equals(20.0),
      );
    });

    test('poor performance on easy scores low with minimal gain', () {
      final result = ExerciseScoringService.scoreObservationChallenge(
        totalQuestions: 10,
        correctAnswers: 2,
        difficulty: ObservationDifficulty.easy,
        durationSeconds: 30,
      );
      expect(result.accuracy, equals(20.0));
      expect(result.performanceScore, closeTo(16.0, 0.001));
      expect(result.skillGainMultiplier, equals(0.2));
      expect(result.xpEarned, equals(15)); // easy 1.0x, no bonus
    });

    test('minimum score: zero correct answers on easy yields 0', () {
      final result = ExerciseScoringService.scoreObservationChallenge(
        totalQuestions: 5,
        correctAnswers: 0,
        difficulty: ObservationDifficulty.easy,
        durationSeconds: 20,
      );
      expect(result.accuracy, equals(0.0));
      expect(result.performanceScore, equals(0.0));
      expect(result.skillGainMultiplier, equals(0.2));
    });

    test('unanswered questions count as incorrect', () {
      final result = ExerciseScoringService.scoreObservationChallenge(
        totalQuestions: 5,
        correctAnswers: 3, // 2 unanswered
        difficulty: ObservationDifficulty.easy,
        durationSeconds: 20,
      );
      expect(result.accuracy, closeTo(60.0, 0.001));
      expect(result.performanceScore, closeTo(48.0, 0.001));
    });

    test('speed is never a scoring factor for identical answers', () {
      final fast = ExerciseScoringService.scoreObservationChallenge(
        totalQuestions: 5,
        correctAnswers: 4,
        difficulty: ObservationDifficulty.medium,
        durationSeconds: 10,
      );
      final slow = ExerciseScoringService.scoreObservationChallenge(
        totalQuestions: 5,
        correctAnswers: 4,
        difficulty: ObservationDifficulty.medium,
        durationSeconds: 600,
      );
      expect(fast.performanceScore, equals(slow.performanceScore));
      expect(fast.accuracy, equals(slow.accuracy));
    });

    test('correct answers are clamped to the question count', () {
      final result = ExerciseScoringService.scoreObservationChallenge(
        totalQuestions: 5,
        correctAnswers: 9,
        difficulty: ObservationDifficulty.easy,
        durationSeconds: 30,
      );
      expect(result.accuracy, equals(100.0));
    });

    test('invalid input throws ArgumentError', () {
      expect(
        () => ExerciseScoringService.scoreObservationChallenge(
          totalQuestions: 0,
          correctAnswers: 0,
          difficulty: ObservationDifficulty.easy,
          durationSeconds: 30,
        ),
        throwsArgumentError,
      );
      expect(
        () => ExerciseScoringService.scoreObservationChallenge(
          totalQuestions: 5,
          correctAnswers: -1,
          difficulty: ObservationDifficulty.easy,
          durationSeconds: 30,
        ),
        throwsArgumentError,
      );
      expect(
        () => ExerciseScoringService.scoreObservationChallenge(
          totalQuestions: 5,
          correctAnswers: 3,
          difficulty: ObservationDifficulty.easy,
          durationSeconds: -5,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Story Builder scoring', () {
    const requiredWords = ['River', 'Lantern', 'Summit'];

    test('perfect story (all constraints, target length, rich vocabulary) scores 100', () {
      final words = List.generate(80, (i) => 'word$i').toList()..addAll(requiredWords);
      final story = words.join(' ');
      final result = ExerciseScoringService.scoreStoryBuilder(
        storyText: story,
        requiredWords: requiredWords,
        minWordCount: 40,
      );
      expect(result.accuracy, equals(100.0));
      expect(result.performanceScore, equals(100.0));
      expect(result.skillGainMultiplier, equals(1.0));
      expect(result.xpEarned, equals(20)); // 15 + excellence bonus
    });

    test('minimum viable story (40 words, all required) gets partial length credit', () {
      final story =
          '${List.generate(40, (i) => 'word$i').join(' ')} river lantern summit';
      final result = ExerciseScoringService.scoreStoryBuilder(
        storyText: story,
        requiredWords: requiredWords,
        minWordCount: 40,
      );
      expect(result.accuracy, equals(100.0)); // all required words used
      // Length: 43/80 = 0.5375 -> 40% weight = 21.5 pts; vocab high for short
      // text; integration 25 pts. Score should land in the small/moderate tier.
      expect(result.performanceScore, greaterThan(60.0));
      expect(result.performanceScore, lessThan(90.0));
      expect(result.xpEarned, equals(15)); // below excellence threshold
    });

    test('repetitive story is penalized through the vocabulary component', () {
      final repetitive =
          '${List.generate(120, (i) => 'cat').join(' ')} river lantern summit';
      final varied =
          '${List.generate(80, (i) => 'word$i').join(' ')} river lantern summit';

      final repetitiveScore = ExerciseScoringService.scoreStoryBuilder(
        storyText: repetitive,
        requiredWords: requiredWords,
        minWordCount: 40,
      ).performanceScore;
      final variedScore = ExerciseScoringService.scoreStoryBuilder(
        storyText: varied,
        requiredWords: requiredWords,
        minWordCount: 40,
      ).performanceScore;

      expect(variedScore, greaterThan(repetitiveScore));
    });

    test('missing required words lower accuracy and the integration component', () {
      final story =
          '${List.generate(80, (i) => 'word$i').join(' ')} river';
      final result = ExerciseScoringService.scoreStoryBuilder(
        storyText: story,
        requiredWords: requiredWords,
        minWordCount: 40,
      );
      expect(result.accuracy, closeTo(100.0 * (1 / 3), 0.001));
      expect(result.performanceScore, lessThan(100.0));
    });

    test('empty story scores 0 but is valid input', () {
      final result = ExerciseScoringService.scoreStoryBuilder(
        storyText: '',
        requiredWords: requiredWords,
        minWordCount: 40,
      );
      expect(result.accuracy, equals(0.0));
      expect(result.performanceScore, equals(0.0));
      expect(result.xpEarned, equals(15));
    });

    test('case and punctuation differences still count as required word usage', () {
      final story =
          '${List.generate(80, (i) => 'word$i').join(' ')} RIVER! lantern, (SuMmIt)?';
      final result = ExerciseScoringService.scoreStoryBuilder(
        storyText: story,
        requiredWords: requiredWords,
        minWordCount: 40,
      );
      expect(result.accuracy, equals(100.0));
    });

    test('custom target word count scales the length component', () {
      final story =
          '${List.generate(40, (i) => 'word$i').join(' ')} river lantern summit';
      final strict = ExerciseScoringService.scoreStoryBuilder(
        storyText: story,
        requiredWords: requiredWords,
        minWordCount: 40,
        targetWordCount: 40,
      );
      final lenient = ExerciseScoringService.scoreStoryBuilder(
        storyText: story,
        requiredWords: requiredWords,
        minWordCount: 40,
        targetWordCount: 400,
      );
      expect(strict.performanceScore, greaterThan(lenient.performanceScore));
    });

    test('invalid input throws ArgumentError', () {
      expect(
        () => ExerciseScoringService.scoreStoryBuilder(
          storyText: 'story',
          requiredWords: requiredWords,
          minWordCount: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => ExerciseScoringService.scoreStoryBuilder(
          storyText: 'story',
          requiredWords: [],
          minWordCount: 40,
        ),
        throwsArgumentError,
      );
      expect(
        () => ExerciseScoringService.scoreStoryBuilder(
          storyText: 'story',
          requiredWords: requiredWords,
          minWordCount: 40,
          targetWordCount: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Scenario Lab scoring', () {
    test('fully deliberated decision (meets reading estimate) scores 100', () {
      final result = ExerciseScoringService.scoreScenarioLab(
        scenarioWordCount: 120, // 120 words @ 200wpm = 36s minimum
        deliberationSeconds: 36,
      );
      expect(result.accuracy, isNull); // No accuracy for trade-off dilemmas
      expect(result.performanceScore, equals(100.0));
      expect(result.skillGainMultiplier, equals(1.0));
      expect(result.xpEarned, equals(25)); // 20 + excellence bonus
    });

    test('rushed confirmation scores low proportionally to engagement', () {
      final result = ExerciseScoringService.scoreScenarioLab(
        scenarioWordCount: 120, // 36s minimum
        deliberationSeconds: 9,
      );
      expect(result.performanceScore, closeTo(25.0, 0.001));
      expect(result.skillGainMultiplier, equals(0.2));
      expect(result.xpEarned, equals(20)); // participation XP unchanged
    });

    test('minimum score at zero deliberation', () {
      final result = ExerciseScoringService.scoreScenarioLab(
        scenarioWordCount: 100,
        deliberationSeconds: 0,
      );
      expect(result.performanceScore, equals(0.0));
      expect(result.accuracy, isNull);
    });

    test('slow readers are never penalized (long deliberation caps at 100)', () {
      final result = ExerciseScoringService.scoreScenarioLab(
        scenarioWordCount: 60, // 18s minimum
        deliberationSeconds: 300,
      );
      expect(result.performanceScore, equals(100.0));
    });

    test('reading estimate floors at 10 seconds and follows 200wpm', () {
      expect(ExerciseScoringService.estimatedReadingSeconds(5), equals(10));
      expect(ExerciseScoringService.estimatedReadingSeconds(0), equals(10));
      expect(ExerciseScoringService.estimatedReadingSeconds(200), equals(60));
    });

    test('deliberation is capped at 30 minutes', () {
      final result = ExerciseScoringService.scoreScenarioLab(
        scenarioWordCount: 60,
        deliberationSeconds: 999999,
      );
      expect(result.performanceScore, equals(100.0));
    });

    test('invalid input throws ArgumentError', () {
      expect(
        () => ExerciseScoringService.scoreScenarioLab(
          scenarioWordCount: -1,
          deliberationSeconds: 30,
        ),
        throwsArgumentError,
      );
      expect(
        () => ExerciseScoringService.scoreScenarioLab(
          scenarioWordCount: 100,
          deliberationSeconds: -1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('Debate Arena scoring', () {
    test('full participation with substantial arguments scores high deterministically', () {
      final result = ExerciseScoringService.scoreDebateDeterministic(
        userTurns: 5,
        maxTurns: 5,
        argumentWordCounts: [40, 40, 40, 40, 40], // 200 words = full substance
      );
      expect(result.accuracy, isNull); // No accuracy for debate arguments
      expect(result.performanceScore, equals(100.0));
      expect(result.skillGainMultiplier, equals(1.0));
      expect(result.xpEarned, equals(35)); // 30 + excellence bonus
    });

    test('full participation with short arguments is capped by substance', () {
      final result = ExerciseScoringService.scoreDebateDeterministic(
        userTurns: 5,
        maxTurns: 5,
        argumentWordCounts: [5, 5, 5, 5, 5], // 25 words of a 200 target
      );
      // Participation 60 + substance 25/200 * 40 = 5 -> 65
      expect(result.performanceScore, closeTo(65.0, 0.001));
      expect(result.skillGainMultiplier, equals(0.45));
      expect(result.xpEarned, equals(30));
    });

    test('average debate (full turns, moderate length) lands in the moderate tier', () {
      final result = ExerciseScoringService.scoreDebateDeterministic(
        userTurns: 5,
        maxTurns: 5,
        argumentWordCounts: [25, 25, 25, 25, 25], // 125/200 substance
      );
      // 60 + 25 = 85
      expect(result.performanceScore, closeTo(85.0, 0.001));
      expect(result.skillGainMultiplier, equals(0.7));
    });

    test('poor participation (dropped out early) scores low', () {
      final result = ExerciseScoringService.scoreDebateDeterministic(
        userTurns: 1,
        maxTurns: 5,
        argumentWordCounts: [10],
      );
      // Participation 12 + substance 10/200*40 = 2 -> 14
      expect(result.performanceScore, closeTo(14.0, 0.001));
      expect(result.skillGainMultiplier, equals(0.2));
    });

    test('minimum score at zero participation', () {
      final result = ExerciseScoringService.scoreDebateDeterministic(
        userTurns: 0,
        maxTurns: 5,
        argumentWordCounts: [],
      );
      expect(result.performanceScore, equals(0.0));
    });

    test('oversized single argument cannot dominate (per-argument cap)', () {
      final dominated = ExerciseScoringService.scoreDebateDeterministic(
        userTurns: 5,
        maxTurns: 5,
        argumentWordCounts: [400, 1, 1, 1, 1],
      );
      final balanced = ExerciseScoringService.scoreDebateDeterministic(
        userTurns: 5,
        maxTurns: 5,
        argumentWordCounts: [81, 80, 80, 80, 80],
      );
      // Both hit the substance cap of 40 points.
      expect(dominated.performanceScore, equals(100.0));
      expect(balanced.performanceScore, equals(100.0));
    });

    test('turns are clamped to maxTurns', () {
      final result = ExerciseScoringService.scoreDebateDeterministic(
        userTurns: 12,
        maxTurns: 5,
        argumentWordCounts: [40, 40, 40, 40, 40],
      );
      expect(result.performanceScore, equals(100.0));
    });

    test('AI evaluation parsing accepts clean JSON', () {
      final score = ExerciseScoringService.parseDebateAiEvaluation(
        '{"relevance": 35, "reasoning": 30, "engagement": 15}',
      );
      expect(score, equals(80));
    });

    test('AI evaluation parsing extracts JSON embedded in prose or fences', () {
      final score = ExerciseScoringService.parseDebateAiEvaluation(
        'Sure! Here is my evaluation:\n```json\n'
        '{"relevance": 40, "reasoning": 40, "engagement": 20}\n'
        '```\nHope that helps.',
      );
      expect(score, equals(100));
    });

    test('AI evaluation clamps out-of-range rubric values', () {
      final score = ExerciseScoringService.parseDebateAiEvaluation(
        '{"relevance": 99, "reasoning": -10, "engagement": 20}',
      );
      // 99 -> 40, -10 -> 0, 20 -> 20
      expect(score, equals(60));
    });

    test('AI evaluation returns null for malformed output', () {
      expect(
        ExerciseScoringService.parseDebateAiEvaluation('no json here'),
        isNull,
      );
      expect(
        ExerciseScoringService.parseDebateAiEvaluation('{not json}'),
        isNull,
      );
      expect(
        ExerciseScoringService.parseDebateAiEvaluation(
          '{"relevance": 30, "reasoning": 30}', // missing engagement
        ),
        isNull,
      );
      expect(
        ExerciseScoringService.parseDebateAiEvaluation(
          '{"relevance": "high", "reasoning": 30, "engagement": 10}',
        ),
        isNull,
      );
      expect(
        ExerciseScoringService.parseDebateAiEvaluation('[1, 2, 3]'),
        isNull,
      );
    });

    test('numeric string rubric values are accepted', () {
      final score = ExerciseScoringService.parseDebateAiEvaluation(
        '{"relevance": "35", "reasoning": "25", "engagement": "10"}',
      );
      expect(score, equals(70));
    });

    test('combining without AI score uses the deterministic score unchanged', () {
      expect(ExerciseScoringService.combineDebateScores(72, null), equals(72));
      expect(
        ExerciseScoringService.combineDebateScores(150, null),
        equals(100),
      );
      expect(ExerciseScoringService.combineDebateScores(-5, null), equals(0));
    });

    test('combining with an AI score blends 60% deterministic / 40% AI', () {
      // 0.6 * 80 + 0.4 * 90 = 84
      expect(ExerciseScoringService.combineDebateScores(80, 90), equals(84));
      // 0.6 * 60 + 0.4 * 100 = 76
      expect(ExerciseScoringService.combineDebateScores(60, 100), equals(76));
      // AI score is clamped into 0-100 before blending.
      expect(ExerciseScoringService.combineDebateScores(60, 500), equals(76));
    });

    test('invalid deterministic input throws ArgumentError', () {
      expect(
        () => ExerciseScoringService.scoreDebateDeterministic(
          userTurns: 3,
          maxTurns: 0,
          argumentWordCounts: [10],
        ),
        throwsArgumentError,
      );
      expect(
        () => ExerciseScoringService.scoreDebateDeterministic(
          userTurns: -1,
          maxTurns: 5,
          argumentWordCounts: [10],
        ),
        throwsArgumentError,
      );
      expect(
        () => ExerciseScoringService.scoreDebateDeterministic(
          userTurns: 3,
          maxTurns: 5,
          argumentWordCounts: [10, -5],
        ),
        throwsArgumentError,
      );
    });
  });
}
