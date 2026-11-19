import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../utils/app_colors.dart';

/// The 8 competitive rank tiers for Cognitive Gym.
enum CognitiveRankTier {
  bronze,
  silver,
  gold,
  platinum,
  crystal,
  diamond,
  master,
  grandmaster,
}

extension CognitiveRankTierExtension on CognitiveRankTier {
  String get title {
    switch (this) {
      case CognitiveRankTier.bronze:
        return 'Bronze';
      case CognitiveRankTier.silver:
        return 'Silver';
      case CognitiveRankTier.gold:
        return 'Gold';
      case CognitiveRankTier.platinum:
        return 'Platinum';
      case CognitiveRankTier.crystal:
        return 'Crystal';
      case CognitiveRankTier.diamond:
        return 'Diamond';
      case CognitiveRankTier.master:
        return 'Master';
      case CognitiveRankTier.grandmaster:
        return 'Grandmaster';
    }
  }

  Color get color {
    switch (this) {
      case CognitiveRankTier.bronze:
        return AppColors.rankBronze;
      case CognitiveRankTier.silver:
        return AppColors.rankSilver;
      case CognitiveRankTier.gold:
        return AppColors.rankGold;
      case CognitiveRankTier.platinum:
        return AppColors.rankPlatinum;
      case CognitiveRankTier.crystal:
        return AppColors.rankCrystal;
      case CognitiveRankTier.diamond:
        return AppColors.rankDiamond;
      case CognitiveRankTier.master:
        return AppColors.rankMaster;
      case CognitiveRankTier.grandmaster:
        return AppColors.rankGrandmaster;
    }
  }
}

/// Model encapsulating rank properties, visual colors, and progression thresholds.
class CognitiveRank {
  final CognitiveRankTier tier;
  final String name;
  final String title;
  final int minXp;
  final int minLevel;
  final int minMastery;
  final Color primaryColor;
  final Color secondaryColor;

  Color get color => primaryColor;

  const CognitiveRank({
    required this.tier,
    required this.name,
    required this.title,
    required this.minXp,
    required this.minLevel,
    required this.minMastery,
    required this.primaryColor,
    required this.secondaryColor,
  });

  /// All 8 rank tiers ordered sequentially from lowest to highest.
  static const List<CognitiveRank> allRanks = [
    CognitiveRank(
      tier: CognitiveRankTier.bronze,
      name: 'Bronze',
      title: 'Bronze Challenger',
      minXp: 0,
      minLevel: 1,
      minMastery: 0,
      primaryColor: AppColors.rankBronze,
      secondaryColor: Color(0xFF8C531B),
    ),
    CognitiveRank(
      tier: CognitiveRankTier.silver,
      name: 'Silver',
      title: 'Silver Tactician',
      minXp: 250,
      minLevel: 3,
      minMastery: 100,
      primaryColor: AppColors.rankSilver,
      secondaryColor: Color(0xFF64748B),
    ),
    CognitiveRank(
      tier: CognitiveRankTier.gold,
      name: 'Gold',
      title: 'Gold Strategist',
      minXp: 750,
      minLevel: 8,
      minMastery: 300,
      primaryColor: AppColors.rankGold,
      secondaryColor: Color(0xFFB45309),
    ),
    CognitiveRank(
      tier: CognitiveRankTier.platinum,
      name: 'Platinum',
      title: 'Platinum Vanguard',
      minXp: 1800,
      minLevel: 18,
      minMastery: 800,
      primaryColor: AppColors.rankPlatinum,
      secondaryColor: Color(0xFF0284C7),
    ),
    CognitiveRank(
      tier: CognitiveRankTier.crystal,
      name: 'Crystal',
      title: 'Crystal Paragon',
      minXp: 3500,
      minLevel: 35,
      minMastery: 1500,
      primaryColor: AppColors.rankCrystal,
      secondaryColor: Color(0xFF7E22CE),
    ),
    CognitiveRank(
      tier: CognitiveRankTier.diamond,
      name: 'Diamond',
      title: 'Diamond Sentinel',
      minXp: 6000,
      minLevel: 60,
      minMastery: 2800,
      primaryColor: AppColors.rankDiamond,
      secondaryColor: Color(0xFF0891B2),
    ),
    CognitiveRank(
      tier: CognitiveRankTier.master,
      name: 'Master',
      title: 'Cognitive Master',
      minXp: 10000,
      minLevel: 100,
      minMastery: 4500,
      primaryColor: AppColors.rankMaster,
      secondaryColor: Color(0xFFBE185D),
    ),
    CognitiveRank(
      tier: CognitiveRankTier.grandmaster,
      name: 'Grandmaster',
      title: 'Apex Grandmaster',
      minXp: 15000,
      minLevel: 150,
      minMastery: 7000,
      primaryColor: AppColors.rankGrandmaster,
      secondaryColor: Color(0xFFA16207),
    ),
  ];

