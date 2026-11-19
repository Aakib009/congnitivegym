/// Centralized constants storing all Mind Tree & gamification point rewards.
class RewardConstants {
  RewardConstants._();

  // ===========================================================================
  // MIND TREE STAGES (10 LEVELS)
  // ===========================================================================
  static const List<MindTreeStageData> stages = [
    MindTreeStageData(level: 1, name: 'Seed', emoji: '🌱', requiredPoints: 0),
    MindTreeStageData(level: 2, name: 'Sprout', emoji: '🌿', requiredPoints: 150),
    MindTreeStageData(level: 3, name: 'Sapling', emoji: '🍃', requiredPoints: 400),
    MindTreeStageData(level: 4, name: 'Young Tree', emoji: '🌳', requiredPoints: 800),
    MindTreeStageData(level: 5, name: 'Growing Oak', emoji: '🌲', requiredPoints: 1500),
    MindTreeStageData(level: 6, name: 'Strong Oak', emoji: '🌴', requiredPoints: 2500),
    MindTreeStageData(level: 7, name: 'Wisdom Tree', emoji: '🌟', requiredPoints: 4000),
    MindTreeStageData(level: 8, name: 'Ancient Tree', emoji: '🔥', requiredPoints: 6000),
    MindTreeStageData(level: 9, name: 'World Tree', emoji: '💎', requiredPoints: 9000),
    MindTreeStageData(level: 10, name: 'Tree of Mastery', emoji: '👑', requiredPoints: 13000),
  ];

  // ===========================================================================
  // LESSON REWARDS
  // ===========================================================================
  static const int completeLesson = 20;
  static const int perfectLesson = 10;
  static const int firstAttemptPerfect = 15;
  static const int completeChapterLessons = 50;

  // ===========================================================================
  // QUIZ REWARDS
  // ===========================================================================
  static const int completeQuiz = 30;
  static const int scoreAbove80 = 15;
  static const int score100 = 25;
  static const int beatPreviousBest = 10;

  // ===========================================================================
  // VOCABULARY REWARDS
  // ===========================================================================
  static const int learnNewWord = 2;
  static const int reviewLearnedWord = 3;
  static const int masterWord = 10;
  static const int learn10WordsDailyBonus = 25;

  // ===========================================================================
  // PRACTICE ACTIVITIES
  // ===========================================================================
  static const int speakingPractice = 25;
  static const int listeningPractice = 25;
  static const int writingPractice = 30;
  static const int grammarExercise = 20;
  static const int pronunciationExercise = 25;

  // ===========================================================================
  // MINI GAMES
  // ===========================================================================
  static const int wordMatch = 15;
  static const int fillInTheBlank = 20;
  static const int wordBuilder = 20;
  static const int sentenceBuilder = 25;
  static const int speedChallenge = 30;

  // ===========================================================================
  // DAILY GOALS
  // ===========================================================================
  static const int completeDailyGoal = 50;
  static const int completeBeforeNoonBonus = 15;
  static const int completeAllWeeklyDailyGoals = 200;

  // ===========================================================================
  // DAILY LOGIN
  // ===========================================================================
  static const int dailyLogin = 10;
  static const int loginStreak7Day = 100;
  static const int loginStreak30Day = 500;

  // ===========================================================================
  // DAILY LEARNING STREAK
  // ===========================================================================
  static const Map<int, int> dailyStreakBonusMap = {
    1: 10,
    2: 15,
    3: 20,
    4: 25,
    5: 30,
    6: 35,
  };
  static const int maxDailyStreakBonus = 40; // Day 7 and beyond

  static int getDailyStreakBonus(int dayCount) {
    if (dayCount <= 0) return 0;
    return dailyStreakBonusMap[dayCount] ?? maxDailyStreakBonus;
  }

  // ===========================================================================
  // WEEKLY STREAK REWARDS
  // ===========================================================================
  static const int study5DaysWeekly = 100;
  static const int study7DaysWeekly = 200;
  static const int streak14Day = 400;
  static const int streak30Day = 800;
  static const int streak100Day = 2500;

  // ===========================================================================
  // ACHIEVEMENTS
  // ===========================================================================
  static const int achievementFirstLesson = 50;
  static const int achievementFirstPerfectLesson = 100;
  static const int achievementLearn100Words = 200;
  static const int achievementLearn500Words = 500;
  static const int achievementLearn1000Words = 1200;
  static const int achievementCompleteBeginnerCourse = 500;
  static const int achievementCompleteIntermediateCourse = 900;
  static const int achievementCompleteAdvancedCourse = 1500;

  // ===========================================================================
  // STUDY TIME BONUSES
  // ===========================================================================
  static const Map<int, int> studyTimeBonusMap = {
    15: 15,
    30: 30,
    45: 45,
    60: 60, // Daily cap
  };

  // ===========================================================================
  // CHALLENGE REWARDS
  // ===========================================================================
  static const int dailyChallenge = 40;
  static const int weeklyChallenge = 250;
  static const int monthlyChallenge = 800;

  // ===========================================================================
  // LEADERBOARD
  // ===========================================================================
  static const int leaderboardTop50 = 100;
  static const int leaderboardTop10 = 250;
  static const int leaderboardRank1 = 1000;

  // ===========================================================================
  // HIDDEN ACHIEVEMENTS
  // ===========================================================================
  static const int hiddenMidnightStudy = 50;
  static const int hiddenTenPerfectScores = 200;
  static const int hiddenThirtyDayStreak = 1000;
  static const int hiddenBeginnerNoMistakes = 500;
  static const int hiddenHundredConsecutiveCorrect = 750;
}

/// Data class holding stage thresholds and Metadata for Mind Tree stages.
class MindTreeStageData {
  final int level;
  final String name;
  final String emoji;
  final int requiredPoints;

  const MindTreeStageData({
    required this.level,
    required this.name,
    required this.emoji,
    required this.requiredPoints,
  });

  String get displayName => '$emoji Level $level: $name';
}
