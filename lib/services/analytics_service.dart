import 'package:flutter/foundation.dart';
import '../models/analytics_event.dart';
import '../models/cognitive_analytics_model.dart';
import 'analytics_repository.dart';
import 'auth_service.dart';
import 'progress_service.dart';

enum AnalyticsStatus { idle, loading, loaded, error }

/// Production service extending ChangeNotifier for state management.
/// Aggregates database events and computes cognitive metrics, trends, and insights.
class AnalyticsService extends ChangeNotifier {
  AnalyticsService._({AnalyticsRepository? repository})
    : _repository = repository ?? AnalyticsRepository();

  static final AnalyticsService instance = AnalyticsService._();

  final AnalyticsRepository _repository;

  AnalyticsStatus _status = AnalyticsStatus.idle;
  AnalyticsTimeRange _selectedTimeRange = AnalyticsTimeRange.sevenDays;
  CognitiveAnalyticsData _analyticsData = CognitiveAnalyticsData.empty(
    AnalyticsTimeRange.sevenDays,
  );
  String? _errorMessage;

  // Active user account ID helper for strict account data isolation
  String get activeUserId {
    final authUser = AuthService.instance.currentUser;
    if (authUser != null && authUser.id.isNotEmpty) {
      return authUser.id;
    }
    return 'default_user';
  }

  // Getters
  AnalyticsStatus get status => _status;
  AnalyticsTimeRange get selectedTimeRange => _selectedTimeRange;
  CognitiveAnalyticsData get analyticsData => _analyticsData;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AnalyticsStatus.loading;
  bool get hasData =>
      _status == AnalyticsStatus.loaded && !_analyticsData.isEmpty;

  /// Resets in-memory analytics data upon user logout.
  void resetOnLogout() {
    _analyticsData = CognitiveAnalyticsData.empty(AnalyticsTimeRange.sevenDays);
    _status = AnalyticsStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }

  /// Loads aggregated analytics for the active user for selected or specified time range.
  Future<void> loadAnalytics({
    AnalyticsTimeRange? timeRange,
    String? userId,
  }) async {
    if (timeRange != null) {
      _selectedTimeRange = timeRange;
    }

    _status = AnalyticsStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      DateTime? startDate;

      switch (_selectedTimeRange) {
        case AnalyticsTimeRange.sevenDays:
          final d = now.subtract(const Duration(days: 7));
          startDate = DateTime(d.year, d.month, d.day);
          break;
        case AnalyticsTimeRange.thirtyDays:
          final d = now.subtract(const Duration(days: 30));
          startDate = DateTime(d.year, d.month, d.day);
          break;
        case AnalyticsTimeRange.allTime:
          startDate = null;
          break;
      }

      final targetUserId = userId ?? activeUserId;

      // 1. Fetch raw events from repository filtered strictly by active user ID
      final events = await _repository.getEvents(
        userId: targetUserId,
        startDate: startDate,
      );

      // 2. Compute metrics
      _analyticsData = _computeAnalyticsData(_selectedTimeRange, events);
      _status = AnalyticsStatus.loaded;
    } catch (e, stack) {
      debugPrint('[AnalyticsService] Error loading analytics: $e\n$stack');
      _status = AnalyticsStatus.error;
      _errorMessage = 'Failed to load cognitive analytics: ${e.toString()}';
    }

