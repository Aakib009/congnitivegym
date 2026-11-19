import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/rank_model.dart';
import '../models/user_profile.dart';
import '../utils/app_colors.dart';
import 'rank_emblem.dart';

/// Hero centerpiece widget for the Dashboard.
/// Replaces the botanical tree with an authentic, gaming-inspired Cognitive Rank Arena showcase.
class RankArenaCard extends StatelessWidget {
  final UserProfile user;

  const RankArenaCard({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentRank = CognitiveRank.getRankForProfile(user);
    final nextRank = currentRank.nextRank;
    final progressToNext = currentRank.getProgressToNext(user);
    final xpNeeded = currentRank.getXpNeededForNext(user);
    final totalMastery = CognitiveRank.totalMasteryForProfile(user);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? currentRank.primaryColor.withAlpha(90)
              : currentRank.primaryColor.withAlpha(120),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 35 : 12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Integrated Card Header: Cognitive Arena
          Row(
            children: [
              const Text(
                '🧠',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'Cognitive Arena',
                style: GoogleFonts.barlowCondensed(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Top Row: Rank Emblem Left, Title & Level Right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.groundDark
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: currentRank.primaryColor.withAlpha(120),
                    width: 1.0,
                  ),
                ),
                child: RankEmblem(
                  tier: currentRank.tier,
                  size: 52,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: currentRank.primaryColor.withAlpha(35),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: currentRank.primaryColor.withAlpha(140),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'TIER ${currentRank.tier.index + 1} / 8',
                            style: TextStyle(
                              color: currentRank.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'LVL ${user.level}',
                          style: TextStyle(
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentRank.title.toUpperCase(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${user.totalXp} Total XP • $totalMastery Skill Points',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 2. Progression Bar to Next Tier
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  nextRank != null
                      ? 'NEXT: ${nextRank.name.toUpperCase()}'
                      : 'APEX STATUS ATTAINED',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  nextRank != null
                      ? '$xpNeeded XP to advance'
                      : 'Maximum Tier',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: currentRank.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: progressToNext,
              minHeight: 6,
              backgroundColor: isDark
                  ? AppColors.borderDark
                  : AppColors.borderLightClean,
              valueColor: AlwaysStoppedAnimation<Color>(currentRank.primaryColor),
            ),
          ),

          const SizedBox(height: 12),

          // 2b. Requirements Breakdown Checklist (Satisfied vs Unmet)
          if (nextRank != null) ...[
            Builder(
              builder: (context) {
                final status = nextRank.getRequirementStatus(user);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.groundDark : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLightClean,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildRequirementPill(
                        label: 'XP',
                        current: status.currentXp,
                        required: status.requiredXp,
                        isMet: status.isXpMet,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 6),
                      _buildRequirementPill(
                        label: 'LVL',
                        current: status.currentLevel,
                        required: status.requiredLevel,
                        isMet: status.isLevelMet,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 6),
                      _buildRequirementPill(
                        label: 'MASTERY',
                        current: status.currentMastery,
                        required: status.requiredMastery,
                        isMet: status.isMasteryMet,
                        isDark: isDark,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
          ],

          // 3. Domain Mastery Segmented Pills
          Row(
            children: [
              _buildDomainPip(
                label: 'CRE',
                value: user.creativityPoints,
                color: AppColors.mathYellow,
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              _buildDomainPip(
                label: 'OBS',
                value: user.observationPoints,
                color: AppColors.memoryBlue,
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              _buildDomainPip(
                label: 'LOG',
                value: user.logicPoints,
                color: AppColors.puzzleGreen,
                isDark: isDark,
              ),
              const SizedBox(width: 6),
              _buildDomainPip(
                label: 'DEC',
                value: user.decisionMakingPoints,
                color: AppColors.eventOrange,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDomainPip({
    required String label,
    required int value,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.groundDark : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: color.withAlpha(70),
            width: 1.0,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$value',
              style: TextStyle(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementPill({
    required String label,
    required int current,
    required int required,
    required bool isMet,
    required bool isDark,
  }) {
    final statusColor = isMet ? AppColors.primaryLimeDark : AppColors.accentYellow;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        decoration: BoxDecoration(
          color: statusColor.withAlpha(isDark ? 20 : 15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: statusColor.withAlpha(isDark ? 80 : 100),
            width: 1.0,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isMet ? Icons.check_circle_rounded : Icons.pending_outlined,
                  size: 10,
                  color: statusColor,
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              isMet ? '$current' : '$current/$required',
              style: TextStyle(
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

