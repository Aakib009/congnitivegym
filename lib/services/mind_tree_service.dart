import '../constants/reward_constants.dart';

/// Computed details for the current Mind Tree stage.
class MindTreeStageInfo {
  final int level;
  final String name;
  final String emoji;
  final int requiredPoints;
  final int? nextStageRequiredPoints;
  final double progressRatio; // 0.0 to 1.0
  final int pointsInCurrentStage;
  final int pointsNeededForNextStage;
  final bool isMaxLevel;

  const MindTreeStageInfo({
    required this.level,
    required this.name,
    required this.emoji,
    required this.requiredPoints,
    required this.nextStageRequiredPoints,
    required this.progressRatio,
    required this.pointsInCurrentStage,
    required this.pointsNeededForNextStage,
    required this.isMaxLevel,
  });

  String get displayName => '$emoji Level $level: $name';
  int get percentageCompleted => (progressRatio * 100).toInt();
}

/// Service managing stage Level (1-10) calculations, Mind Tree stage thresholds, and progress ratios.
class MindTreeService {
  MindTreeService._();

  static final MindTreeService instance = MindTreeService._();

  /// Returns the current [MindTreeStageInfo] corresponding to [totalPoints].
  MindTreeStageInfo getStageInfo(int totalPoints) {
    final stages = RewardConstants.stages;
    final points = totalPoints < 0 ? 0 : totalPoints;

    MindTreeStageData currentStage = stages.first;
    for (final stage in stages) {
      if (points >= stage.requiredPoints) {
        currentStage = stage;
      } else {
        break;
      }
    }

    final isMax = currentStage.level >= stages.last.level;
    final nextStage = isMax ? null : stages[currentStage.level];

    final minPts = currentStage.requiredPoints;
    final maxPts = nextStage?.requiredPoints ?? minPts;
    final range = maxPts - minPts;

    final ptsInStage = points - minPts;
    final ptsNeeded = isMax ? 0 : (maxPts - points);

    final ratio = isMax || range <= 0
        ? 1.0
        : (ptsInStage / range).clamp(0.0, 1.0);

    return MindTreeStageInfo(
      level: currentStage.level,
      name: currentStage.name,
      emoji: currentStage.emoji,
      requiredPoints: currentStage.requiredPoints,
      nextStageRequiredPoints: nextStage?.requiredPoints,
      progressRatio: ratio,
      pointsInCurrentStage: ptsInStage,
      pointsNeededForNextStage: ptsNeeded,
      isMaxLevel: isMax,
    );
  }

  /// Calculates level for total points.
  int getLevelForPoints(int totalPoints) {
    return getStageInfo(totalPoints).level;
  }

  /// Returns true if advancing from [oldPoints] to [newPoints] triggers a level up.
  bool didLevelUp(int oldPoints, int newPoints) {
    final oldLevel = getLevelForPoints(oldPoints);
    final newLevel = getLevelForPoints(newPoints);
    return newLevel > oldLevel;
  }
}
