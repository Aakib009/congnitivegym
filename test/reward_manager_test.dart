import 'package:flutter/services.dart';
import 'package:cognitive_gym/services/progress_service.dart';
import 'package:cognitive_gym/services/reward_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RewardManager & Point System Unit Tests', () {
    setUp(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global'),
        (MethodCall methodCall) async => null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'),
        (MethodCall methodCall) async => null,
      );
      SharedPreferences.setMockInitialValues({});
      await ProgressService.instance.init();
      await ProgressService.instance.resetProgress();
      await RewardManager.instance.init();
    });

    test('awardLesson awards points and enforces anti-exploitation daily repetition rules',
        () async {
      final initialPts = RewardManager.instance.userProfile.totalXp;
      expect(initialPts, 0);

      // First completion of lesson_1 today
      final ptsEarned = await RewardManager.instance.awardLesson(
        lessonId: 'lesson_1',
        isPerfect: true,
        isFirstAttempt: true,
      );

      // Complete lesson (20) + Perfect (10) + First attempt (15) + Day 1 streak (10) = 55 pts + First lesson achievement (50) + First perfect achievement (100)
      expect(ptsEarned, greaterThanOrEqualTo(45));
      expect(RewardManager.instance.userProfile.totalLessonsCompleted, 1);

      // Repeating same lesson on same day awards 0 points (Anti-Exploitation)
      final repeatPts = await RewardManager.instance.awardLesson(
        lessonId: 'lesson_1',
      );
      expect(repeatPts, 0);
      expect(RewardManager.instance.userProfile.totalLessonsCompleted, 1);
    });

    test('awardQuiz awards points according to score percentage', () async {
      final pts = await RewardManager.instance.awardQuiz(
        quizId: 'quiz_101',
        scorePercentage: 100,
        beatPreviousBest: true,
      );

      // Quiz (30) + Score > 80 (15) + Score 100 (25) + Beat best (10) + Streak (10) = 90 pts
      expect(pts, greaterThanOrEqualTo(80));
      expect(RewardManager.instance.userProfile.totalQuizzesCompleted, 1);
    });

    test('awardVocabulary awards points per word learned and triggers milestones',
        () async {
      final pts = await RewardManager.instance.awardVocabulary(
        newWords: 10,
        reviewedWords: 5,
        masteredWords: 2,
      );

      // 10*2 + 5*3 + 2*10 + 25 bonus = 75 pts + streak
      expect(pts, greaterThanOrEqualTo(75));
      expect(RewardManager.instance.userProfile.totalWordsLearned, 10);
    });

    test('Emits LevelUpEvent when crossing stage thresholds', () async {
      LevelUpEvent? receivedEvent;
      final subscription = RewardManager.instance.onLevelUp.listen((event) {
        receivedEvent = event;
      });

      // Award enough vocabulary/quiz points to cross Stage 2 threshold (150 pts)
      await RewardManager.instance.awardQuiz(
        quizId: 'q1',
        scorePercentage: 100,
      );
      await RewardManager.instance.awardQuiz(
        quizId: 'q2',
        scorePercentage: 100,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(receivedEvent, isNotNull);
      expect(receivedEvent!.newLevel, greaterThanOrEqualTo(2));

      await subscription.cancel();
    });
  });
}
