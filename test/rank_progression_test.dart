import 'package:cognitive_gym/models/rank_model.dart';
import 'package:cognitive_gym/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CognitiveRank Strict AND Eligibility Boundary Tests', () {
    test('User at baseline is Bronze', () {
      final profile = UserProfile.mock();
      final rank = CognitiveRank.getRankForProfile(profile);
      expect(rank.tier, CognitiveRankTier.bronze);
    });

    test('Boundary: Satisfying XP and Level but NOT Mastery keeps user at Bronze (cannot unlock Silver)', () {
      final profile = UserProfile.mock().copyWith(
        totalXp: 500, // Meets Silver minXp: 250
        level: 4,     // Meets Silver minLevel: 3
        creativityPoints: 50,
        observationPoints: 49, // Total mastery = 99 (below minMastery: 100)
        logicPoints: 0,
        decisionMakingPoints: 0,
        knowledgePoints: 0,
      );

      final rank = CognitiveRank.getRankForProfile(profile);
      expect(rank.tier, CognitiveRankTier.bronze);

      final nextRank = rank.nextRank!;
      final status = nextRank.getRequirementStatus(profile);
      expect(status.isXpMet, true);
      expect(status.isLevelMet, true);
      expect(status.isMasteryMet, false);
      expect(status.isAllMet, false);
      expect(status.masteryNeeded, 1);
    });

    test('Boundary: Satisfying XP and Mastery but NOT Level keeps user at Bronze (cannot unlock Silver)', () {
      final profile = UserProfile.mock().copyWith(
        totalXp: 500, // Meets Silver minXp: 250
        level: 2,     // Below Silver minLevel: 3
        creativityPoints: 50,
        observationPoints: 60, // Total mastery = 110 (meets minMastery: 100)
        logicPoints: 0,
        decisionMakingPoints: 0,
        knowledgePoints: 0,
      );

      final rank = CognitiveRank.getRankForProfile(profile);
      expect(rank.tier, CognitiveRankTier.bronze);

      final nextRank = rank.nextRank!;
      final status = nextRank.getRequirementStatus(profile);
      expect(status.isXpMet, true);
      expect(status.isLevelMet, false);
      expect(status.isMasteryMet, true);
      expect(status.isAllMet, false);
      expect(status.levelsNeeded, 1);
    });

    test('Boundary: Satisfying Level and Mastery but NOT XP keeps user at Bronze (cannot unlock Silver)', () {
      final profile = UserProfile.mock().copyWith(
        totalXp: 249, // Below Silver minXp: 250
        level: 5,     // Meets Silver minLevel: 3
        creativityPoints: 60,
        observationPoints: 60, // Total mastery = 120 (meets minMastery: 100)
        logicPoints: 0,
        decisionMakingPoints: 0,
        knowledgePoints: 0,
      );

      final rank = CognitiveRank.getRankForProfile(profile);
      expect(rank.tier, CognitiveRankTier.bronze);

      final nextRank = rank.nextRank!;
      final status = nextRank.getRequirementStatus(profile);
      expect(status.isXpMet, false);
      expect(status.isLevelMet, true);
      expect(status.isMasteryMet, true);
      expect(status.isAllMet, false);
      expect(status.xpNeeded, 1);
    });

    test('All 3 requirements satisfied promotes user to Silver', () {
      final profile = UserProfile.mock().copyWith(
        totalXp: 250,
        level: 3,
        creativityPoints: 50,
        observationPoints: 50, // Total mastery = 100
        logicPoints: 0,
        decisionMakingPoints: 0,
        knowledgePoints: 0,
      );

      final rank = CognitiveRank.getRankForProfile(profile);
      expect(rank.tier, CognitiveRankTier.silver);
    });

    test('Boundary for Gold: Missing 1 of 3 criteria stays Silver', () {
      // Missing Mastery
      final p1 = UserProfile.mock().copyWith(
        totalXp: 1000, // Meets Gold minXp: 750
        level: 10,     // Meets Gold minLevel: 8
        creativityPoints: 150,
        observationPoints: 149, // Total mastery = 299 (below Gold minMastery: 300)
      );
      expect(CognitiveRank.getRankForProfile(p1).tier, CognitiveRankTier.silver);

      // Missing Level
      final p2 = UserProfile.mock().copyWith(
        totalXp: 1000,
        level: 7, // Below Gold minLevel: 8
        creativityPoints: 150,
        observationPoints: 160, // Total mastery = 310
      );
      expect(CognitiveRank.getRankForProfile(p2).tier, CognitiveRankTier.silver);

      // Missing XP
      final p3 = UserProfile.mock().copyWith(
        totalXp: 749, // Below Gold minXp: 750
        level: 10,
        creativityPoints: 150,
        observationPoints: 160,
      );
      expect(CognitiveRank.getRankForProfile(p3).tier, CognitiveRankTier.silver);

      // All 3 satisfied -> Gold
      final p4 = UserProfile.mock().copyWith(
        totalXp: 750,
        level: 8,
        creativityPoints: 150,
        observationPoints: 150, // Total mastery = 300
      );
      expect(CognitiveRank.getRankForProfile(p4).tier, CognitiveRankTier.gold);
    });
  });
}
