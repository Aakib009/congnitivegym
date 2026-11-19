import 'dart:async';
import 'package:flutter/foundation.dart';

import '../constants/reward_constants.dart';
import '../models/user_profile.dart';
import 'achievement_service.dart';
import 'mind_tree_service.dart';
import 'point_service.dart';
import 'progress_service.dart';
import 'streak_service.dart';
import 'sound_service.dart';

/// Event payload emitted when user advances to a new Mind Tree stage.
class LevelUpEvent {
  final int oldLevel;
  final int newLevel;
  final MindTreeStageInfo stageInfo;
  final bool isMasteryLevel10;

  const LevelUpEvent({
    required this.oldLevel,
    required this.newLevel,
    required this.stageInfo,
    required this.isMasteryLevel10,
  });
}

/// Central orchestrator facade for gamification, point rewards, streaks, achievements, and level-ups.
class RewardManager extends ChangeNotifier {
  RewardManager._();

  static final RewardManager instance = RewardManager._();

  final StreamController<LevelUpEvent> _levelUpController =
      StreamController<LevelUpEvent>.broadcast();

  /// Broadcast stream emitting events when the user levels up.
  Stream<LevelUpEvent> get onLevelUp => _levelUpController.stream;

  /// Initializes the RewardManager and underlying progress service.
  Future<void> init() async {
    await ProgressService.instance.init();
    await AchievementService.instance.init();
  }

  /// Current user profile from ProgressService.
  UserProfile get userProfile => ProgressService.instance.userProfile;

  /// Current Mind Tree Stage information derived from total points.
  MindTreeStageInfo get mindTreeStageInfo =>
      MindTreeService.instance.getStageInfo(userProfile.totalXp);

  // ===========================================================================
  // INTERNAL REWARD DISPATCHER WITH ANTI-EXPLOITATION & LEVEL-UP CHECKS
  // ===========================================================================
  Future<int> _awardPointsInternal({
    required int basePoints,
    required String sourceKey,
    int lessonsDelta = 0,
    int quizzesDelta = 0,
    int wordsDelta = 0,
    String? txId,
  }) async {
    // 1. Idempotency Check: Prevent duplicate point grants from retries/refreshes
    if (txId != null && txId.isNotEmpty) {
      final canProcess = await PointService.instance.canProcessTransaction(txId);
      if (!canProcess) {
        return 0; // Already processed
      }
      await PointService.instance.markTransactionProcessed(txId);
    }

    if (basePoints <= 0 &&
        lessonsDelta <= 0 &&
        quizzesDelta <= 0 &&
        wordsDelta <= 0) {
      return 0;
    }

    final oldTotalXp = userProfile.totalXp;
    final oldLevel = MindTreeService.instance.getLevelForPoints(oldTotalXp);

    // 2. Process daily streak bonus if activity occurred
    final streakResult = await StreakService.instance.recordDailyActivity();
    final totalRewardPoints = basePoints + streakResult.bonusPoints;

    // 3. Save updated progress to ProgressService
    await ProgressService.instance.recordCustomExerciseReward(
      creativity: sourceKey == 'lesson' ? totalRewardPoints : 0,
      observation: sourceKey == 'quiz' ? totalRewardPoints : 0,
      knowledge: sourceKey == 'vocabulary' ? totalRewardPoints : 0,
      xp: totalRewardPoints,
      exercisesCompleted: (lessonsDelta + quizzesDelta > 0 ? 1 : 0),
      lessons: lessonsDelta,
      quizzes: quizzesDelta,
      words: wordsDelta,
      currentStreak: streakResult.newStreak,
      bestStreak: streakResult.bestStreak,
      idempotencyKey: txId != null && txId.isNotEmpty ? 'tx_$txId' : null,
    );

    // Update local profile instance fields
    final newTotalXp = ProgressService.instance.userProfile.totalXp;
    final newLevel = MindTreeService.instance.getLevelForPoints(newTotalXp);
    final newStageInfo = MindTreeService.instance.getStageInfo(newTotalXp);

    if (totalRewardPoints > 0) {
      SoundService.instance.playRewardSuccess();
    }

    notifyListeners();

    // 4. Trigger Level Up Event if stage threshold passed
    if (newLevel > oldLevel) {
      _levelUpController.add(LevelUpEvent(
        oldLevel: oldLevel,
        newLevel: newLevel,
        stageInfo: newStageInfo,
        isMasteryLevel10: newLevel >= 10,
      ));
    }

    return totalRewardPoints;
  }

  // ===========================================================================
  // PUBLIC REWARD API
  // ===========================================================================

