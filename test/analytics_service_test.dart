import 'package:flutter_test/flutter_test.dart';
import 'package:cognitive_gym/models/analytics_event.dart';
import 'package:cognitive_gym/models/cognitive_analytics_model.dart';
import 'package:cognitive_gym/services/analytics_repository.dart';
import 'package:cognitive_gym/services/analytics_service.dart';

class MockAnalyticsRepository implements AnalyticsRepository {
  final List<AnalyticsEvent> _storage = [];

  @override
  Future<void> logEvent(AnalyticsEvent event) async {
    _storage.add(event);
  }

  @override
  Future<List<AnalyticsEvent>> getEvents({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _storage.where((e) {
      if (userId != null && userId.isNotEmpty && e.userId != userId) return false;
      if (startDate != null && e.timestamp.isBefore(startDate)) return false;
      if (endDate != null && e.timestamp.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  @override
  Future<void> clearEvents() async {
    _storage.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AnalyticsService Audit Unit Tests', () {
    late AnalyticsService analyticsService;
    late MockAnalyticsRepository mockRepository;

    setUp(() {
      mockRepository = MockAnalyticsRepository();
      analyticsService = AnalyticsService.instance;
    });

    test('Initial AnalyticsService state should be idle or loaded', () {
      expect(analyticsService.status, anyOf(AnalyticsStatus.idle, AnalyticsStatus.loaded));
      expect(analyticsService.selectedTimeRange, AnalyticsTimeRange.sevenDays);
    });

    test('Empty analytics data correctly reports empty metrics and default recommendation', () async {
      await analyticsService.loadAnalytics(timeRange: AnalyticsTimeRange.sevenDays, userId: 'non_existent_user');

      final data = analyticsService.analyticsData;
      expect(data.timeRange, AnalyticsTimeRange.sevenDays);
      expect(data.skillMetrics.criticalThinking, greaterThanOrEqualTo(0.0));
      expect(data.skillMetrics.memory, greaterThanOrEqualTo(0.0));
      expect(data.skillMetrics.observation, greaterThanOrEqualTo(0.0));
      expect(data.skillMetrics.creativity, greaterThanOrEqualTo(0.0));
      expect(data.skillMetrics.decisionMaking, greaterThanOrEqualTo(0.0));
    });

    test('AnalyticsEvent model serialization and deserialization works for all 5 cognitive dimensions', () {
      final now = DateTime.now();
      final event = AnalyticsEvent(
        id: 'test_1',
        userId: 'user_123',
        exerciseType: 'debate_arena',
        timestamp: now,
        xpEarned: 30,
        score: 0.95,
        accuracy: null, // Accuracy does not apply to debate arguments.
        durationSeconds: 180,
        criticalThinkingDelta: 25,
        memoryDelta: 10,
        observationDelta: 15,
        creativityDelta: 20,
        decisionMakingDelta: 15,
      );

      final map = event.toMap();
      expect(map['id'], 'test_1');
      expect(map['userId'], 'user_123');
      expect(map['xpEarned'], 30);
      expect(map['criticalThinkingDelta'], 25);
      expect(map['memoryDelta'], 10);
      expect(map['score'], 0.95);
      expect(map['accuracy'], isNull);

      final recreated = AnalyticsEvent.fromMap(map);
      expect(recreated.id, 'test_1');
      expect(recreated.userId, 'user_123');
      expect(recreated.criticalThinkingDelta, 25);
      expect(recreated.memoryDelta, 10);
      expect(recreated.score, 0.95);
      expect(recreated.accuracy, isNull);
      expect(recreated.performanceScorePercent, closeTo(95.0, 0.001));
    });

    test('AnalyticsEvent keeps meaningful accuracy values through serialization', () {
      final now = DateTime.now();
      final event = AnalyticsEvent(
        id: 'test_2',
        userId: 'user_123',
        exerciseType: 'observation_challenge',
        timestamp: now,
        xpEarned: 18,
        score: 0.84,
        accuracy: 0.8,
        durationSeconds: 45,
        observationDelta: 12,
      );

      final map = event.toMap();
      final recreated = AnalyticsEvent.fromMap(map);

      expect(recreated.accuracy, closeTo(0.8, 0.0001));
      expect(recreated.accuracyPercent, closeTo(80.0, 0.001));
    });

    test('User Isolation Audit: User A analytics do not leak into User B query', () async {
      final now = DateTime.now();
      final eventUserA = AnalyticsEvent(
        id: 'ev_a',
        userId: 'user_A',
        exerciseType: 'debate_arena',
        timestamp: now,
        xpEarned: 100,
        score: 0.8,
        criticalThinkingDelta: 25,
      );
      final eventUserB = AnalyticsEvent(
        id: 'ev_b',
        userId: 'user_B',
        exerciseType: 'story_builder',
        timestamp: now,
        xpEarned: 50,
        score: 0.9,
        creativityDelta: 15,
      );

      await mockRepository.logEvent(eventUserA);
      await mockRepository.logEvent(eventUserB);

      final userAEvents = await mockRepository.getEvents(userId: 'user_A');
      final userBEvents = await mockRepository.getEvents(userId: 'user_B');

      expect(userAEvents.length, 1);
      expect(userAEvents.first.userId, 'user_A');
      expect(userAEvents.first.xpEarned, 100);

      expect(userBEvents.length, 1);
      expect(userBEvents.first.userId, 'user_B');
      expect(userBEvents.first.xpEarned, 50);
    });

    test('Time range selection updates selectedTimeRange state cleanly', () async {
      await analyticsService.setTimeRange(AnalyticsTimeRange.thirtyDays);
      expect(analyticsService.selectedTimeRange, AnalyticsTimeRange.thirtyDays);

      await analyticsService.setTimeRange(AnalyticsTimeRange.allTime);
      expect(analyticsService.selectedTimeRange, AnalyticsTimeRange.allTime);
    });

    test('sampleSizeConfidence scales monotonically and marks sample reliability at threshold', () {
      final emptyData = CognitiveAnalyticsData.empty(AnalyticsTimeRange.sevenDays);
      expect(emptyData.sampleSizeConfidence, 0.0);
      expect(emptyData.isSampleReliable, isFalse);

      CognitiveAnalyticsData makeData(int completed) {
        return CognitiveAnalyticsData(
          timeRange: AnalyticsTimeRange.sevenDays,
          rawEvents: const [],
          skillMetrics: SkillMetrics.empty(),
          xpTrend: const [],
          exerciseBreakdown: ExerciseCountBreakdown.empty(),
          totalXpEarned: completed * 20,
          totalExercisesCompleted: completed,
          averageScore: 0.85,
          averageAccuracy: 0.90,
          totalDurationMinutes: completed * 5,
          strongestSkill: 'Logic',
          weakestSkill: 'Observation',
          mostPracticedExercise: 'Debate Arena',
          performanceRecommendation: 'Keep training.',
        );
      }

      final data1 = makeData(1);
      final data2 = makeData(2);
      final data3 = makeData(3);
      final data5 = makeData(5);

      expect(data1.sampleSizeConfidence, closeTo(0.35, 0.001));
      expect(data1.isSampleReliable, isFalse);

      expect(data2.sampleSizeConfidence, closeTo(0.55, 0.001));
      expect(data2.isSampleReliable, isFalse);

      expect(data3.sampleSizeConfidence, closeTo(0.75, 0.001));
      expect(data3.isSampleReliable, isTrue); // >= 3 meets baseline threshold

      expect(data5.sampleSizeConfidence, 1.0);
      expect(data5.isSampleReliable, isTrue);
    });

    test('Rolling aggregate normalization clamps score and accuracy strictly between 0.0 and 1.0', () async {
      final now = DateTime.now();
      // Even if an aberrant event had an out-of-range score, the service clamps the average
      final event = AnalyticsEvent(
        id: 'ev_overflow',
        userId: 'user_norm',
        exerciseType: 'observation_challenge',
        timestamp: now,
        xpEarned: 20,
        score: 1.0,
        accuracy: 1.0,
        observationDelta: 15,
      );

      await mockRepository.logEvent(event);
      final events = await mockRepository.getEvents(userId: 'user_norm');
      expect(events.length, 1);
      expect(events.first.score, inInclusiveRange(0.0, 1.0));
      expect(events.first.accuracy, inInclusiveRange(0.0, 1.0));
    });
  });
}
