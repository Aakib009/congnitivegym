import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sequence_master.dart';
import '../models/spot_the_difference.dart';
import '../models/user_profile.dart';
import 'auth_service.dart';
import 'progress_service.dart';

/// Data representation of an achievement with category, progress targets, and reward metadata.
class AchievementItem {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int pointsReward;
  final bool isHidden;
  final int targetProgress;
  final String category;
  final String? unlockCondition;
  final String? targetDescription;

  const AchievementItem({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.pointsReward,
    this.isHidden = false,
    this.targetProgress = 1,
    this.category = 'General',
    this.unlockCondition,
    this.targetDescription,
  });
}

/// Service managing achievement unlocks, progress evaluation, persistence, and reactive updates.
class AchievementService extends ChangeNotifier {
  AchievementService._();

  static final AchievementService instance = AchievementService._();

  static const String _keyUnlockedAchievements = 'unlocked_achievements_list';
  static const String _keyUnlockTimestamps = 'unlocked_achievements_timestamps';
  static const String _keyPerfectScores = 'achievement_perfect_scores_count';
  static const String _keyConsecutiveCorrect =
      'achievement_consecutive_correct_count';
  static const String _keySmGamesCompleted = 'achievement_sm_games_completed';
  static const String _keySmQuestionsCorrect =
      'achievement_sm_questions_correct';
  static const String _keySmHardHighAccuracy =
      'achievement_sm_hard_high_accuracy_completed';
  static const String _keyStdDifferencesFound =
      'achievement_std_differences_found';
  static const String _keyStdGamesCompleted = 'achievement_std_games_completed';
  static const String _keyStdHighAccuracyCompleted =
      'achievement_std_high_accuracy_completed';

  final StreamController<AchievementItem> _unlockedController =
      StreamController<AchievementItem>.broadcast();

  /// Stream emitting newly unlocked achievements for celebratory feedback.
  Stream<AchievementItem> get onAchievementUnlocked =>
      _unlockedController.stream;

  List<String> _cachedUnlockedIds = [];
  Map<String, String> _cachedTimestamps = {};
  int _cachedPerfectScores = 0;
  int _cachedConsecutiveCorrect = 0;
  int _cachedSmGamesCompleted = 0;
  int _cachedSmQuestionsCorrect = 0;
  int _cachedSmHardHighAccuracy = 0;
  int _cachedStdDifferencesFound = 0;
  int _cachedStdGamesCompleted = 0;
  int _cachedStdHighAccuracyCompleted = 0;
  bool _isInitialized = false;
  bool _isEvaluating = false;

  int get smGamesCompleted => _cachedSmGamesCompleted;
  int get smQuestionsCorrect => _cachedSmQuestionsCorrect;
  int get smHardHighAccuracy => _cachedSmHardHighAccuracy;
  int get stdDifferencesFound => _cachedStdDifferencesFound;
  int get stdGamesCompleted => _cachedStdGamesCompleted;
  int get stdHighAccuracyCompleted => _cachedStdHighAccuracyCompleted;

  /// User-scoped storage key for SharedPreferences isolation.
  String _userKey(String base) {
    final uid = AuthService.instance.currentUser?.id;
    return (uid != null && uid.isNotEmpty) ? '${base}_$uid' : base;
  }

