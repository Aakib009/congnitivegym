import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sequence_master.dart';
import '../models/spot_the_difference.dart';
import '../models/user_profile.dart';
import 'achievement_service.dart';
import 'analytics_service.dart';
import 'auth_service.dart';
import 'exercise_scoring_service.dart';

/// Centralized service acting as the single source of truth for the user's cognitive progress.
class ProgressService extends ChangeNotifier {
  ProgressService._();

  static final ProgressService instance = ProgressService._();
  static const String _storageKeyBase = 'cognitive_user_profile_progress';

  String? _activeUserId;
  UserProfile _userProfile = defaultInitialProfile(
    userId: 'guest',
    displayName: 'Guest',
  );

  /// Read-only access to current user profile statistics.
  UserProfile get userProfile => _userProfile;

  // In-flight concurrency lock to prevent race conditions during concurrent async dispatches
  final Set<String> _inFlightCompletions = {};

  static const String _idempotencyStorageKeyBase =
      'cognitive_gym_idempotency_keys';

  static String _getIdempotencyStorageKey(String? userId) {
    if (userId != null && userId.isNotEmpty) {
      return '${_idempotencyStorageKeyBase}_$userId';
    }
    return _idempotencyStorageKeyBase;
  }

  /// Evaluates whether an activity completion identified by [idempotencyKey] has already been processed.
  Future<bool> isCompletionProcessed(String idempotencyKey) async {
    if (idempotencyKey.isEmpty) return false;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getIdempotencyStorageKey(_activeUserId);
      final list = prefs.getStringList(key) ?? [];
      return list.contains(idempotencyKey);
    } catch (_) {
      return false;
    }
  }

  /// Marks an activity completion identified by [idempotencyKey] as processed in persistent storage.
  Future<void> markCompletionProcessed(String idempotencyKey) async {
    if (idempotencyKey.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getIdempotencyStorageKey(_activeUserId);
      final list = prefs.getStringList(key) ?? [];
      if (!list.contains(idempotencyKey)) {
        list.add(idempotencyKey);
        // Retain last 1,000 keys to bound storage footprint cleanly
        if (list.length > 1000) {
          list.removeRange(0, list.length - 1000);
        }
        await prefs.setStringList(key, list);
      }
    } catch (_) {}
  }

  /// Clears in-flight locks and persisted idempotency records for the active user context.
  Future<void> clearIdempotencyKeys() async {
    _inFlightCompletions.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_getIdempotencyStorageKey(_activeUserId));
    } catch (_) {}
  }

  static String _getStorageKey(String? userId) {
    if (userId != null && userId.isNotEmpty) {
      return '${_storageKeyBase}_$userId';
    }
    return _storageKeyBase;
  }

  /// Default initial profile for new accounts (starts at Level 1, 0 XP, 0 completed exercises).
  static UserProfile defaultInitialProfile({
    required String userId,
    String displayName = 'Cognitive Explorer',
    String avatarId = 'raccoon',
  }) {
    return UserProfile(
      id: userId,
      displayName: displayName,
      level: 1,
      currentXp: 0,
      maxXp: 100,
      streakDays: 0,
      mentalEnergy: 1.0,
      avatarTitle: 'Forest Sage',
      avatarId: avatarId,
      creativityPoints: 0,
      observationPoints: 0,
      logicPoints: 0,
      decisionMakingPoints: 0,
      knowledgePoints: 0,
      totalXp: 0,
      totalExercisesCompleted: 0,
      totalLessonsCompleted: 0,
      totalQuizzesCompleted: 0,
      totalWordsLearned: 0,
      currentStreak: 0,
      bestStreak: 0,
      unlockedAchievements: const [],
      lastLevel: 1,
    );
  }

  /// Initializes the user progress profile from local storage.
  Future<void> init({String? userId, String? displayName}) async {
    final effectiveUserId = userId ?? AuthService.instance.currentUser?.id;
    if (effectiveUserId != null && effectiveUserId.isNotEmpty) {
      await loadForUser(
        effectiveUserId,
        displayName: displayName ?? AuthService.instance.currentUser?.fullName,
      );
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedJsonStr = prefs.getString(_getStorageKey(null));
        if (savedJsonStr != null && savedJsonStr.isNotEmpty) {
          _userProfile = UserProfile.fromRawJson(savedJsonStr);
        } else {
          _userProfile = UserProfile.mock();
        }
      } catch (_) {
        _userProfile = UserProfile.mock();
      }

      // Synchronize with AchievementService unlocked IDs
      try {
        final unlocked = await AchievementService.instance
            .getUnlockedAchievementIds();
        if (unlocked.isNotEmpty) {
          final combined = Set<String>.from(_userProfile.unlockedAchievements)
            ..addAll(unlocked);
          _userProfile = _userProfile.copyWith(
            unlockedAchievements: combined.toList(),
          );
        }
      } catch (_) {}

      notifyListeners();
    }
  }

  /// Loads and isolates progress statistics for a specific user ID.
  Future<void> loadForUser(
    String userId, {
    String? displayName,
    String? avatarId,
  }) async {
    _activeUserId = userId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getStorageKey(userId);
      final savedJsonStr = prefs.getString(key);
      if (savedJsonStr != null && savedJsonStr.isNotEmpty) {
        _userProfile = UserProfile.fromRawJson(savedJsonStr);
        if (avatarId != null &&
            avatarId.isNotEmpty &&
            _userProfile.avatarId != avatarId) {
          _userProfile = _userProfile.copyWith(avatarId: avatarId);
          await prefs.setString(key, _userProfile.toRawJson());
        }
      } else {
        _userProfile = defaultInitialProfile(
          userId: userId,
          displayName: displayName ?? 'Cognitive Explorer',
          avatarId: avatarId ?? 'raccoon',
        );
        await prefs.setString(key, _userProfile.toRawJson());
      }
    } catch (_) {
      _userProfile = defaultInitialProfile(
        userId: userId,
        displayName: displayName ?? 'Cognitive Explorer',
        avatarId: avatarId ?? 'raccoon',
      );
    }

    // Synchronize with AchievementService unlocked IDs
    try {
      final unlocked = await AchievementService.instance
          .getUnlockedAchievementIds();
      if (unlocked.isNotEmpty) {
        final combined = Set<String>.from(_userProfile.unlockedAchievements)
          ..addAll(unlocked);
        _userProfile = _userProfile.copyWith(
          unlockedAchievements: combined.toList(),
        );
      }
    } catch (_) {}

    notifyListeners();
  }

  /// Updates user avatar selection and persists across sessions.
  Future<void> updateAvatar(String newAvatarId) async {
    _userProfile = _userProfile.copyWith(avatarId: newAvatarId);
    await _saveLocal();
    notifyListeners();
  }

  /// Synchronizes unlocked achievements from AchievementService into user profile.
  Future<void> syncUnlockedAchievements(List<String> unlockedIds) async {
    _userProfile = _userProfile.copyWith(
      unlockedAchievements: List<String>.from(unlockedIds),
    );
    notifyListeners();
    await _saveLocal();
  }

  /// Awards XP for an unlocked achievement once and only once with idempotency protection.
  Future<void> awardAchievementXp({
    required String achievementId,
    required int xpAmount,
  }) async {
    if (xpAmount <= 0) return;
    final idempotencyKey = 'achievement_xp_$achievementId';
    if (await isCompletionProcessed(idempotencyKey)) {
      return;
    }
    await _updateProgress(xpDelta: xpAmount, exercisesCompletedDelta: 0);
    await markCompletionProcessed(idempotencyKey);
  }

  /// Resets in-memory progress upon user logout.
  void resetOnLogout() {
    _inFlightCompletions.clear();
    _activeUserId = null;
    _userProfile = defaultInitialProfile(userId: 'guest', displayName: 'Guest');
    notifyListeners();
  }

  /// Centralized internal method for updating user points, XP, and exercise counts.
  Future<void> _updateProgress({
    int creativityDelta = 0,
    int observationDelta = 0,
    int logicDelta = 0,
    int decisionMakingDelta = 0,
    int knowledgeDelta = 0,
    int xpDelta = 0,
    int exercisesCompletedDelta = 1,
    int lessonsDelta = 0,
    int quizzesDelta = 0,
    int wordsDelta = 0,
    int? currentStreak,
    int? bestStreak,
    List<String>? unlockedAchievements,
  }) async {
    final newCreativity = _userProfile.creativityPoints + creativityDelta;
    final newObservation = _userProfile.observationPoints + observationDelta;
    final newLogic = _userProfile.logicPoints + logicDelta;
    final newDecisionMaking =
        _userProfile.decisionMakingPoints + decisionMakingDelta;
    final newKnowledge = _userProfile.knowledgePoints + knowledgeDelta;
    final newTotalXp = _userProfile.totalXp + xpDelta;
    final newTotalCompleted =
        _userProfile.totalExercisesCompleted + exercisesCompletedDelta;
    final newLessons = _userProfile.totalLessonsCompleted + lessonsDelta;
    final newQuizzes = _userProfile.totalQuizzesCompleted + quizzesDelta;
    final newWords = _userProfile.totalWordsLearned + wordsDelta;

    // Derived level calculation (1 + totalXp ~/ 100)
    final newLevel = 1 + (newTotalXp ~/ 100);
    final currentXpInLevel = newTotalXp % 100;

    _userProfile = _userProfile.copyWith(
      creativityPoints: newCreativity,
      observationPoints: newObservation,
      logicPoints: newLogic,
      decisionMakingPoints: newDecisionMaking,
      knowledgePoints: newKnowledge,
      totalXp: newTotalXp,
      level: newLevel,
      currentXp: currentXpInLevel,
      maxXp: 100,
      totalExercisesCompleted: newTotalCompleted,
      totalLessonsCompleted: newLessons,
      totalQuizzesCompleted: newQuizzes,
      totalWordsLearned: newWords,
      currentStreak: currentStreak ?? _userProfile.currentStreak,
      bestStreak: bestStreak ?? _userProfile.bestStreak,
      unlockedAchievements:
          unlockedAchievements ?? _userProfile.unlockedAchievements,
    );

    notifyListeners();
    await _saveLocal();

    // Synchronize cognitive progression to SQLite user account
    await AuthService.instance.syncProgress(
      totalXp: _userProfile.totalXp,
      creativityPoints: _userProfile.creativityPoints,
      observationPoints: _userProfile.observationPoints,
      logicPoints: _userProfile.logicPoints,
      decisionMakingPoints: _userProfile.decisionMakingPoints,
      knowledgePoints: _userProfile.knowledgePoints,
      exercisesCompleted: _userProfile.totalExercisesCompleted,
      treeStage: _userProfile.level,
      currentRank: _userProfile.avatarTitle,
    );

    // Evaluate achievements dynamically based on updated user metrics
    try {
      await AchievementService.instance.evaluateAchievements(
        userProfile: _userProfile,
        wordsAdded: wordsDelta,
      );
    } catch (_) {}
  }

  /// Persists current user profile to local storage.
  Future<void> _saveLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _getStorageKey(_activeUserId),
        _userProfile.toRawJson(),
      );
    } catch (_) {}
  }

  // ===========================================================================
  // MODULE REWARD METHODS
  //
  // Every method below takes the REAL measured performance metrics computed
  // by ExerciseScoringService at exercise completion. Skill gains scale with
  // the 0-100 performance score (performance-dependent progression); XP stays
  // participation-based (fixed base + difficulty multiplier for Observation
  // Challenge + a small bounded excellence bonus). Scores are stored in the
  // analytics stream normalized to 0.0-1.0, and accuracy is recorded only for
  // exercises where the metric genuinely applies.
  //
  // Analytics logging is intentionally fire-and-forget (matching the original
  // architecture): AnalyticsRepository catches and reports its own errors, so
  // a storage failure can never block or corrupt the user-facing completion
  // flow. Profile/XP updates are always awaited.
  // ===========================================================================

  /// Awards rewards for completing the Story Builder exercise.
  ///
  /// * Creativity gain: 15 base points scaled by the performance tier.
  /// * XP: 15 participation XP (+5 bounded excellence bonus at score >= 90).
  /// Returns the XP earned for this completion (or 0 if already processed).
  Future<int> recordStoryBuilderCompletion({
    required double performanceScore,
    required double accuracy,
    required int durationSeconds,
    String? idempotencyKey,
  }) async {
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      if (!_inFlightCompletions.add(idempotencyKey)) {
        return 0;
      }
      if (await isCompletionProcessed(idempotencyKey)) {
        _inFlightCompletions.remove(idempotencyKey);
        return 0;
      }
    }

    try {
      final creativityGain = ExerciseScoringService.scaledGain(
        15,
        performanceScore,
      );
      final memoryGain = ExerciseScoringService.scaledGain(
        ExerciseScoringService.storyBaseMemoryPoints,
        performanceScore,
      );
      final xpEarned =
          ExerciseScoringService.storyBuilderBaseXp +
          ExerciseScoringService.excellenceBonusXp(performanceScore);

      await _updateProgress(
        creativityDelta: creativityGain,
        xpDelta: xpEarned,
        exercisesCompletedDelta: 1,
      );

      final isPerfect =
          performanceScore >= 100 ||
          accuracy >= 100 ||
          (accuracy > 0 && accuracy >= 1.0);
      if (isPerfect) {
        try {
          await AchievementService.instance.evaluateAchievements(
            userProfile: _userProfile,
            isPerfect: true,
          );
        } catch (_) {}
      }

      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        await markCompletionProcessed(idempotencyKey);
      }

      AnalyticsService.instance.logExerciseCompletion(
        exerciseType: 'story_builder',
        xpEarned: xpEarned,
        creativityDelta: creativityGain,
        memoryDelta: memoryGain,
        score: ExerciseScoringService.clampScore(performanceScore) / 100.0,
        // Accuracy = required-word coverage; the submission gate guarantees a
        // submitted story satisfied the prompt constraints.
        accuracy: ExerciseScoringService.clampScore(accuracy) / 100.0,
        durationSeconds: durationSeconds,
        eventId: idempotencyKey != null && idempotencyKey.isNotEmpty
            ? 'analytics_$idempotencyKey'
            : null,
      );
      return xpEarned;
    } finally {
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        _inFlightCompletions.remove(idempotencyKey);
      }
    }
  }

  /// Awards rewards for completing the Observation Challenge exercise.
  ///
  /// * Observation gain: 15 base points scaled by the performance tier.
  /// * XP: 15 base participation XP scaled by the chosen difficulty
  ///   (Easy 1.0x / Medium 1.2x / Hard 1.5x) plus the bounded excellence
  ///   bonus at score >= 90.
  /// Returns the XP earned for this completion (or 0 if already processed).
  Future<int> recordObservationChallengeCompletion({
    required double performanceScore,
    required double accuracy,
    required int durationSeconds,
    required ObservationDifficulty difficulty,
    String? idempotencyKey,
  }) async {
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      if (!_inFlightCompletions.add(idempotencyKey)) {
        return 0;
      }
      if (await isCompletionProcessed(idempotencyKey)) {
        _inFlightCompletions.remove(idempotencyKey);
        return 0;
      }
    }

    try {
      final observationGain = ExerciseScoringService.scaledGain(
        15,
        performanceScore,
      );
      final memoryGain = ExerciseScoringService.scaledGain(
        ExerciseScoringService.observationBaseMemoryPoints,
        performanceScore,
      );
      final xpEarned =
          (ExerciseScoringService.observationBaseXp * difficulty.xpMultiplier)
              .round() +
          ExerciseScoringService.excellenceBonusXp(performanceScore);

      await _updateProgress(
        observationDelta: observationGain,
        xpDelta: xpEarned,
        exercisesCompletedDelta: 1,
      );

      final isPerfect =
          performanceScore >= 100 ||
          accuracy >= 100 ||
          (accuracy > 0 && accuracy >= 1.0);
      if (isPerfect) {
        try {
          await AchievementService.instance.evaluateAchievements(
            userProfile: _userProfile,
            isPerfect: true,
          );
        } catch (_) {}
      }

      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        await markCompletionProcessed(idempotencyKey);
      }

      AnalyticsService.instance.logExerciseCompletion(
        exerciseType: 'observation_challenge',
        xpEarned: xpEarned,
        observationDelta: observationGain,
        memoryDelta: memoryGain,
        score: ExerciseScoringService.clampScore(performanceScore) / 100.0,
        // Accuracy = correct answers / total questions (genuinely meaningful).
        accuracy: ExerciseScoringService.clampScore(accuracy) / 100.0,
        durationSeconds: durationSeconds,
        eventId: idempotencyKey != null && idempotencyKey.isNotEmpty
            ? 'analytics_$idempotencyKey'
            : null,
      );
      return xpEarned;
    } finally {
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        _inFlightCompletions.remove(idempotencyKey);
      }
    }
  }

  /// Awards rewards for completing the Sequence Master exercise.
  ///
  /// * Logic gain: 20 base points scaled by the performance tier.
  /// * XP: 20 base participation XP scaled by the chosen difficulty
  ///   (Easy 1.0x / Medium 1.2x / Hard 1.5x) plus the bounded excellence
  ///   bonus at score >= 90.
  /// Returns the XP earned for this completion (or 0 if already processed).
  Future<int> recordSequenceMasterCompletion({
    required double performanceScore,
    required double accuracy,
    required int durationSeconds,
    required SequenceMasterDifficulty difficulty,
    int? correctAnswers,
    String? idempotencyKey,
  }) async {
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      if (!_inFlightCompletions.add(idempotencyKey)) {
        return 0;
      }
      if (await isCompletionProcessed(idempotencyKey)) {
        _inFlightCompletions.remove(idempotencyKey);
        return 0;
      }
    }

    try {
      final logicGain = ExerciseScoringService.scaledGain(
        ExerciseScoringService.sequenceMasterBaseLogicPoints,
        performanceScore,
      );
      final xpEarned =
          (ExerciseScoringService.sequenceMasterBaseXp *
                  difficulty.xpMultiplier)
              .round() +
          ExerciseScoringService.excellenceBonusXp(performanceScore);

      await _updateProgress(
        logicDelta: logicGain,
        xpDelta: xpEarned,
        exercisesCompletedDelta: 1,
      );

      final isPerfect = accuracy >= 100;
      if (isPerfect) {
        try {
          await AchievementService.instance.evaluateAchievements(
            userProfile: _userProfile,
            isPerfect: true,
          );
        } catch (_) {}
      }

      final effectiveCorrect =
          correctAnswers ??
          (difficulty.questionCount * (accuracy / 100.0)).round();

      try {
        await AchievementService.instance.recordSequenceMasterCompletion(
          correctAnswers: effectiveCorrect,
          accuracy: accuracy,
          difficulty: difficulty,
          userProfile: _userProfile,
        );
      } catch (_) {}

      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        await markCompletionProcessed(idempotencyKey);
      }

      AnalyticsService.instance.logExerciseCompletion(
        exerciseType: 'sequence_master',
        xpEarned: xpEarned,
        criticalThinkingDelta: logicGain,
        logicDelta: logicGain,
        score: ExerciseScoringService.clampScore(performanceScore) / 100.0,
        // Accuracy = correct sequences / total sequences.
        accuracy: ExerciseScoringService.clampScore(accuracy) / 100.0,
        durationSeconds: durationSeconds,
        eventId: idempotencyKey != null && idempotencyKey.isNotEmpty
            ? 'analytics_$idempotencyKey'
            : null,
      );
      return xpEarned;
    } finally {
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        _inFlightCompletions.remove(idempotencyKey);
      }
    }
  }

  /// Awards rewards for completing the Spot the Difference exercise.
  ///
  /// * Observation gain: 15 base points scaled by the performance tier.
  /// * Memory gain: 10 base points scaled by the performance tier.
  /// * XP: 20 base participation XP scaled by the chosen difficulty
  ///   (Easy 1.0x / Medium 1.2x / Hard 1.5x) plus the bounded excellence
  ///   bonus at score >= 90.
  /// Returns the XP earned for this completion (or 0 if already processed).
  Future<int> recordSpotTheDifferenceCompletion({
    required double performanceScore,
    required double accuracy,
    required int durationSeconds,
    required SpotDifferenceDifficulty difficulty,
    int? differencesFound,
    String? idempotencyKey,
  }) async {
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      if (!_inFlightCompletions.add(idempotencyKey)) {
        return 0;
      }
      if (await isCompletionProcessed(idempotencyKey)) {
        _inFlightCompletions.remove(idempotencyKey);
        return 0;
      }
    }

    try {
      final observationGain = ExerciseScoringService.scaledGain(
        ExerciseScoringService.spotTheDifferenceBaseObservationPoints,
        performanceScore,
      );
      final memoryGain = ExerciseScoringService.scaledGain(
        10,
        performanceScore,
      );
      final xpEarned =
          (ExerciseScoringService.spotTheDifferenceBaseXp *
                  difficulty.xpMultiplier)
              .round() +
          ExerciseScoringService.excellenceBonusXp(performanceScore);

      await _updateProgress(
        observationDelta: observationGain,
        xpDelta: xpEarned,
        exercisesCompletedDelta: 1,
      );

      final isPerfect = performanceScore >= 100 || accuracy >= 100;
      if (isPerfect) {
        try {
          await AchievementService.instance.evaluateAchievements(
            userProfile: _userProfile,
            isPerfect: true,
          );
        } catch (_) {}
      }

      final effectiveDifferences =
          differencesFound ??
          (accuracy >= 100 ? 4 : (4 * (accuracy / 100.0)).round());

      try {
        await AchievementService.instance.recordSpotTheDifferenceCompletion(
          differencesFound: effectiveDifferences,
          accuracy: accuracy,
          difficulty: difficulty,
          userProfile: _userProfile,
        );
      } catch (_) {}

      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        await markCompletionProcessed(idempotencyKey);
      }

      AnalyticsService.instance.logExerciseCompletion(
        exerciseType: 'spot_the_difference',
        xpEarned: xpEarned,
        observationDelta: observationGain,
        memoryDelta: memoryGain,
        score: ExerciseScoringService.clampScore(performanceScore) / 100.0,
        accuracy: ExerciseScoringService.clampScore(accuracy) / 100.0,
        durationSeconds: durationSeconds,
        eventId: idempotencyKey != null && idempotencyKey.isNotEmpty
            ? 'analytics_$idempotencyKey'
            : null,
      );
      return xpEarned;
    } finally {
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        _inFlightCompletions.remove(idempotencyKey);
      }
    }
  }

  /// Awards rewards for completing the Scenario Lab exercise.
  ///
  /// HONEST SCORING NOTE: scenario options are balanced trade-off dilemmas
  /// with no objectively correct answer, so no accuracy is recorded. The
  /// performance score is the deliberation-engagement score computed by
  /// ExerciseScoringService (measured deliberation time vs. estimated
  /// reading time).
  ///
  /// * Decision Making gain: 15 base points scaled by the performance tier.
  /// * Logic (critical thinking) gain: 10 base points scaled likewise.
  /// * XP: 20 participation XP (+5 bounded excellence bonus at score >= 90).
  /// Returns the XP earned for this completion (or 0 if already processed).
  Future<int> recordScenarioLabCompletion({
    required double performanceScore,
    required int durationSeconds,
    String? idempotencyKey,
  }) async {
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      if (!_inFlightCompletions.add(idempotencyKey)) {
        return 0;
      }
      if (await isCompletionProcessed(idempotencyKey)) {
        _inFlightCompletions.remove(idempotencyKey);
        return 0;
      }
    }

    try {
      final decisionGain = ExerciseScoringService.scaledGain(
        15,
        performanceScore,
      );
      final criticalThinkingGain = ExerciseScoringService.scaledGain(
        10,
        performanceScore,
      );
      final xpEarned =
          ExerciseScoringService.scenarioLabBaseXp +
          ExerciseScoringService.excellenceBonusXp(performanceScore);

      await _updateProgress(
        decisionMakingDelta: decisionGain,
        logicDelta: criticalThinkingGain,
        xpDelta: xpEarned,
        exercisesCompletedDelta: 1,
      );

      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        await markCompletionProcessed(idempotencyKey);
      }

      AnalyticsService.instance.logExerciseCompletion(
        exerciseType: 'scenario_lab',
        xpEarned: xpEarned,
        decisionMakingDelta: decisionGain,
        criticalThinkingDelta: criticalThinkingGain,
        logicDelta: criticalThinkingGain,
        score: ExerciseScoringService.clampScore(performanceScore) / 100.0,
        // accuracy intentionally omitted: trade-off dilemmas have no correct
        // answer, so no accuracy value is fabricated.
        durationSeconds: durationSeconds,
        eventId: idempotencyKey != null && idempotencyKey.isNotEmpty
            ? 'analytics_$idempotencyKey'
            : null,
      );
      return xpEarned;
    } finally {
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        _inFlightCompletions.remove(idempotencyKey);
      }
    }
  }

  /// Awards rewards for completing the Debate Arena exercise.
  ///
  /// HONEST SCORING NOTE: arguments have no binary correct answer, so no
  /// accuracy is recorded. The performance score blends the deterministic
  /// participation/substance metrics with the optional AI rubric evaluation
  /// (see ExerciseScoringService and DebateChatScreen).
  ///
  /// * Logic (critical thinking) gain: 25 base points scaled by the
  ///   performance tier.
  /// * XP: 30 participation XP (+5 bounded excellence bonus at score >= 90).
  /// Returns the XP earned for this completion (or 0 if already processed).
  Future<int> recordDebateArenaCompletion({
    required double performanceScore,
    required int durationSeconds,
    String? idempotencyKey,
  }) async {
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      if (!_inFlightCompletions.add(idempotencyKey)) {
        return 0;
      }
      if (await isCompletionProcessed(idempotencyKey)) {
        _inFlightCompletions.remove(idempotencyKey);
        return 0;
      }
    }

    try {
      final logicGain = ExerciseScoringService.scaledGain(25, performanceScore);
      final xpEarned =
          ExerciseScoringService.debateArenaBaseXp +
          ExerciseScoringService.excellenceBonusXp(performanceScore);

      await _updateProgress(
        logicDelta: logicGain,
        xpDelta: xpEarned,
        exercisesCompletedDelta: 1,
      );

      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        await markCompletionProcessed(idempotencyKey);
      }

      AnalyticsService.instance.logExerciseCompletion(
        exerciseType: 'debate_arena',
        xpEarned: xpEarned,
        criticalThinkingDelta: logicGain,
        logicDelta: logicGain,
        score: ExerciseScoringService.clampScore(performanceScore) / 100.0,
        // accuracy intentionally omitted: debate arguments have no correct
        // answer, so no accuracy value is fabricated.
        durationSeconds: durationSeconds,
        eventId: idempotencyKey != null && idempotencyKey.isNotEmpty
            ? 'analytics_$idempotencyKey'
            : null,
      );
      return xpEarned;
    } finally {
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        _inFlightCompletions.remove(idempotencyKey);
      }
    }
  }

  /// Generic method to record arbitrary exercise rewards (for future compatibility).
  Future<void> recordCustomExerciseReward({
    int creativity = 0,
    int observation = 0,
    int logic = 0,
    int decisionMaking = 0,
    int knowledge = 0,
    int xp = 0,
    int exercisesCompleted = 1,
    int lessons = 0,
    int quizzes = 0,
    int words = 0,
    int? currentStreak,
    int? bestStreak,
    List<String>? unlockedAchievements,
    String? idempotencyKey,
  }) async {
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      if (!_inFlightCompletions.add(idempotencyKey)) {
        return;
      }
      if (await isCompletionProcessed(idempotencyKey)) {
        _inFlightCompletions.remove(idempotencyKey);
        return;
      }
    }

    try {
      await _updateProgress(
        creativityDelta: creativity,
        observationDelta: observation,
        logicDelta: logic,
        decisionMakingDelta: decisionMaking,
        knowledgeDelta: knowledge,
        xpDelta: xp,
        exercisesCompletedDelta: exercisesCompleted,
        lessonsDelta: lessons,
        quizzesDelta: quizzes,
        wordsDelta: words,
        currentStreak: currentStreak,
        bestStreak: bestStreak,
        unlockedAchievements: unlockedAchievements,
      );

      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        await markCompletionProcessed(idempotencyKey);
      }
    } finally {
      if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
        _inFlightCompletions.remove(idempotencyKey);
      }
    }
  }

  /// Updates the user's display name.
  Future<void> updateDisplayName(String name) async {
    _userProfile = _userProfile.copyWith(displayName: name);
    notifyListeners();
    await _saveLocal();
  }

  /// Resets profile progress to initial state (for testing/debug purposes).
  Future<void> resetProgress() async {
    await clearIdempotencyKeys();
    _userProfile = UserProfile.mock();
    notifyListeners();
    await _saveLocal();
  }
}