  /// Awards points for completing a lesson.
  /// Anti-Exploitation: Full points awarded only on first completion per day.
  Future<int> awardLesson({
    required String lessonId,
    bool isPerfect = false,
    bool isFirstAttempt = false,
    bool isChapterComplete = false,
  }) async {
    final alreadyCompletedToday =
        await PointService.instance.isLessonCompletedToday(lessonId);

    if (alreadyCompletedToday) {
      // Repetition penalty: zero base points for repeating lesson on same day
      return 0;
    }

    await PointService.instance.markLessonCompletedToday(lessonId);

    int pts = RewardConstants.completeLesson;
    if (isPerfect) pts += RewardConstants.perfectLesson;
    if (isFirstAttempt && isPerfect) pts += RewardConstants.firstAttemptPerfect;
    if (isChapterComplete) pts += RewardConstants.completeChapterLessons;

    // Check achievement triggers
    if (userProfile.totalLessonsCompleted == 0) {
      pts += await AchievementService.instance.unlockAchievement('first_lesson');
    }
    if (isPerfect) {
      pts += await AchievementService.instance
          .unlockAchievement('first_perfect_lesson');
    }

    return await _awardPointsInternal(
      basePoints: pts,
      sourceKey: 'lesson',
      lessonsDelta: 1,
      txId: 'lesson_${lessonId}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Awards points for completing a quiz.
  Future<int> awardQuiz({
    required String quizId,
    required int scorePercentage,
    bool beatPreviousBest = false,
  }) async {
    int pts = RewardConstants.completeQuiz;
    if (scorePercentage >= 80) pts += RewardConstants.scoreAbove80;
    if (scorePercentage == 100) pts += RewardConstants.score100;
    if (beatPreviousBest) pts += RewardConstants.beatPreviousBest;

    return await _awardPointsInternal(
      basePoints: pts,
      sourceKey: 'quiz',
      quizzesDelta: 1,
      txId: 'quiz_${quizId}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  /// Awards points for learning and reviewing vocabulary words.
  Future<int> awardVocabulary({
    int newWords = 0,
    int reviewedWords = 0,
    int masteredWords = 0,
  }) async {
    int pts = (newWords * RewardConstants.learnNewWord) +
        (reviewedWords * RewardConstants.reviewLearnedWord) +
        (masteredWords * RewardConstants.masterWord);

    if (newWords >= 10) {
      pts += RewardConstants.learn10WordsDailyBonus;
    }

    final newTotalWords = userProfile.totalWordsLearned + newWords;
    if (newTotalWords >= 100) {
      pts += await AchievementService.instance.unlockAchievement('learn_100_words');
    }
    if (newTotalWords >= 500) {
      pts += await AchievementService.instance.unlockAchievement('learn_500_words');
    }
    if (newTotalWords >= 1000) {
      pts += await AchievementService.instance.unlockAchievement('learn_1000_words');
    }

    return await _awardPointsInternal(
      basePoints: pts,
      sourceKey: 'vocabulary',
      wordsDelta: newWords,
    );
  }

  /// Awards points for practice exercises (Speaking, Listening, Writing, Grammar, Pronunciation).
  Future<int> awardPractice(String practiceType) async {
    int pts = RewardConstants.speakingPractice;
    switch (practiceType.toLowerCase()) {
      case 'listening':
        pts = RewardConstants.listeningPractice;
        break;
      case 'writing':
        pts = RewardConstants.writingPractice;
        break;
      case 'grammar':
        pts = RewardConstants.grammarExercise;
        break;
      case 'pronunciation':
        pts = RewardConstants.pronunciationExercise;
        break;
      default:
        pts = RewardConstants.speakingPractice;
    }
    return await _awardPointsInternal(
      basePoints: pts,
      sourceKey: 'practice',
    );
  }

  /// Awards points for mini-games.
  Future<int> awardMiniGame(String gameType) async {
    int pts = RewardConstants.wordMatch;
    switch (gameType.toLowerCase()) {
      case 'fill_in_the_blank':
        pts = RewardConstants.fillInTheBlank;
        break;
      case 'word_builder':
        pts = RewardConstants.wordBuilder;
        break;
      case 'sentence_builder':
        pts = RewardConstants.sentenceBuilder;
        break;
      case 'speed_challenge':
        pts = RewardConstants.speedChallenge;
        break;
      default:
        pts = RewardConstants.wordMatch;
    }
    return await _awardPointsInternal(
      basePoints: pts,
      sourceKey: 'minigame',
    );
  }

  /// Awards daily goal completion points.
  Future<int> awardDailyGoal({
    bool beforeNoon = false,
    bool allWeeklyComplete = false,
  }) async {
    int pts = RewardConstants.completeDailyGoal;
    if (beforeNoon) pts += RewardConstants.completeBeforeNoonBonus;
    if (allWeeklyComplete) pts += RewardConstants.completeAllWeeklyDailyGoals;

    return await _awardPointsInternal(
      basePoints: pts,
      sourceKey: 'daily_goal',
    );
  }

  /// Records study time in minutes (daily bonus cap 60 mins).
  Future<int> recordStudyTime(int minutes) async {
    final pts = await StreakService.instance.addStudyTime(minutes);
    if (pts > 0) {
      return await _awardPointsInternal(
        basePoints: pts,
        sourceKey: 'study_time',
      );
    }
    return 0;
  }

  /// Claims an achievement reward. Prevents duplicate claims.
  Future<int> claimAchievement(String achievementId) async {
    final pts = await AchievementService.instance.unlockAchievement(achievementId);
    if (pts > 0) {
      return await _awardPointsInternal(
        basePoints: pts,
        sourceKey: 'achievement',
      );
    }
    return 0;
  }

  @override
  void dispose() {
    _levelUpController.close();
    super.dispose();
  }
}
