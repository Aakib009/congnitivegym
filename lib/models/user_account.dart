import 'animal_avatar.dart';

/// Model representing a user's account and profile persisted in SQLite.
class UserAccount {
  final String id;
  final String fullName;
  final String username;
  final String email;
  final String password;
  final String profileImage;
  final int totalXP;
  final int creativityPoints;
  final int observationPoints;
  final int logicPoints;
  final int decisionMakingPoints;
  final int knowledgePoints;
  final int exercisesCompleted;
  final int treeStage;
  final String currentRank;
  final String createdAt;

  const UserAccount({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.password,
    this.profileImage = 'assets/images/raccoon_avatar.png',
    this.totalXP = 0,
    this.creativityPoints = 0,
    this.observationPoints = 0,
    this.logicPoints = 0,
    this.decisionMakingPoints = 0,
    this.knowledgePoints = 0,
    this.exercisesCompleted = 0,
    this.treeStage = 1,
    this.currentRank = 'Forest Sage',
    required this.createdAt,
  });

  /// Normalized avatar ID (e.g. 'elephant', 'tiger', 'raccoon', etc.)
  String get avatarId => AppAvatars.normalize(profileImage);

  /// Factory constructor to convert SQLite database map to UserAccount.
  factory UserAccount.fromMap(Map<String, dynamic> map) {
    return UserAccount(
      id: (map['id'] as String?) ?? '',
      fullName: (map['fullName'] as String?) ?? '',
      username: (map['username'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      password: (map['password'] as String?) ?? '',
      profileImage: (map['profileImage'] as String?) ?? 'assets/images/raccoon_avatar.png',
      totalXP: (map['totalXP'] as int?) ?? 0,
      creativityPoints: (map['creativityPoints'] as int?) ?? 0,
      observationPoints: (map['observationPoints'] as int?) ?? 0,
      logicPoints: (map['logicPoints'] as int?) ?? 0,
      decisionMakingPoints: (map['decisionMakingPoints'] as int?) ?? 0,
      knowledgePoints: (map['knowledgePoints'] as int?) ?? 0,
      exercisesCompleted: (map['exercisesCompleted'] as int?) ?? 0,
      treeStage: (map['treeStage'] as int?) ?? 1,
      currentRank: (map['currentRank'] as String?) ?? 'Forest Sage',
      createdAt: (map['createdAt'] as String?) ?? DateTime.now().toIso8601String(),
    );
  }

  /// Converts UserAccount object to a Map for SQLite insertion/updating.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'username': username,
      'email': email,
      'password': password,
      'profileImage': profileImage,
      'totalXP': totalXP,
      'creativityPoints': creativityPoints,
      'observationPoints': observationPoints,
      'logicPoints': logicPoints,
      'decisionMakingPoints': decisionMakingPoints,
      'knowledgePoints': knowledgePoints,
      'exercisesCompleted': exercisesCompleted,
      'treeStage': treeStage,
      'currentRank': currentRank,
      'createdAt': createdAt,
    };
  }

  /// Returns a copy of the UserAccount with updated fields.
  UserAccount copyWith({
    String? id,
    String? fullName,
    String? username,
    String? email,
    String? password,
    String? profileImage,
    int? totalXP,
    int? creativityPoints,
    int? observationPoints,
    int? logicPoints,
    int? decisionMakingPoints,
    int? knowledgePoints,
    int? exercisesCompleted,
    int? treeStage,
    String? currentRank,
    String? createdAt,
  }) {
    return UserAccount(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      profileImage: profileImage ?? this.profileImage,
      totalXP: totalXP ?? this.totalXP,
      creativityPoints: creativityPoints ?? this.creativityPoints,
      observationPoints: observationPoints ?? this.observationPoints,
      logicPoints: logicPoints ?? this.logicPoints,
      decisionMakingPoints: decisionMakingPoints ?? this.decisionMakingPoints,
      knowledgePoints: knowledgePoints ?? this.knowledgePoints,
      exercisesCompleted: exercisesCompleted ?? this.exercisesCompleted,
      treeStage: treeStage ?? this.treeStage,
      currentRank: currentRank ?? this.currentRank,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