  /// Master list of all 25 authentic achievements defined in Cognitive Gym.
  static final List<AchievementItem> allAchievements = [
    // 1. Getting Started
    const AchievementItem(
      id: 'first_step',
      title: 'First Step',
      description:
          'Every journey begins with a single step. Complete your first cognitive game and begin your journey towards a sharper mind.',
      emoji: '🎯',
      pointsReward: 50,
      targetProgress: 1,
      category: 'Getting Started',
      unlockCondition:
          'Complete any one game in Cognitive Gym for the first time. Any game qualifies, regardless of its category.',
      targetDescription: '1 completed game.',
    ),

    // 2. Observation (Progressive Series)
    const AchievementItem(
      id: 'sharp_eye',
      title: 'Sharp-eye',
      description:
          'Your observation skills are improving. Keep noticing the little details!',
      emoji: '👁️',
      pointsReward: 50,
      targetProgress: 50,
      category: 'Observation',
      unlockCondition: 'Collect 50 Observation Points.',
      targetDescription: '50 Observation Points.',
    ),
    const AchievementItem(
      id: 'eagle_eye',
      title: 'Eagle-eye',
      description:
          'Your eyes miss very little. Your attention to detail is becoming impressive.',
      emoji: '🦅',
      pointsReward: 75,
      targetProgress: 100,
      category: 'Observation',
      unlockCondition: 'Collect 100 Observation Points.',
      targetDescription: '100 Observation Points.',
    ),
    const AchievementItem(
      id: 'hawk_eye',
      title: 'Hawk-eye',
      description:
          'You have developed exceptional observation skills. Almost nothing escapes your attention.',
      emoji: '🔍',
      pointsReward: 100,
      targetProgress: 150,
      category: 'Observation',
      unlockCondition: 'Collect 150 Observation Points.',
      targetDescription: '150 Observation Points.',
    ),
    const AchievementItem(
      id: 'master_observer',
      title: 'Master Observer',
      description:
          'An extraordinary observer. Your ability to notice and recognize details has reached an elite level.',
      emoji: '🔭',
      pointsReward: 150,
      targetProgress: 300,
      category: 'Observation',
      unlockCondition: 'Collect 300 Observation Points.',
      targetDescription: '300 Observation Points.',
    ),

    // 3. Decision Making (Progressive Series)
    const AchievementItem(
      id: 'the_hardest_choice',
      title: 'The Hardest Choice',
      description:
          'Difficult decisions are part of growth. You have demonstrated your ability to make thoughtful choices.',
      emoji: '⚖️',
      pointsReward: 50,
      targetProgress: 100,
      category: 'Decision Making',
      unlockCondition: 'Collect 100 Decision Points.',
      targetDescription: '100 Decision Points.',
    ),
    const AchievementItem(
      id: 'no_turning_back',
      title: 'No Turning Back',
      description:
          'You stand firmly by your decisions. Your decision-making skills have reached another level.',
      emoji: '🧭',
      pointsReward: 100,
      targetProgress: 200,
      category: 'Decision Making',
      unlockCondition: 'Collect 200 Decision Points.',
      targetDescription: '200 Decision Points.',
    ),

    // 4. Creativity (Progressive Series)
    const AchievementItem(
      id: 'tall_tales',
      title: 'Tall Tales',
      description:
          'Every great story starts with an imagination. You have successfully completed 20 Story Builder games.',
      emoji: '📖',
      pointsReward: 50,
      targetProgress: 20,
      category: 'Creativity',
      unlockCondition: 'Complete 20 Story Builder games.',
      targetDescription: '20 completed Story Builder games.',
    ),
    const AchievementItem(
      id: 'tall_tales_1',
      title: 'Tall Tales I',
      description:
          'Your creativity knows no boundaries. You have taken your storytelling journey even further.',
      emoji: '📚',
      pointsReward: 100,
      targetProgress: 50,
      category: 'Creativity',
      unlockCondition: 'Complete 50 Debate Arena games.',
      targetDescription: '50 completed Story builder games.',
    ),
    const AchievementItem(
      id: 'tall_tales_2',
      title: 'Tall Tales II',
      description:
          'Your imagination and creative thinking continue to grow. You have reached another major milestone.',
      emoji: '📜',
      pointsReward: 150,
      targetProgress: 100,
      category: 'Creativity',
      unlockCondition: 'Complete 100 story builder games.',
      targetDescription: '100 completed Debate Arena games.',
    ),

    // 5. Logic and Critical Thinking (Progressive Series)
    const AchievementItem(
      id: 'counter_point',
      title: 'Counter Point',
      description:
          'Every argument deserves thoughtful consideration. You have completed 20 Debate Arena games.',
      emoji: '💬',
      pointsReward: 50,
      targetProgress: 20,
      category: 'Logic and Critical Thinking',
      unlockCondition: 'Complete 20 Debate Arena games.',
      targetDescription: '20 completed Debate Arena games.',
    ),
    const AchievementItem(
      id: 'counter_point_1',
      title: 'Counter Point I',
      description:
          'You have developed greater confidence in examining arguments and defending your reasoning.',
      emoji: '🗣️',
      pointsReward: 100,
      targetProgress: 50,
      category: 'Logic and Critical Thinking',
      unlockCondition: 'Complete 50 Debate Arena games.',
      targetDescription: '50 completed Debate Arena games.',
    ),
    const AchievementItem(
      id: 'counter_point_2',
      title: 'Counter Point II',
      description:
          'A seasoned debater. Your dedication to logical reasoning and critical thinking is remarkable.',
      emoji: '⚡',
      pointsReward: 150,
      targetProgress: 100,
      category: 'Logic and Critical Thinking',
      unlockCondition: 'Complete 100 Debate Arena games.',
      targetDescription: '100 completed Debate Arena games.',
    ),

    // 6. Overall Progress (Progressive Series)
    const AchievementItem(
      id: 'xp_hunter',
      title: 'XP Hunter',
      description:
          'Your journey is gaining momentum. Keep training and collecting experience!',
      emoji: '🏹',
      pointsReward: 50,
      targetProgress: 1000,
      category: 'Overall Progress',
      unlockCondition: 'Reach 1,000 Total XP.',
      targetDescription: '1,000 XP.',
    ),
    const AchievementItem(
      id: 'xp_hunter_2',
      title: 'XP Hunter II',
      description:
          'Your dedication is paying off. You have accumulated a significant amount of experience.',
      emoji: '⚔️',
      pointsReward: 100,
      targetProgress: 2000,
      category: 'Overall Progress',
      unlockCondition: 'Reach 2,000 Total XP.',
      targetDescription: '2,000 XP.',
    ),
    const AchievementItem(
      id: 'xp_hunter_3',
      title: 'XP Hunter III',
      description:
          'An experienced mind in constant development. Your commitment to cognitive training is impressive.',
      emoji: '👑',
      pointsReward: 150,
      targetProgress: 3000,
      category: 'Overall Progress',
      unlockCondition: 'Reach 3,000 Total XP.',
      targetDescription: '3,000 XP.',
    ),

    // 7. Level Progression (Progressive Series)
    const AchievementItem(
      id: 'rising_star',
      title: 'Rising Star',
      description:
          'Your efforts are beginning to shine. You have reached an important milestone in your cognitive journey.',
      emoji: '⭐',
      pointsReward: 50,
      targetProgress: 10,
      category: 'Level Progression',
      unlockCondition: 'Reach Level 10.',
      targetDescription: 'Level 10.',
    ),
    const AchievementItem(
      id: 'rising_star_2',
      title: 'Rising Star II',
      description:
          'Your progress is impressive. You are becoming a dedicated cognitive athlete.',
      emoji: '🌟',
      pointsReward: 100,
      targetProgress: 20,
      category: 'Level Progression',
      unlockCondition: 'Reach Level 20.',
      targetDescription: 'Level 20.',
    ),
    const AchievementItem(
      id: 'rising_star_3',
      title: 'Rising Star III',
      description:
          'Your journey has taken you to an elite level. Your consistency and dedication have paid off.',
      emoji: '✨',
      pointsReward: 150,
      targetProgress: 30,
      category: 'Level Progression',
      unlockCondition: 'Reach Level 30.',
      targetDescription: 'Level 30.',
    ),

    // 8. Sequence Master Achievements
    const AchievementItem(
      id: 'pattern_apprentice',
      title: 'Pattern Apprentice',
      description:
          'Complete your first Sequence Master game and begin unlocking the secrets of logic.',
      emoji: '🧩',
      pointsReward: 25,
      targetProgress: 1,
      category: 'Sequence Master',
      unlockCondition: 'Complete your first Sequence Master game.',
      targetDescription: '1 completed Sequence Master game.',
    ),
    const AchievementItem(
      id: 'sequence_specialist',
      title: 'Sequence Specialist',
      description:
          'Demonstrate your logical deduction by answering 20 Sequence Master questions correctly across multiple sessions.',
      emoji: '🔢',
      pointsReward: 50,
      targetProgress: 20,
      category: 'Sequence Master',
      unlockCondition:
          'Answer 20 Sequence Master questions correctly across multiple sessions.',
      targetDescription: '20 correct sequence answers.',
    ),
    const AchievementItem(
      id: 'master_of_patterns',
      title: 'Master of Patterns',
      description:
          'Conquer the toughest sequence challenges. Complete a Hard difficulty Sequence Master game with at least 90% accuracy.',
      emoji: '⚡',
      pointsReward: 100,
      targetProgress: 1,
      category: 'Sequence Master',
      unlockCondition:
          'Complete a Hard difficulty Sequence Master game with at least 90% accuracy.',
      targetDescription: '1 Hard game with >= 90% accuracy.',
    ),

    // 9. Spot the Difference Achievements
    const AchievementItem(
      id: 'sharp_eyes',
      title: 'Sharp Eyes',
      description:
          'Spot visual discrepancies with precision. Successfully identify 10 differences across challenges.',
      emoji: '🔍',
      pointsReward: 25,
      targetProgress: 10,
      category: 'Spot the Difference',
      unlockCondition: 'Successfully identify 10 differences.',
      targetDescription: '10 identified differences.',
    ),
    const AchievementItem(
      id: 'detail_detective',
      title: 'Detail Detective',
      description:
          'Your keen scrutiny is unmatched. Complete 5 Spot the Difference challenges.',
      emoji: '🕵️',
      pointsReward: 50,
      targetProgress: 5,
      category: 'Spot the Difference',
      unlockCondition: 'Complete 5 Spot the Difference challenges.',
      targetDescription: '5 completed challenges.',
    ),
    const AchievementItem(
      id: 'nothing_escapes_me',
      title: 'Nothing Escapes Me',
      description:
          'Achieve observation mastery by completing 10 Spot the Difference challenges with at least 90% accuracy.',
      emoji: '🎯',
      pointsReward: 100,
      targetProgress: 10,
      category: 'Spot the Difference',
      unlockCondition:
          'Complete 10 Spot the Difference challenges with at least 90% accuracy.',
      targetDescription: '10 challenges with >= 90% accuracy.',
    ),
  ];

