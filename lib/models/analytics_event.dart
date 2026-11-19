import 'dart:convert';

/// Model representing an individual exercise performance event recorded in SQLite.
///
/// Normalization convention (0-100 scores exposed by ExerciseScoringService
/// are divided by 100 before being stored here):
/// * [score] is the normalized 0.0-1.0 performance score for the completion.
/// * [accuracy] is the normalized 0.0-1.0 accuracy WHEN the exercise has a
///   genuinely meaningful accuracy concept (Observation Challenge: correct
///   answers / questions; Story Builder: required-word coverage). For
///   exercises where accuracy does not apply (Debate Arena arguments and
///   Scenario Lab trade-off dilemmas have no correct answer) it is `null`
///   and the analytics layer excludes the event from accuracy averages
///   instead of pretending the metric exists.
class AnalyticsEvent {
  final String id;
  final String userId;
  final String
  exerciseType; // 'story_builder', 'observation_challenge', 'sequence_master', 'scenario_lab', 'debate_arena'
  final DateTime timestamp;
  final int xpEarned;
  final double score; // 0.0 to 1.0
  final double? accuracy; // 0.0 to 1.0; null = metric not applicable
  final int durationSeconds;
  final int criticalThinkingDelta;
  final int memoryDelta;
  final int observationDelta;
  final int creativityDelta;
  final int decisionMakingDelta;
  final int logicDelta;
  final int knowledgeDelta;

  const AnalyticsEvent({
    required this.id,
    required this.userId,
    required this.exerciseType,
    required this.timestamp,
    required this.xpEarned,
    required this.score,
    this.accuracy,
    this.durationSeconds = 60,
    this.criticalThinkingDelta = 0,
    this.memoryDelta = 0,
    this.observationDelta = 0,
    this.creativityDelta = 0,
    this.decisionMakingDelta = 0,
    this.logicDelta = 0,
    this.knowledgeDelta = 0,
  });

  /// Normalized 0-100 performance score for display.
  double get performanceScorePercent => score * 100.0;

  /// Normalized 0-100 accuracy for display, or null when not applicable.
  double? get accuracyPercent => accuracy == null ? null : accuracy! * 100.0;

  /// Factory constructor converting SQLite row map into AnalyticsEvent instance.
  factory AnalyticsEvent.fromMap(Map<String, dynamic> map) {
    final rawLogic = (map['logicDelta'] as int?) ?? 0;
    final rawKnowledge = (map['knowledgeDelta'] as int?) ?? 0;

    return AnalyticsEvent(
      id: (map['id'] as String?) ?? '',
      userId: (map['userId'] as String?) ?? 'default_user',
      exerciseType: (map['exerciseType'] as String?) ?? 'general',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      xpEarned: (map['xpEarned'] as int?) ?? 0,
      score: (map['score'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      durationSeconds: (map['durationSeconds'] as int?) ?? 60,
      criticalThinkingDelta: (map['criticalThinkingDelta'] as int?) ?? rawLogic,
      memoryDelta: (map['memoryDelta'] as int?) ?? rawKnowledge,
      observationDelta: (map['observationDelta'] as int?) ?? 0,
      creativityDelta: (map['creativityDelta'] as int?) ?? 0,
      decisionMakingDelta: (map['decisionMakingDelta'] as int?) ?? 0,
      logicDelta: rawLogic,
      knowledgeDelta: rawKnowledge,
    );
  }

  /// Converts AnalyticsEvent instance into SQLite row map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'exerciseType': exerciseType,
      'timestamp': timestamp.toIso8601String(),
      'xpEarned': xpEarned,
      'score': score,
      'accuracy': accuracy,
      'durationSeconds': durationSeconds,
      'criticalThinkingDelta': criticalThinkingDelta,
      'memoryDelta': memoryDelta,
      'observationDelta': observationDelta,
      'creativityDelta': creativityDelta,
      'decisionMakingDelta': decisionMakingDelta,
      'logicDelta': logicDelta,
      'knowledgeDelta': knowledgeDelta,
    };
  }

  String toJson() => json.encode(toMap());

  factory AnalyticsEvent.fromJson(String source) =>
      AnalyticsEvent.fromMap(json.decode(source));
}
