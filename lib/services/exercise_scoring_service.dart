import 'dart:convert';

import '../models/sequence_master.dart';
import '../models/spot_the_difference.dart';
import '../models/story_model.dart';

/// Difficulty levels for the Observation Challenge exercise.
///
/// [scoreBonus] is added directly to the 0-100 performance score and makes
/// Easy/Medium/Hard produce meaningfully different scores for identical
/// answer accuracy. [xpMultiplier] scales the participation XP so that
/// harder runs reward slightly more progression without turning XP into a
/// score proxy.
enum ObservationDifficulty {
  easy(0.0, 1.0),
  medium(10.0, 1.2),
  hard(20.0, 1.5);

  final double scoreBonus;
  final double xpMultiplier;

  const ObservationDifficulty(this.scoreBonus, this.xpMultiplier);
}

/// Deterministic scoring result for a single exercise completion.
///
/// * [performanceScore] is always normalized to 0-100.
/// * [accuracy] is normalized to 0-100 when the exercise has a genuinely
///   meaningful accuracy concept, otherwise it is `null` (callers must not
///   pretend accuracy applies where it does not).
/// * [xpEarned] is bounded participation XP (never a copy of the score).
/// * [skillGainMultiplier] scales skill-point gains by performance tier.
class ExerciseScoreResult {
  final double performanceScore;
  final double? accuracy;
  final int xpEarned;
  final double skillGainMultiplier;

  const ExerciseScoreResult({
    required this.performanceScore,
    required this.accuracy,
    required this.xpEarned,
    required this.skillGainMultiplier,
  });
}

/// Deterministic, objective scoring engine for the five Cognitive Gym
/// exercises.
///
/// IMPORTANT SCOPE NOTE: these scores measure *in-app training performance*
/// only. They are NOT clinically validated measurements of real-world
/// cognitive ability, and no function in this class fabricates precision
/// beyond what the exercise interaction can objectively observe.
abstract final class ExerciseScoringService {
  ExerciseScoringService._();

  // ===========================================================================
  // SHARED GAMIFICATION RULES
  // ===========================================================================

  /// Performance score (0-100) at or above which the small one-time
  /// excellence XP bonus is granted for a completion.
  static const double excellenceThreshold = 90.0;

  /// Bounded excellence XP bonus. Keeps XP tied to participation while still
  /// acknowledging outstanding runs, without making score == XP.
  static const int excellenceXpBonus = 5;

  /// Base participation XP per exercise completion (before difficulty
  /// multiplier and excellence bonus). These match the pre-existing economy.
  static const int storyBuilderBaseXp = 15;
  static const int observationBaseXp = 15;
  static const int sequenceMasterBaseXp = 20;
  static const int scenarioLabBaseXp = 20;
  static const int debateArenaBaseXp = 30;
  static const int spotTheDifferenceBaseXp = 20;

  /// Clamps a value into the normalized 0-100 score range.
  static double clampScore(num value) {
    final double v = value.toDouble();
    if (v.isNaN) return 0.0;
    if (v < 0) return 0.0;
    if (v > 100) return 100.0;
    return v;
  }

