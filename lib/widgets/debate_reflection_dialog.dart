import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/debate_session.dart';
import '../utils/app_colors.dart';
import 'gym_card.dart';

/// Reflection dialog shown upon completing a debate session.
/// Displays transparent rule-based metrics across relevance, reasoning, structure, and clarity.
class DebateReflectionDialog extends StatelessWidget {
  final DebateSession session;
  final VoidCallback? onComplete;

  const DebateReflectionDialog({
    super.key,
    required this.session,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.brandLime : AppColors.primaryLimeLight;

    final userSideText =
        session.userSide == DebateSide.support ? 'Support' : 'Oppose';
    final opponentSideText =
        session.aiSide == DebateSide.support ? 'Support' : 'Oppose';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GymCard(
        padding: const EdgeInsets.all(22),
        backgroundColor: isDark ? AppColors.surface : Colors.white,
        borderColor: isDark ? AppColors.borderSubtle : AppColors.borderLightClean,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceContainerHigh
                      : AppColors.surfaceLightClean,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLightClean,
                  ),
                ),
                child: Icon(
                  Icons.school_outlined,
                  size: 22,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'Debate reflection',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),

              Text(
                session.topic.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem(theme, 'Your stance', userSideText, isDark),
                  _buildStatItem(theme, 'Opponent', opponentSideText, isDark),
                  _buildStatItem(
                    theme,
                    'Turns',
                    '${session.messages.where((m) => m.isUser).length}',
                    isDark,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDeep : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderSubtle
                        : AppColors.borderLightClean,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Logic evaluation',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${session.performanceScore ?? 0} / 100',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    _buildCriteriaRow(
                        theme, 'Relevance to proposition', '${session.relevanceScore ?? 0} / 25', isDark),
                    _buildCriteriaRow(
                        theme, 'Deductive reasoning', '${session.reasoningScore ?? 0} / 30', isDark),
                    _buildCriteriaRow(
                        theme, 'Counterargument structure', '${session.structureScore ?? 0} / 25', isDark),
                    _buildCriteriaRow(
                        theme, 'Clarity', '${session.clarityScore ?? 0} / 20', isDark),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceContainerLow
                      : AppColors.surfaceLightClean,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderSubtle
                        : AppColors.borderLightClean,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, color: accent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      session.earnedXp == null && session.logicPointsEarned == null
                          ? 'Debate completed'
                          : '+${session.logicPointsEarned ?? 0} logic points, +${session.earnedXp ?? 0} XP',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (onComplete != null) {
                      onComplete!();
                    } else {
                      context.pop();
                    }
                  },
                  child: const Text('Complete exercise'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    bool isDark,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCriteriaRow(
    ThemeData theme,
    String title,
    String score,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
              ),
            ),
          ),
          Text(
            score,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