  /// Initializes the service from local storage and performs an initial evaluation.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedUnlockedIds =
        prefs.getStringList(_userKey(_keyUnlockedAchievements)) ?? [];

    final rawTimestamps = prefs.getString(_userKey(_keyUnlockTimestamps));
    if (rawTimestamps != null && rawTimestamps.isNotEmpty) {
      try {
        _cachedTimestamps = Map<String, String>.from(
          json.decode(rawTimestamps) as Map,
        );
      } catch (_) {
        _cachedTimestamps = {};
      }
    } else {
      _cachedTimestamps = {};
    }

    _cachedPerfectScores = prefs.getInt(_userKey(_keyPerfectScores)) ?? 0;
    _cachedConsecutiveCorrect =
        prefs.getInt(_userKey(_keyConsecutiveCorrect)) ?? 0;
    _cachedSmGamesCompleted = prefs.getInt(_userKey(_keySmGamesCompleted)) ?? 0;
    _cachedSmQuestionsCorrect =
        prefs.getInt(_userKey(_keySmQuestionsCorrect)) ?? 0;
    _cachedSmHardHighAccuracy =
        prefs.getInt(_userKey(_keySmHardHighAccuracy)) ?? 0;
    _cachedStdDifferencesFound =
        prefs.getInt(_userKey(_keyStdDifferencesFound)) ?? 0;
    _cachedStdGamesCompleted =
        prefs.getInt(_userKey(_keyStdGamesCompleted)) ?? 0;
    _cachedStdHighAccuracyCompleted =
        prefs.getInt(_userKey(_keyStdHighAccuracyCompleted)) ?? 0;