  static int _clampInt(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  /// Counts whitespace-separated words in [text] (0 for empty text).
  static int wordCount(String text) => StoryModel.countWords(text);

  /// Performance-dependent skill progression multiplier.
  ///
  /// Tiers (adapted to the existing point economy where a full exercise
  /// historically granted ~10-25 points):
  /// * score >= 90 -> 1.0  (strong gain)
  /// * score >= 75 -> 0.7  (moderate gain)
  /// * score >= 60 -> 0.45 (small gain)
  /// * score < 60  -> 0.2  (minimal gain; completion still counts)
  static double skillGainMultiplier(double performanceScore) {
    final s = clampScore(performanceScore);
    if (s >= 90) return 1.0;
    if (s >= 75) return 0.7;
    if (s >= 60) return 0.45;
    return 0.2;
  }

  /// Scales a base skill-point value by the performance tier, rounded to the
  /// nearest integer. A completed exercise always yields a small non-negative
  /// gain; poor performances simply gain much less than excellent ones.
  static int scaledGain(int basePoints, double performanceScore) {
    if (basePoints <= 0) return 0;
    return (basePoints * skillGainMultiplier(performanceScore)).round();
  }

  /// Bounded excellence XP bonus for a completion.
  static int excellenceBonusXp(double performanceScore) =>
      clampScore(performanceScore) >= excellenceThreshold
      ? excellenceXpBonus
      : 0;

  // ===========================================================================
  // OBSERVATION CHALLENGE
  // ===========================================================================
  //
  // Accuracy is genuinely meaningful here: correct answers / total questions.
  // Unanswered questions count as incorrect (completion/performance component:
  // a challenge is only recorded once every question was answered or skipped).
  //
  // performanceScore = 0.80 * accuracy + difficultyBonus
  //   * accuracy dominates (80% weight); speed is deliberately NOT a factor.
  //   * difficultyBonus: Easy 0, Medium 10, Hard 20 -> same accuracy on a
  //     harder memorization window produces a meaningfully higher score
  //     (e.g. 100% accuracy: Easy 80, Medium 90, Hard 100).

  /// Base secondary memory gain logged for analytics (scaled by performance).
  static const int observationBaseMemoryPoints = 10;

  static ExerciseScoreResult scoreObservationChallenge({
    required int totalQuestions,
    required int correctAnswers,
    required ObservationDifficulty difficulty,
    required int durationSeconds,
  }) {
    if (totalQuestions <= 0) {
      throw ArgumentError.value(
        totalQuestions,
        'totalQuestions',
        'must be greater than 0',
      );
    }
    if (correctAnswers < 0) {
      throw ArgumentError.value(
        correctAnswers,
        'correctAnswers',
        'must not be negative',
      );
    }
    if (durationSeconds < 0) {
      throw ArgumentError.value(
        durationSeconds,
        'durationSeconds',
        'must not be negative',
      );
    }

    final correct = _clampInt(correctAnswers, 0, totalQuestions);
    final accuracy = (correct / totalQuestions) * 100.0;

    final performance = clampScore(
      clampScore(accuracy) * 0.80 + difficulty.scoreBonus,
    );

    final xp =
        (observationBaseXp * difficulty.xpMultiplier).round() +
        excellenceBonusXp(performance);

    return ExerciseScoreResult(
      performanceScore: performance,
      accuracy: accuracy,
      xpEarned: xp,
      skillGainMultiplier: skillGainMultiplier(performance),
    );
  }

  // ===========================================================================
  // SEQUENCE MASTER
  // ===========================================================================
  //
  // Accuracy is genuinely meaningful here: correct sequences / total sequences.
  // Unanswered sequences count as incorrect when a timed session ends.
  //
  // performanceScore = 0.80 * accuracy + difficultyBonus
  //   * difficultyBonus: Easy 0, Medium 10, Hard 20. A perfect Easy run scores
  //     80, a perfect Medium run 90, and a perfect Hard run 100.
  //   * Speed is deliberately NOT part of the score. The per-question timer
  //     creates pressure, but a correct answer is a correct answer.
  //
  // Logic gain scales with performance. XP stays participation-based with the
  // same difficulty multipliers as Observation Challenge.

  /// Base secondary logic gain logged for analytics (scaled by performance).
  static const int sequenceMasterBaseLogicPoints = 20;

  static ExerciseScoreResult scoreSequenceMaster({
    required int totalQuestions,
    required int correctAnswers,
    required SequenceMasterDifficulty difficulty,
    required int durationSeconds,
  }) {
    if (totalQuestions <= 0) {
      throw ArgumentError.value(
        totalQuestions,
        'totalQuestions',
        'must be greater than 0',
      );
    }
    if (correctAnswers < 0) {
      throw ArgumentError.value(
        correctAnswers,
        'correctAnswers',
        'must not be negative',
      );
    }
    if (durationSeconds < 0) {
      throw ArgumentError.value(
        durationSeconds,
        'durationSeconds',
        'must not be negative',
      );
    }

    final correct = _clampInt(correctAnswers, 0, totalQuestions);
    final accuracy = (correct / totalQuestions) * 100.0;
    final performance = clampScore(
      clampScore(accuracy) * 0.80 + difficulty.scoreBonus,
    );
    final xp =
        (sequenceMasterBaseXp * difficulty.xpMultiplier).round() +
        excellenceBonusXp(performance);

    return ExerciseScoreResult(
      performanceScore: performance,
      accuracy: accuracy,
      xpEarned: xp,
      skillGainMultiplier: skillGainMultiplier(performance),
    );
  }

  // ===========================================================================
  // SPOT THE DIFFERENCE
  // ===========================================================================
  //
  // Accuracy = discoveredDifferences / (discoveredDifferences + incorrectTaps) * 100.
  // Completion ratio = discoveredDifferences / totalDifferences * 100.
  //
  // performanceScore = 0.70 * completionRatio + 0.15 * accuracy + difficulty.scoreBonus
  //   * Easy (+0): perfect run scores 85.
  //   * Medium (+10): perfect run scores 95.
  //   * Hard (+20): perfect run scores 100 (clamped).
  //
  // Observation points scale with performance. XP rewards are participation-based
  // with difficulty multipliers and excellence bonus.

  /// Base secondary observation gain logged for analytics (scaled by performance).
  static const int spotTheDifferenceBaseObservationPoints = 15;

  static ExerciseScoreResult scoreSpotTheDifference({
    required int totalDifferences,
    required int discoveredDifferences,
    required int incorrectTaps,
    required SpotDifferenceDifficulty difficulty,
    required int durationSeconds,
  }) {
    if (totalDifferences <= 0) {
      throw ArgumentError.value(
        totalDifferences,
        'totalDifferences',
        'must be greater than 0',
      );
    }
    if (discoveredDifferences < 0) {
      throw ArgumentError.value(
        discoveredDifferences,
        'discoveredDifferences',
        'must not be negative',
      );
    }
    if (incorrectTaps < 0) {
      throw ArgumentError.value(
        incorrectTaps,
        'incorrectTaps',
        'must not be negative',
      );
    }
    if (durationSeconds < 0) {
      throw ArgumentError.value(
        durationSeconds,
        'durationSeconds',
        'must not be negative',
      );
    }

    final discovered = _clampInt(discoveredDifferences, 0, totalDifferences);
    final totalTaps = discovered + incorrectTaps;
    final double accuracy = totalTaps == 0
        ? 0.0
        : (discovered / totalTaps) * 100.0;
    final double completionRatio = (discovered / totalDifferences) * 100.0;

    final performance = clampScore(
      0.70 * completionRatio + 0.15 * accuracy + difficulty.scoreBonus,
    );

    final xp =
        (spotTheDifferenceBaseXp * difficulty.xpMultiplier).round() +
        excellenceBonusXp(performance);

    return ExerciseScoreResult(
      performanceScore: performance,
      accuracy: accuracy,
      xpEarned: xp,
      skillGainMultiplier: skillGainMultiplier(performance),
    );
  }

  // ===========================================================================
  // STORY BUILDER
  // ===========================================================================
  //
  // Deterministic scoring from measurable properties of the submitted text.
  // No AI evaluation, no arbitrary writing-quality judgments.
  //
  // Components (weights sum to 1.0):
  //   * Length depth (40%): wordCount / targetWordCount, clamped to 0-1.
  //   * Vocabulary richness (35%): type-token ratio (unique words / total
  //     words) normalized from the [0.4, 1.0] band to [0, 1].
  //   * Required-word integration (25%): required words actually used.
  //
  // Accuracy = required-word coverage (%). The UI submission gate requires
  // all required words and the minimum word count, so a *submitted* story
  // always has 100% coverage; the value remains meaningful (constraint
  // compliance) and the performance score carries the differentiation.

  /// Word count at which the length-depth component reaches full marks.
  static const int storyTargetWordCount = 80;
  static const double storyLengthWeight = 0.40;
  static const double storyVocabularyWeight = 0.35;
  static const double storyRequiredWordWeight = 0.25;

  /// Lower type-token ratio considered "poor" vocabulary variety.
  static const double _vocabularyFloor = 0.4;

  /// Type-token ratio considered "excellent" vocabulary variety.
  static const double _vocabularyCeiling = 1.0;

  /// Base secondary memory/recall gain logged for analytics.
  static const int storyBaseMemoryPoints = 10;

  static List<String> _tokenize(String text) {
    final clean = text.toLowerCase().replaceAll(
      RegExp(r'[^\p{L}\p{N}\s]', unicode: true),
      ' ',
    );
    return clean.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  }

  static ExerciseScoreResult scoreStoryBuilder({
    required String storyText,
    required List<String> requiredWords,
    required int minWordCount,
    int targetWordCount = storyTargetWordCount,
  }) {
    if (minWordCount <= 0) {
      throw ArgumentError.value(
        minWordCount,
        'minWordCount',
        'must be greater than 0',
      );
    }
    if (targetWordCount <= 0) {
      throw ArgumentError.value(
        targetWordCount,
        'targetWordCount',
        'must be greater than 0',
      );
    }
    if (requiredWords.isEmpty) {
      throw ArgumentError.value(
        requiredWords,
        'requiredWords',
        'must not be empty',
      );
    }

    final words = StoryModel.countWords(storyText);
    final missing = StoryModel.getMissingWords(storyText, requiredWords);
    final usedRequired = requiredWords.length - missing.length;

    // Length depth relative to the stretch target.
    final lengthDepth = (words / targetWordCount).clamp(0.0, 1.0).toDouble();

    // Vocabulary richness via type-token ratio.
    double vocabularyRichness = 0.0;
    if (words > 0) {
      final tokens = _tokenize(storyText);
      if (tokens.isNotEmpty) {
        final ttr = tokens.toSet().length / tokens.length;
        final span = _vocabularyCeiling - _vocabularyFloor;
        vocabularyRichness = ((ttr - _vocabularyFloor) / span)
            .clamp(0.0, 1.0)
            .toDouble();
      }
    }

    // Required-word integration.
    final requiredIntegration = (usedRequired / requiredWords.length)
        .clamp(0.0, 1.0)
        .toDouble();

    final performance = clampScore(
      100.0 *
          (storyLengthWeight * lengthDepth +
              storyVocabularyWeight * vocabularyRichness +
              storyRequiredWordWeight * requiredIntegration),
    );

    final accuracy = clampScore((usedRequired / requiredWords.length) * 100.0);

    final xp = storyBuilderBaseXp + excellenceBonusXp(performance);

    return ExerciseScoreResult(
      performanceScore: performance,
      accuracy: accuracy,
      xpEarned: xp,
      skillGainMultiplier: skillGainMultiplier(performance),
    );
  }

  // ===========================================================================
  // SCENARIO LAB
  // ===========================================================================
  //
  // HONEST LIMITATION (documented): every scenario is a balanced trade-off
  // dilemma whose options all carry explicit strengths AND weaknesses. There
  // is no objectively correct decision and no defensible quality ranking of
  // the options, so decision "accuracy" does not exist for this exercise.
  //
  // Instead the exercise exposes a 0-100 *deliberation engagement* score:
  // the measured deliberation time relative to the estimated time needed to
  // read the scenario material (200 words/minute standard reading speed,
  // floored at 10 seconds, deliberation capped at 30 minutes). Confirming a
  // decision without engaging with the material yields a low score; a fully
  // read scenario yields 100. Slow readers are never penalized (ratio caps
  // at 1.0). Known limitation: idle/AFK time also counts as deliberation.

  static const double scenarioReadingWordsPerMinute = 200.0;
  static const int scenarioMinReadingSeconds = 10;
  static const int scenarioMaxDeliberationSeconds = 1800;

  /// Estimated seconds needed to read [wordCount] words at standard reading
  /// speed, floored at [scenarioMinReadingSeconds].
  static int estimatedReadingSeconds(int wordCount) {
    if (wordCount <= 0) return scenarioMinReadingSeconds;
    final estimated = (wordCount / scenarioReadingWordsPerMinute * 60.0).ceil();
    return estimated < scenarioMinReadingSeconds
        ? scenarioMinReadingSeconds
        : estimated;
  }

  static ExerciseScoreResult scoreScenarioLab({
    required int scenarioWordCount,
    required int deliberationSeconds,
  }) {
    if (scenarioWordCount < 0) {
      throw ArgumentError.value(
        scenarioWordCount,
        'scenarioWordCount',
        'must not be negative',
      );
    }
    if (deliberationSeconds < 0) {
      throw ArgumentError.value(
        deliberationSeconds,
        'deliberationSeconds',
        'must not be negative',
      );
    }

    final capped = _clampInt(
      deliberationSeconds,
      0,
      scenarioMaxDeliberationSeconds,
    );
    final minimum = estimatedReadingSeconds(scenarioWordCount);
    final ratio = (capped / minimum).clamp(0.0, 1.0).toDouble();
    final performance = clampScore(100.0 * ratio);

    final xp = scenarioLabBaseXp + excellenceBonusXp(performance);

    return ExerciseScoreResult(
      performanceScore: performance,
      accuracy: null, // Accuracy does not apply to balanced trade-off dilemmas.
      xpEarned: xp,
      skillGainMultiplier: skillGainMultiplier(performance),
    );
  }

  // ===========================================================================
  // DEBATE ARENA
  // ===========================================================================
  //
  // Completing a debate is NOT equivalent to making a high-quality argument,
  // so the score has two layers:
  //
  // 1. Deterministic layer (always available, objective):
  //    * Participation (up to 60 pts): userTurns / maxTurns * 60.
  //    * Substance (up to 40 pts): total argument words relative to a target
  //      of 40 words per turn, each argument capped at 400 words so a single
  //      pasted wall of text cannot dominate.
  //    This layer measures engagement, not argument quality.
  //
  // 2. Optional AI quality evaluation (only when the existing OpenRouter
  //    integration succeeds): a strict 0-100 rubric scored from the user's
  //    actual arguments:
  //      relevance 0-40 + reasoning 0-40 + engagement-with-opponent 0-20.
  //    Final = 0.6 * deterministic + 0.4 * AI. Any API/parse failure falls
  //    back to the deterministic score and never blocks completion.
  //
  // Accuracy does not apply: debate arguments have no binary correct answer.

  static const int debateParticipationPoints = 60;
  static const int debateSubstancePoints = 40;
  static const int debateWordsPerTurnTarget = 40;
  static const int debateMaxWordsPerArgument = 400;

  /// AI evaluation rubric maximum values.
  static const int debateAiRelevanceMax = 40;
  static const int debateAiReasoningMax = 40;
  static const int debateAiEngagementMax = 20;

  static ExerciseScoreResult scoreDebateDeterministic({
    required int userTurns,
    required int maxTurns,
    required List<int> argumentWordCounts,
  }) {
    if (maxTurns <= 0) {
      throw ArgumentError.value(maxTurns, 'maxTurns', 'must be greater than 0');
    }
    if (userTurns < 0) {
      throw ArgumentError.value(userTurns, 'userTurns', 'must not be negative');
    }
    if (argumentWordCounts.any((c) => c < 0)) {
      throw ArgumentError.value(
        argumentWordCounts,
        'argumentWordCounts',
        'must not be negative',
      );
    }

    final turns = _clampInt(userTurns, 0, maxTurns);
    final participation = turns / maxTurns * debateParticipationPoints;

    final totalWords = argumentWordCounts
        .map((c) => _clampInt(c, 0, debateMaxWordsPerArgument))
        .fold<int>(0, (sum, c) => sum + c);
    final substanceTarget = maxTurns * debateWordsPerTurnTarget;
    final substance =
        (totalWords / substanceTarget).clamp(0.0, 1.0).toDouble() *
        debateSubstancePoints;

    final performance = clampScore(participation + substance);
    final xp = debateArenaBaseXp + excellenceBonusXp(performance);

    return ExerciseScoreResult(
      performanceScore: performance,
      accuracy: null, // Arguments have no binary correct answer.
      xpEarned: xp,
      skillGainMultiplier: skillGainMultiplier(performance),
    );
  }

  /// Parses an AI debate evaluation response into a 0-100 rubric score.
  ///
  /// Safely extracts the first JSON object even if the model wraps it in
  /// prose or markdown fences. Returns `null` on ANY structural problem,
  /// missing field, or non-numeric value so callers can fall back to the
  /// deterministic score. Out-of-range rubric values are clamped.
  static int? parseDebateAiEvaluation(String rawResponse) {
    final start = rawResponse.indexOf('{');
    final end = rawResponse.lastIndexOf('}');
    if (start < 0 || end <= start) return null;

    final Map<String, dynamic>? decoded;
    try {
      final obj = jsonDecode(rawResponse.substring(start, end + 1));
      decoded = obj is Map<String, dynamic> ? obj : null;
    } catch (_) {
      return null;
    }
    if (decoded == null) return null;

    final relevance = _rubricValue(decoded['relevance'], debateAiRelevanceMax);
    final reasoning = _rubricValue(decoded['reasoning'], debateAiReasoningMax);
    final engagement = _rubricValue(
      decoded['engagement'],
      debateAiEngagementMax,
    );
    if (relevance == null || reasoning == null || engagement == null) {
      return null;
    }
    return relevance + reasoning + engagement;
  }

  static int? _rubricValue(dynamic value, int maxValue) {
    int? parsed;
    if (value is int) {
      parsed = value;
    } else if (value is num) {
      parsed = value.toInt();
    } else if (value is String) {
      parsed = int.tryParse(value.trim());
    }
    if (parsed == null) return null;
    return _clampInt(parsed, 0, maxValue);
  }

  /// Combines the deterministic debate score with an optional AI evaluation
  /// score. Without an AI score the deterministic score is used unchanged.
  static int combineDebateScores(
    int deterministicScore,
    int? aiEvaluationScore,
  ) {
    final det = _clampInt(deterministicScore, 0, 100);
    if (aiEvaluationScore == null) return det;
    final ai = _clampInt(aiEvaluationScore, 0, 100);
    return (det * 0.6 + ai * 0.4).round();
  }
}
