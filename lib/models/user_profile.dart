import 'dart:convert';

/// Represents a user's cognitive stats, level, points, and overall progress.
class UserProfile {
  final String id;
  final String displayName;
  final int level;
  final int currentXp;
  final int maxXp;
  final int streakDays;
  final double mentalEnergy;
  final String avatarTitle;
  final String avatarId;

  // Cognitive Progression Statistics
  final int creativityPoints;
  final int observationPoints;
  final int logicPoints;
  final int decisionMakingPoints;
  final int knowledgePoints;
  final int totalXp;
  final int totalExercisesCompleted;

  // Mind Tree & Learning Gamification Statistics
  final int totalLessonsCompleted;
  final int totalQuizzesCompleted;
  final int totalWordsLearned;
  final int currentStreak;
  final int bestStreak;
  final List<String> unlockedAchievements;
  final int lastLevel;

  const UserProfile({
    required this.id,
    required this.displayName,
    required this.level,
    required this.currentXp,
    required this.maxXp,
    required this.streakDays,
    required this.mentalEnergy,
    required this.avatarTitle,
    this.avatarId = 'raccoon',
    this.creativityPoints = 0,
    this.observationPoints = 0,
    this.logicPoints = 0,
    this.decisionMakingPoints = 0,
    this.knowledgePoints = 0,
    this.totalXp = 0,
    this.totalExercisesCompleted = 0,
    this.totalLessonsCompleted = 0,
    this.totalQuizzesCompleted = 0,
    this.totalWordsLearned = 0,
    this.currentStreak = 1,
    this.bestStreak = 1,
    this.unlockedAchievements = const [],
    this.lastLevel = 1,
  });

  /// Factory mock profile for initial UI preview
  factory UserProfile.mock() {
    return const UserProfile(
      id: 'usr_001',
      displayName: 'Alex Mindful',
      level: 7,
      currentXp: 1420,
      maxXp: 2000,
      streakDays: 5,
      mentalEnergy: 0.85,
      avatarTitle: 'Cognitive Trainee',
      avatarId: 'raccoon',
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
      currentStreak: 5,
      bestStreak: 12,
      unlockedAchievements: [],
      lastLevel: 7,
    );
  }

  double get xpProgress => maxXp > 0 ? (currentXp / maxXp).clamp(0.0, 1.0) : 0.0;

  UserProfile copyWith({
    String? id,
    String? displayName,
    int? level,
    int? currentXp,
    int? maxXp,
    int? streakDays,
    double? mentalEnergy,
    String? avatarTitle,
    String? avatarId,
    int? creativityPoints,
    int? observationPoints,
    int? logicPoints,
    int? decisionMakingPoints,
    int? knowledgePoints,
    int? totalXp,
    int? totalExercisesCompleted,
    int? totalLessonsCompleted,
    int? totalQuizzesCompleted,
    int? totalWordsLearned,
    int? currentStreak,
    int? bestStreak,
    List<String>? unlockedAchievements,
    int? lastLevel,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      maxXp: maxXp ?? this.maxXp,
      streakDays: streakDays ?? this.streakDays,
      mentalEnergy: mentalEnergy ?? this.mentalEnergy,
      avatarTitle: avatarTitle ?? this.avatarTitle,
      avatarId: avatarId ?? this.avatarId,
      creativityPoints: creativityPoints ?? this.creativityPoints,
      observationPoints: observationPoints ?? this.observationPoints,
      logicPoints: logicPoints ?? this.logicPoints,
      decisionMakingPoints: decisionMakingPoints ?? this.decisionMakingPoints,
      knowledgePoints: knowledgePoints ?? this.knowledgePoints,
      totalXp: totalXp ?? this.totalXp,
      totalExercisesCompleted:
          totalExercisesCompleted ?? this.totalExercisesCompleted,
      totalLessonsCompleted:
          totalLessonsCompleted ?? this.totalLessonsCompleted,
      totalQuizzesCompleted:
          totalQuizzesCompleted ?? this.totalQuizzesCompleted,
      totalWordsLearned: totalWordsLearned ?? this.totalWordsLearned,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      unlockedAchievements: unlockedAchievements ?? this.unlockedAchievements,
      lastLevel: lastLevel ?? this.lastLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'level': level,
      'currentXp': currentXp,
      'maxXp': maxXp,
      'streakDays': streakDays,
      'mentalEnergy': mentalEnergy,
      'avatarTitle': avatarTitle,
      'avatarId': avatarId,
      'creativityPoints': creativityPoints,
      'observationPoints': observationPoints,
      'logicPoints': logicPoints,
      'decisionMakingPoints': decisionMakingPoints,
      'knowledgePoints': knowledgePoints,
      'totalXp': totalXp,
      'totalExercisesCompleted': totalExercisesCompleted,
      'totalLessonsCompleted': totalLessonsCompleted,
      'totalQuizzesCompleted': totalQuizzesCompleted,
      'totalWordsLearned': totalWordsLearned,
      'currentStreak': currentStreak,
      'bestStreak': bestStreak,
      'unlockedAchievements': unlockedAchievements,
      'lastLevel': lastLevel,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: (json['id'] as String?) ?? 'usr_001',
      displayName: (json['displayName'] as String?) ?? 'Alex Mindful',
      level: (json['level'] as int?) ?? 1,
      currentXp: (json['currentXp'] as int?) ?? 0,
      maxXp: (json['maxXp'] as int?) ?? 100,
      streakDays: (json['streakDays'] as int?) ?? 1,
      mentalEnergy: (json['mentalEnergy'] as num?)?.toDouble() ?? 0.85,
      avatarTitle: (json['avatarTitle'] as String?) ?? 'Forest Sage',
      avatarId: (json['avatarId'] as String?) ?? 'raccoon',
      creativityPoints: (json['creativityPoints'] as int?) ?? 0,
      observationPoints: (json['observationPoints'] as int?) ?? 0,
      logicPoints: (json['logicPoints'] as int?) ?? 0,
      decisionMakingPoints: (json['decisionMakingPoints'] as int?) ?? 0,
      knowledgePoints: (json['knowledgePoints'] as int?) ?? 0,
      totalXp: (json['totalXp'] as int?) ?? 0,
      totalExercisesCompleted: (json['totalExercisesCompleted'] as int?) ?? 0,
      totalLessonsCompleted: (json['totalLessonsCompleted'] as int?) ?? 0,
      totalQuizzesCompleted: (json['totalQuizzesCompleted'] as int?) ?? 0,
      totalWordsLearned: (json['totalWordsLearned'] as int?) ?? 0,
      currentStreak: (json['currentStreak'] as int?) ?? 1,
      bestStreak: (json['bestStreak'] as int?) ?? 1,
      unlockedAchievements:
          List<String>.from((json['unlockedAchievements'] as List?) ?? []),
      lastLevel: (json['lastLevel'] as int?) ?? 1,
    );
  }

  String toRawJson() => json.encode(toJson());

  factory UserProfile.fromRawJson(String str) =>
      UserProfile.fromJson(json.decode(str) as Map<String, dynamic>);
}