    notifyListeners();
  }

  /// Updates current time range filter and reloads analytics.
  Future<void> setTimeRange(AnalyticsTimeRange timeRange) async {
    if (_selectedTimeRange == timeRange && _status == AnalyticsStatus.loaded) {
      return;
    }
    await loadAnalytics(timeRange: timeRange);
  }

  /// Records an exercise completion event in SQLite for active user and updates active analytics.
  ///
  /// [score] and [accuracy] are normalized 0.0-1.0 values derived from the
  /// real exercise performance (see ExerciseScoringService). There are no
  /// fake defaults: callers must pass the actual measured values, and
  /// [accuracy] must be left null for exercises where accuracy is not a
  /// meaningful concept (e.g. Debate Arena, Scenario Lab).
  Future<void> logExerciseCompletion({
    required String exerciseType,
    required int xpEarned,
    required double score,
    double? accuracy,
    required int durationSeconds,
    int criticalThinkingDelta = 0,
    int memoryDelta = 0,
    int creativityDelta = 0,
    int observationDelta = 0,
    int logicDelta = 0,
    int decisionMakingDelta = 0,
    int knowledgeDelta = 0,
    String? userId,
    String? eventId,
  }) async {
    final event = AnalyticsEvent(
      id:
          eventId ??
          'event_${DateTime.now().millisecondsSinceEpoch}_$exerciseType',
      userId: userId ?? activeUserId,
      exerciseType: exerciseType,
      timestamp: DateTime.now(),
      xpEarned: xpEarned,
      score: score,
      accuracy: accuracy,
      durationSeconds: durationSeconds,
      criticalThinkingDelta: criticalThinkingDelta > 0
          ? criticalThinkingDelta
          : logicDelta,
      memoryDelta: memoryDelta > 0 ? memoryDelta : knowledgeDelta,
      creativityDelta: creativityDelta,
      observationDelta: observationDelta,
      logicDelta: logicDelta,
      decisionMakingDelta: decisionMakingDelta,
      knowledgeDelta: knowledgeDelta,
    );

    await _repository.logEvent(event);
    await loadAnalytics();
  }

  /// Internal deterministic aggregation engine.
  CognitiveAnalyticsData _computeAnalyticsData(
    AnalyticsTimeRange timeRange,
    List<AnalyticsEvent> events,
  ) {
    final userProfile = ProgressService.instance.userProfile;
    final now = DateTime.now();

    int totalXp = 0;
    double scoreSum = 0.0;
    double accuracySum = 0.0;
    int accuracyEventCount = 0;
    int totalDurationSecs = 0;

    int storyCount = 0;
    int obsCount = 0;
    int sequenceCount = 0;
    int spotCount = 0;
    int scenarioCount = 0;
    int debateCount = 0;

    int eventCriticalThinking = 0;
    int eventMemory = 0;
    int eventObservation = 0;
    int eventCreativity = 0;
    int eventDecision = 0;

    final validEvents = <AnalyticsEvent>[];

    for (final e in events) {
      // Exclude future-dated edge records
      if (e.timestamp.isAfter(now)) continue;

      validEvents.add(e);
      totalXp += e.xpEarned;
      scoreSum += e.score;
      // Accuracy is averaged only over events where the metric genuinely
      // applies (non-null). Exercises without an accuracy concept are
      // excluded rather than counted as perfect scores.
      final eventAccuracy = e.accuracy;
      if (eventAccuracy != null) {
        accuracySum += eventAccuracy;
        accuracyEventCount++;
      }
      totalDurationSecs += e.durationSeconds;

      eventCriticalThinking += (e.criticalThinkingDelta > 0
          ? e.criticalThinkingDelta
          : e.logicDelta);
      eventMemory += (e.memoryDelta > 0 ? e.memoryDelta : e.knowledgeDelta);
      eventObservation += e.observationDelta;
      eventCreativity += e.creativityDelta;
      eventDecision += e.decisionMakingDelta;

      switch (e.exerciseType) {
        case 'story_builder':
          storyCount++;
          break;
        case 'observation_challenge':
          obsCount++;
          break;
        case 'sequence_master':
          sequenceCount++;
          break;
        case 'spot_the_difference':
          spotCount++;
          break;
        case 'scenario_lab':
          scenarioCount++;
          break;
        case 'debate_arena':
          debateCount++;
          break;
        default:
          break;
      }
    }

    final totalCompleted = validEvents.length;

    // Fallback if no database events exist yet: use user profile cumulative metrics
    final isFallback = totalCompleted == 0;

    final effectiveTotalXp = isFallback ? userProfile.totalXp : totalXp;
    final effectiveTotalCompleted = isFallback
        ? userProfile.totalExercisesCompleted
        : totalCompleted;
    // Derived skill metrics (0-100 scale)
    double calcSkillScore(int profilePoints, int eventPoints) {
      if (effectiveTotalCompleted == 0) return 0.0;
      // When database events exist, aggregate directly from event deltas.
      // Fallback to user profile points only if no database events exist yet.
      final raw =
          (isFallback
                  ? profilePoints
                  : (eventPoints > 0 ? eventPoints : profilePoints))
              .toDouble();
      if (raw <= 0) return 0.0;
      // Scale points cleanly into a 0-100 score threshold (150 pts = 100% score)
      final score = (raw / 150.0) * 100.0;
      return score.clamp(0.0, 100.0);
    }

    final skillMetrics = SkillMetrics(
      criticalThinking: calcSkillScore(
        userProfile.logicPoints,
        eventCriticalThinking,
      ),
      memory: calcSkillScore(
        (userProfile.observationPoints + userProfile.knowledgePoints) ~/ 2,
        eventMemory,
      ),
      observation: calcSkillScore(
        userProfile.observationPoints,
        eventObservation,
      ),
      creativity: calcSkillScore(userProfile.creativityPoints, eventCreativity),
      decisionMaking: calcSkillScore(
        userProfile.decisionMakingPoints,
        eventDecision,
      ),
    );

    // Compute XP trend timeline points over days
    final xpTrend = _generateXpTrend(timeRange, validEvents);

    // Exercise breakdown
    final exerciseBreakdown = ExerciseCountBreakdown(
      storyBuilder: storyCount,
      observationChallenge: obsCount,
      sequenceMaster: sequenceCount,
      spotTheDifference: spotCount,
      scenarioLab: scenarioCount,
      debateArena: debateCount,
    );

    // Real computed averages only. No fabricated placeholder values: when no
    // scored events exist the averages are 0.0 and the UI shows the empty
    // state. averageAccuracy covers only events with a meaningful accuracy
    // metric (see aggregation above). Clamped to [0.0, 1.0] to prevent overflow.
    final avgScore = totalCompleted > 0
        ? (scoreSum / totalCompleted).clamp(0.0, 1.0)
        : 0.0;
    final avgAccuracy = accuracyEventCount > 0
        ? (accuracySum / accuracyEventCount).clamp(0.0, 1.0)
        : 0.0;
    final durationMins = totalDurationSecs ~/ 60;

    // Deterministic Insights
    final skillsMap = {
      'Critical Thinking': skillMetrics.criticalThinking,
      'Memory': skillMetrics.memory,
      'Observation': skillMetrics.observation,
      'Creativity': skillMetrics.creativity,
      'Decision Making': skillMetrics.decisionMaking,
    };

    final sortedSkills = skillsMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final strongest = sortedSkills.first.value > 0
        ? sortedSkills.first.key
        : 'None';
    final weakest = sortedSkills.last.value > 0
        ? sortedSkills.last.key
        : 'None';

    final exercisesMap = {
      'Story Builder': storyCount,
      'Observation Challenge': obsCount,
      'Sequence Master': sequenceCount,
      'Scenario Lab': scenarioCount,
      'Debate Arena': debateCount,
    };
    final sortedExercises = exercisesMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topExercise = sortedExercises.first.value > 0
        ? sortedExercises.first.key
        : 'None';

    String recommendation;
    if (effectiveTotalCompleted == 0) {
      recommendation =
          'Complete your first exercise to unlock personalized cognitive analytics.';
    } else if (effectiveTotalCompleted < 3) {
      final needed = 3 - effectiveTotalCompleted;
      recommendation =
          'Complete $needed more exercise${needed == 1 ? '' : 's'} to establish high-confidence cognitive analytics.';
    } else {
      switch (weakest) {
        case 'Observation':
          recommendation =
              'Focus on the Observation Challenge to sharpen visual attention and memory recall.';
          break;
        case 'Creativity':
          recommendation =
              'Spend time in Story Builder to expand creative word synthesis and narrative flow.';
          break;
        case 'Critical Thinking':
          recommendation =
              'Engage in the Debate Arena or Sequence Master to sharpen logical analysis and pattern recognition.';
          break;
        case 'Decision Making':
          recommendation =
              'Practice in Scenario Lab to build sound tactical decision-making strategies.';
          break;
        case 'Memory':
          recommendation =
              'Combine Observation and Story exercises to build associative spatial memory.';
          break;
        default:
          recommendation =
              'Maintain balanced cognitive training across all five interactive modules.';
      }
    }

    return CognitiveAnalyticsData(
      timeRange: timeRange,
      rawEvents: validEvents,
      skillMetrics: skillMetrics,
      xpTrend: xpTrend,
      exerciseBreakdown: exerciseBreakdown,
      totalXpEarned: effectiveTotalXp,
      totalExercisesCompleted: effectiveTotalCompleted,
      averageScore: avgScore,
      averageAccuracy: avgAccuracy,
      totalDurationMinutes: durationMins,
      strongestSkill: strongest,
      weakestSkill: weakest,
      mostPracticedExercise: topExercise,
      performanceRecommendation: recommendation,
    );
  }

  /// Groups events into day-by-day XP trend points for line chart.
  List<XpTrendPoint> _generateXpTrend(
    AnalyticsTimeRange timeRange,
    List<AnalyticsEvent> events,
  ) {
    final now = DateTime.now();
    final int daysCount = timeRange == AnalyticsTimeRange.sevenDays ? 7 : 30;
    final List<XpTrendPoint> points = [];

    final Map<String, int> dailyXpMap = {};
    for (final e in events) {
      if (e.timestamp.isAfter(now)) continue;
      final dateKey =
          '${e.timestamp.year}-${e.timestamp.month.toString().padLeft(2, '0')}-${e.timestamp.day.toString().padLeft(2, '0')}';
      dailyXpMap[dateKey] = (dailyXpMap[dateKey] ?? 0) + e.xpEarned;
    }

    for (int i = daysCount - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final xp = dailyXpMap[dateKey] ?? 0;
      points.add(XpTrendPoint(date: date, xpEarned: xp));
    }

    return points;
  }
}
