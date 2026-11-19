import 'analytics_event.dart';

/// Available time range filter options for analytics reporting.
enum AnalyticsTimeRange { sevenDays, thirtyDays, allTime }

/// Snapshot representation of a single day's cumulative XP.
class XpTrendPoint {
  final DateTime date;
  final int xpEarned;

  const XpTrendPoint({required this.date, required this.xpEarned});
}

/// Normalized 5-skill cognitive score balance (0 to 100 scale).
class SkillMetrics {
  final double criticalThinking; // Derived from Logic & Debate
  final double memory; // Derived from Observation & Story recall
  final double observation; // Derived from Observation Challenge
  final double creativity; // Derived from Story Builder
  final double decisionMaking; // Derived from Scenario Lab

  const SkillMetrics({
    required this.criticalThinking,
    required this.memory,
    required this.observation,
    required this.creativity,
    required this.decisionMaking,
  });

  factory SkillMetrics.empty() {
    return const SkillMetrics(
      criticalThinking: 0,
      memory: 0,
      observation: 0,
      creativity: 0,
      decisionMaking: 0,
    );
  }
}

/// Distribution counts across cognitive training modules.
class ExerciseCountBreakdown {
  final int storyBuilder;
  final int observationChallenge;
  final int sequenceMaster;
  final int spotTheDifference;
  final int scenarioLab;
  final int debateArena;

  const ExerciseCountBreakdown({
    required this.storyBuilder,
    required this.observationChallenge,
    this.sequenceMaster = 0,
    this.spotTheDifference = 0,
    required this.scenarioLab,
    required this.debateArena,
  });

  int get total =>
      storyBuilder +
      observationChallenge +
      sequenceMaster +
      spotTheDifference +
      scenarioLab +
      debateArena;

  factory ExerciseCountBreakdown.empty() {
    return const ExerciseCountBreakdown(
      storyBuilder: 0,
      observationChallenge: 0,
      sequenceMaster: 0,
      spotTheDifference: 0,
      scenarioLab: 0,
      debateArena: 0,
    );
  }
}

/// Aggregated dataset containing computed metrics, trend points, and insights.
class CognitiveAnalyticsData {
  final AnalyticsTimeRange timeRange;
  final List<AnalyticsEvent> rawEvents;
  final SkillMetrics skillMetrics;
  final List<XpTrendPoint> xpTrend;
  final ExerciseCountBreakdown exerciseBreakdown;
  final int totalXpEarned;
  final int totalExercisesCompleted;
  final double averageScore;
  final double averageAccuracy;
  final int totalDurationMinutes;
  final String strongestSkill;
  final String weakestSkill;
  final String mostPracticedExercise;
  final String performanceRecommendation;

  const CognitiveAnalyticsData({
    required this.timeRange,
    required this.rawEvents,
    required this.skillMetrics,
    required this.xpTrend,
    required this.exerciseBreakdown,
    required this.totalXpEarned,
    required this.totalExercisesCompleted,
    required this.averageScore,
    required this.averageAccuracy,
    required this.totalDurationMinutes,
    required this.strongestSkill,
    required this.weakestSkill,
    required this.mostPracticedExercise,
    required this.performanceRecommendation,
  });

  bool get isEmpty => totalExercisesCompleted == 0;

  /// Statistical confidence score (0.0 to 1.0) based on rolling exercise sample size.
  /// - 0 completions: 0.0
  /// - 1 completion: 0.35
  /// - 2 completions: 0.55
  /// - 3 completions: 0.75
  /// - 4 completions: 0.88
  /// - 5+ completions: 1.0 (fully stabilized rolling sample)
  double get sampleSizeConfidence {
    if (totalExercisesCompleted <= 0) return 0.0;
    if (totalExercisesCompleted == 1) return 0.35;
    if (totalExercisesCompleted == 2) return 0.55;
    if (totalExercisesCompleted == 3) return 0.75;
    if (totalExercisesCompleted == 4) return 0.88;
    return 1.0;
  }

  /// Whether the rolling sample size is sufficient for stable cognitive profiling (>= 3).
  bool get isSampleReliable => totalExercisesCompleted >= 3;

  factory CognitiveAnalyticsData.empty(AnalyticsTimeRange range) {
    return CognitiveAnalyticsData(
      timeRange: range,
      rawEvents: const [],
      skillMetrics: SkillMetrics.empty(),
      xpTrend: const [],
      exerciseBreakdown: ExerciseCountBreakdown.empty(),
      totalXpEarned: 0,
      totalExercisesCompleted: 0,
      averageScore: 0.0,
      averageAccuracy: 0.0,
      totalDurationMinutes: 0,
      strongestSkill: 'None',
      weakestSkill: 'None',
      mostPracticedExercise: 'None',
      performanceRecommendation:
          'Complete your first exercise to unlock personalized cognitive analytics.',
    );
  }
}