    _isInitialized = true;

    // Evaluate existing profile metrics to unlock any qualified achievements
    await evaluateAchievements(
      userProfile: ProgressService.instance.userProfile,
    );

    notifyListeners();
  }

  /// Whether the service has completed loading from storage.
  bool get isInitialized => _isInitialized;

  /// Fast synchronous check for achievement completion.
  bool isUnlocked(String achievementId) {
    return _cachedUnlockedIds.contains(achievementId);
  }

  /// Returns list of unlocked achievement IDs.
  Future<List<String>> getUnlockedAchievementIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_userKey(_keyUnlockedAchievements)) ?? [];
    _cachedUnlockedIds = List<String>.from(list);
    return list;
  }

  /// Returns unlock timestamp for the given achievement ID, or null if locked.
  DateTime? getUnlockDate(String achievementId) {
    final str = _cachedTimestamps[achievementId];
    if (str == null) return null;
    return DateTime.tryParse(str);
  }

  /// Returns current progress value clamped between 0 and targetProgress.
  int getProgress(String achievementId, [UserProfile? profile]) {
    final user = profile ?? ProgressService.instance.userProfile;
    final totalActivityCount =
        user.totalLessonsCompleted + user.totalExercisesCompleted;

    if (isUnlocked(achievementId)) {
      final item = allAchievements.firstWhere(
        (a) => a.id == achievementId,
        orElse: () => AchievementItem(
          id: achievementId,
          title: '',
          description: '',
          emoji: '🎯',
          pointsReward: 0,
        ),
      );
      return item.targetProgress;
    }

    switch (achievementId) {
      case 'first_step':
        return totalActivityCount.clamp(0, 1);
      case 'sharp_eye':
        return user.observationPoints.clamp(0, 50);
      case 'eagle_eye':
        return user.observationPoints.clamp(0, 100);
      case 'hawk_eye':
        return user.observationPoints.clamp(0, 150);
      case 'master_observer':
        return user.observationPoints.clamp(0, 300);
      case 'the_hardest_choice':
        return user.decisionMakingPoints.clamp(0, 100);
      case 'no_turning_back':
        return user.decisionMakingPoints.clamp(0, 200);
      case 'tall_tales':
        return totalActivityCount.clamp(0, 20);
      case 'tall_tales_1':
        return totalActivityCount.clamp(0, 50);
      case 'tall_tales_2':
        return totalActivityCount.clamp(0, 100);
      case 'counter_point':
        return totalActivityCount.clamp(0, 20);
      case 'counter_point_1':
        return totalActivityCount.clamp(0, 50);
      case 'counter_point_2':
        return totalActivityCount.clamp(0, 100);
      case 'xp_hunter':
        return user.totalXp.clamp(0, 1000);
      case 'xp_hunter_2':
        return user.totalXp.clamp(0, 2000);
      case 'xp_hunter_3':
        return user.totalXp.clamp(0, 3000);
      case 'rising_star':
        return user.level.clamp(0, 10);
      case 'rising_star_2':
        return user.level.clamp(0, 20);
      case 'rising_star_3':
        return user.level.clamp(0, 30);
      case 'pattern_apprentice':
        return _cachedSmGamesCompleted.clamp(0, 1);
      case 'sequence_specialist':
        return _cachedSmQuestionsCorrect.clamp(0, 20);
      case 'master_of_patterns':
        return _cachedSmHardHighAccuracy.clamp(0, 1);
      case 'sharp_eyes':
        return _cachedStdDifferencesFound.clamp(0, 10);
      case 'detail_detective':
        return _cachedStdGamesCompleted.clamp(0, 5);
      case 'nothing_escapes_me':
        return _cachedStdHighAccuracyCompleted.clamp(0, 10);
      default:
        return 0;
    }
  }

  /// Attempts to unlock an achievement.
  /// Anti-Exploitation: Returns points awarded, or 0 if already unlocked.
  Future<int> unlockAchievement(
    String achievementId, {
    bool awardXp = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final unlocked =
        prefs.getStringList(_userKey(_keyUnlockedAchievements)) ?? [];

    if (unlocked.contains(achievementId)) {
      return 0; // Already claimed - anti-exploitation rule
    }

    final achievement = allAchievements.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => AchievementItem(
        id: achievementId,
        title: 'Custom Achievement',
        description: 'Completed achievement challenge.',
        emoji: '🌟',
        pointsReward: 50,
      ),
    );

    unlocked.add(achievementId);
    _cachedUnlockedIds = List<String>.from(unlocked);
    await prefs.setStringList(_userKey(_keyUnlockedAchievements), unlocked);

    // Save timestamp
    _cachedTimestamps[achievementId] = DateTime.now().toIso8601String();
    await prefs.setString(
      _userKey(_keyUnlockTimestamps),
      json.encode(_cachedTimestamps),
    );

    // Synchronize with ProgressService
    await ProgressService.instance.syncUnlockedAchievements(_cachedUnlockedIds);

    // Award XP only once per achievement
    if (awardXp && achievement.pointsReward > 0) {
      await ProgressService.instance.awardAchievementXp(
        achievementId: achievement.id,
        xpAmount: achievement.pointsReward,
      );
    }

    // Emit event and notify UI
    _unlockedController.add(achievement);
    notifyListeners();

    return achievement.pointsReward;
  }

  /// Increments and persists the count of perfect scores.
  Future<void> recordPerfectScore() async {
    _cachedPerfectScores++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userKey(_keyPerfectScores), _cachedPerfectScores);
  }

  /// Increments consecutive correct answers counter.
  Future<void> recordCorrectAnswers(int count) async {
    if (count <= 0) return;
    _cachedConsecutiveCorrect += count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _userKey(_keyConsecutiveCorrect),
      _cachedConsecutiveCorrect,
    );
  }

  /// Resets consecutive correct answers counter upon a mistake.
  Future<void> resetConsecutiveCorrect() async {
    _cachedConsecutiveCorrect = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userKey(_keyConsecutiveCorrect), 0);
  }

  /// Records a completed Sequence Master session and evaluates achievements.
  Future<List<AchievementItem>> recordSequenceMasterCompletion({
    required int correctAnswers,
    required double accuracy,
    required SequenceMasterDifficulty difficulty,
    UserProfile? userProfile,
  }) async {
    if (!_isInitialized) return [];
    _cachedSmGamesCompleted++;
    _cachedSmQuestionsCorrect += correctAnswers;
    if (difficulty == SequenceMasterDifficulty.hard && accuracy >= 90.0) {
      _cachedSmHardHighAccuracy++;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userKey(_keySmGamesCompleted), _cachedSmGamesCompleted);
    await prefs.setInt(
      _userKey(_keySmQuestionsCorrect),
      _cachedSmQuestionsCorrect,
    );
    await prefs.setInt(
      _userKey(_keySmHardHighAccuracy),
      _cachedSmHardHighAccuracy,
    );

    return await evaluateAchievements(userProfile: userProfile);
  }

  /// Records a completed Spot the Difference challenge session and evaluates achievements.
  Future<List<AchievementItem>> recordSpotTheDifferenceCompletion({
    required int differencesFound,
    required double accuracy,
    required SpotDifferenceDifficulty difficulty,
    UserProfile? userProfile,
  }) async {
    if (!_isInitialized) return [];
    _cachedStdGamesCompleted++;
    _cachedStdDifferencesFound += differencesFound;
    if (accuracy >= 90.0) {
      _cachedStdHighAccuracyCompleted++;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _userKey(_keyStdGamesCompleted),
      _cachedStdGamesCompleted,
    );
    await prefs.setInt(
      _userKey(_keyStdDifferencesFound),
      _cachedStdDifferencesFound,
    );
    await prefs.setInt(
      _userKey(_keyStdHighAccuracyCompleted),
      _cachedStdHighAccuracyCompleted,
    );

    return await evaluateAchievements(userProfile: userProfile);
  }

  /// Evaluates all achievement criteria against user activity and unlocks any qualified ones.
  Future<List<AchievementItem>> evaluateAchievements({
    UserProfile? userProfile,
    bool isPerfect = false,
    int consecutiveCorrectAdded = 0,
    int wordsAdded = 0,
  }) async {
    if (!_isInitialized || _isEvaluating) return [];
    _isEvaluating = true;
    try {
      final newlyUnlocked = <AchievementItem>[];

      if (consecutiveCorrectAdded > 0) {
        await recordCorrectAnswers(consecutiveCorrectAdded);
      }

      if (isPerfect) {
        await recordPerfectScore();
      }

      final profile = userProfile ?? ProgressService.instance.userProfile;
      final totalActivityCount =
          profile.totalLessonsCompleted + profile.totalExercisesCompleted;

      // 1. Getting Started
      if (!isUnlocked('first_step') && totalActivityCount >= 1) {
        final pts = await unlockAchievement('first_step');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'first_step'),
          );
        }
      }

      // 2. Observation (Progressive Series)
      if (!isUnlocked('sharp_eye') && profile.observationPoints >= 50) {
        final pts = await unlockAchievement('sharp_eye');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'sharp_eye'),
          );
        }
      }
      if (!isUnlocked('eagle_eye') && profile.observationPoints >= 100) {
        final pts = await unlockAchievement('eagle_eye');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'eagle_eye'),
          );
        }
      }
      if (!isUnlocked('hawk_eye') && profile.observationPoints >= 150) {
        final pts = await unlockAchievement('hawk_eye');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'hawk_eye'),
          );
        }
      }
      if (!isUnlocked('master_observer') && profile.observationPoints >= 300) {
        final pts = await unlockAchievement('master_observer');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'master_observer'),
          );
        }
      }

      // 3. Decision Making (Progressive Series)
      if (!isUnlocked('the_hardest_choice') &&
          profile.decisionMakingPoints >= 100) {
        final pts = await unlockAchievement('the_hardest_choice');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'the_hardest_choice'),
          );
        }
      }
      if (!isUnlocked('no_turning_back') &&
          profile.decisionMakingPoints >= 200) {
        final pts = await unlockAchievement('no_turning_back');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'no_turning_back'),
          );
        }
      }

      // 4. Creativity (Progressive Series)
      if (!isUnlocked('tall_tales') && totalActivityCount >= 20) {
        final pts = await unlockAchievement('tall_tales');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'tall_tales'),
          );
        }
      }
      if (!isUnlocked('tall_tales_1') && totalActivityCount >= 50) {
        final pts = await unlockAchievement('tall_tales_1');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'tall_tales_1'),
          );
        }
      }
      if (!isUnlocked('tall_tales_2') && totalActivityCount >= 100) {
        final pts = await unlockAchievement('tall_tales_2');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'tall_tales_2'),
          );
        }
      }

      // 5. Logic and Critical Thinking (Progressive Series)
      if (!isUnlocked('counter_point') && totalActivityCount >= 20) {
        final pts = await unlockAchievement('counter_point');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'counter_point'),
          );
        }
      }
      if (!isUnlocked('counter_point_1') && totalActivityCount >= 50) {
        final pts = await unlockAchievement('counter_point_1');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'counter_point_1'),
          );
        }
      }
      if (!isUnlocked('counter_point_2') && totalActivityCount >= 100) {
        final pts = await unlockAchievement('counter_point_2');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'counter_point_2'),
          );
        }
      }

      // 6. Overall Progress (Progressive Series)
      if (!isUnlocked('xp_hunter') && profile.totalXp >= 1000) {
        final pts = await unlockAchievement('xp_hunter');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'xp_hunter'),
          );
        }
      }
      if (!isUnlocked('xp_hunter_2') && profile.totalXp >= 2000) {
        final pts = await unlockAchievement('xp_hunter_2');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'xp_hunter_2'),
          );
        }
      }
      if (!isUnlocked('xp_hunter_3') && profile.totalXp >= 3000) {
        final pts = await unlockAchievement('xp_hunter_3');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'xp_hunter_3'),
          );
        }
      }

      // 7. Level Progression (Progressive Series)
      if (!isUnlocked('rising_star') && profile.level >= 10) {
        final pts = await unlockAchievement('rising_star');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'rising_star'),
          );
        }
      }
      if (!isUnlocked('rising_star_2') && profile.level >= 20) {
        final pts = await unlockAchievement('rising_star_2');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'rising_star_2'),
          );
        }
      }
      if (!isUnlocked('rising_star_3') && profile.level >= 30) {
        final pts = await unlockAchievement('rising_star_3');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'rising_star_3'),
          );
        }
      }

      // 8. Sequence Master Achievements
      if (!isUnlocked('pattern_apprentice') && _cachedSmGamesCompleted >= 1) {
        final pts = await unlockAchievement('pattern_apprentice');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'pattern_apprentice'),
          );
        }
      }
      if (!isUnlocked('sequence_specialist') &&
          _cachedSmQuestionsCorrect >= 20) {
        final pts = await unlockAchievement('sequence_specialist');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'sequence_specialist'),
          );
        }
      }
      if (!isUnlocked('master_of_patterns') && _cachedSmHardHighAccuracy >= 1) {
        final pts = await unlockAchievement('master_of_patterns');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'master_of_patterns'),
          );
        }
      }

      // 9. Spot the Difference Achievements
      if (!isUnlocked('sharp_eyes') && _cachedStdDifferencesFound >= 10) {
        final pts = await unlockAchievement('sharp_eyes');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'sharp_eyes'),
          );
        }
      }
      if (!isUnlocked('detail_detective') && _cachedStdGamesCompleted >= 5) {
        final pts = await unlockAchievement('detail_detective');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'detail_detective'),
          );
        }
      }
      if (!isUnlocked('nothing_escapes_me') &&
          _cachedStdHighAccuracyCompleted >= 10) {
        final pts = await unlockAchievement('nothing_escapes_me');
        if (pts > 0) {
          newlyUnlocked.add(
            allAchievements.firstWhere((a) => a.id == 'nothing_escapes_me'),
          );
        }
      }

      return newlyUnlocked;
    } finally {
      _isEvaluating = false;
    }
  }

  static String? _lastShownAchievementId;
  static DateTime? _lastShownTime;

  /// Displays a non-intrusive celebratory notification when an achievement is unlocked.
  static void showUnlockSnackBar(
    BuildContext context,
    AchievementItem achievement,
  ) {
    if (!context.mounted) return;
    final now = DateTime.now();
    if (_lastShownAchievementId == achievement.id &&
        _lastShownTime != null &&
        now.difference(_lastShownTime!) < const Duration(milliseconds: 1000)) {
      return;
    }
    _lastShownAchievementId = achievement.id;
    _lastShownTime = now;

    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        elevation: 6,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
        ),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: const Color(0xFF10B981),
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(40),
                shape: BoxShape.circle,
              ),
              child: Text(
                achievement.emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🏆 Milestone Unlocked!',
                    style: TextStyle(
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${achievement.pointsReward} XP',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Resets in-memory cached state for unit testing.
  void resetForTesting() {
    _cachedUnlockedIds.clear();
    _cachedTimestamps.clear();
    _cachedPerfectScores = 0;
    _cachedConsecutiveCorrect = 0;
    _cachedSmGamesCompleted = 0;
    _cachedSmQuestionsCorrect = 0;
    _cachedSmHardHighAccuracy = 0;
    _cachedStdDifferencesFound = 0;
    _cachedStdGamesCompleted = 0;
    _cachedStdHighAccuracyCompleted = 0;
    _isInitialized = false;
    _isEvaluating = false;
    _lastShownAchievementId = null;
    _lastShownTime = null;
  }

  @override
  void dispose() {
    _unlockedController.close();
    super.dispose();
  }
}