  /// Calculates total cognitive domain mastery points for a user profile.
  static int totalMasteryForProfile(UserProfile profile) {
    return profile.creativityPoints +
        profile.observationPoints +
        profile.logicPoints +
        profile.decisionMakingPoints +
        profile.knowledgePoints;
  }

  /// Resolves the user's active rank based on strict conjunction:
  /// Overall XP AND Account Level AND Cognitive Domain Mastery.
  static CognitiveRank getRankForProfile(UserProfile profile) {
    final mastery = totalMasteryForProfile(profile);
    final xp = profile.totalXp;
    final level = profile.level;

    for (int i = allRanks.length - 1; i >= 0; i--) {
      final rank = allRanks[i];
      if (xp >= rank.minXp && level >= rank.minLevel && mastery >= rank.minMastery) {
        return rank;
      }
    }
    return allRanks.first;
  }

  /// Returns the next sequential rank tier, or null if already Grandmaster.
  CognitiveRank? get nextRank {
    final idx = allRanks.indexOf(this);
    if (idx >= 0 && idx < allRanks.length - 1) {
      return allRanks[idx + 1];
    }
    return null;
  }

  /// Calculates progression ratio (0.0 to 1.0) towards the next rank based on XP.
  double getProgressToNext(UserProfile profile) {
    final next = nextRank;
    if (next == null) return 1.0;

    final currentBaseXp = minXp;
    final nextTargetXp = next.minXp;
    final range = nextTargetXp - currentBaseXp;
    if (range <= 0) return 1.0;

    final progress = (profile.totalXp - currentBaseXp) / range;
    return progress.clamp(0.0, 1.0);
  }

  /// Calculates XP remaining until the next rank tier.
  int getXpNeededForNext(UserProfile profile) {
    final next = nextRank;
    if (next == null) return 0;
    final needed = next.minXp - profile.totalXp;
    return needed > 0 ? needed : 0;
  }

  /// Evaluates and reports exact requirement satisfaction status for a profile.
  RankRequirementStatus getRequirementStatus(UserProfile profile) {
    final mastery = totalMasteryForProfile(profile);
    return RankRequirementStatus(
      targetRank: this,
      isXpMet: profile.totalXp >= minXp,
      currentXp: profile.totalXp,
      requiredXp: minXp,
      isLevelMet: profile.level >= minLevel,
      currentLevel: profile.level,
      requiredLevel: minLevel,
      isMasteryMet: mastery >= minMastery,
      currentMastery: mastery,
      requiredMastery: minMastery,
    );
  }
}

/// Status of requirements needed to attain a target rank.
class RankRequirementStatus {
  final CognitiveRank targetRank;
  final bool isXpMet;
  final int currentXp;
  final int requiredXp;

  final bool isLevelMet;
  final int currentLevel;
  final int requiredLevel;

  final bool isMasteryMet;
  final int currentMastery;
  final int requiredMastery;

  const RankRequirementStatus({
    required this.targetRank,
    required this.isXpMet,
    required this.currentXp,
    required this.requiredXp,
    required this.isLevelMet,
    required this.currentLevel,
    required this.requiredLevel,
    required this.isMasteryMet,
    required this.currentMastery,
    required this.requiredMastery,
  });

  /// All 3 requirements (XP, Level, AND Cognitive Mastery) must be satisfied.
  bool get isAllMet => isXpMet && isLevelMet && isMasteryMet;

  int get xpNeeded => (requiredXp - currentXp) > 0 ? (requiredXp - currentXp) : 0;
  int get levelsNeeded => (requiredLevel - currentLevel) > 0 ? (requiredLevel - currentLevel) : 0;
  int get masteryNeeded => (requiredMastery - currentMastery) > 0 ? (requiredMastery - currentMastery) : 0;
}
