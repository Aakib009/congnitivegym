import 'package:flutter/material.dart';

import '../models/mind_tree_level_config.dart';
import '../models/user_profile.dart';
import '../services/progress_service.dart';
import '../services/mind_tree_service.dart';
import '../utils/app_colors.dart';
import '../widgets/gym_card.dart';
import '../widgets/mind_tree_widget.dart';

/// Full-screen Mind Tree experience showing the user's cognitive growth journey.
///
/// Displays the tree visualization, level progress, and skill metrics.
class MindTreeScreen extends StatefulWidget {
  const MindTreeScreen({super.key});

  @override
  State<MindTreeScreen> createState() => _MindTreeScreenState();
}

class _MindTreeScreenState extends State<MindTreeScreen> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ProgressService.instance,
      builder: (context, _) {
        final profile = ProgressService.instance.userProfile;
        final stageInfo = MindTreeService.instance.getStageInfo(profile.totalXp);
        final config = MindTreeLevelConfig.forLevel(stageInfo.level);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Mind Tree'),
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline_rounded),
                tooltip: 'About Mind Tree',
                onPressed: () => _showInfoDialog(context, config),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  MindTreeWidget(
                    level: stageInfo.level,
                    progress: stageInfo.progressRatio,
                    animate: true,
                  ),

                  const SizedBox(height: 20),

                  _buildProgressSection(context, stageInfo, config),

                  const SizedBox(height: 16),

                  _buildSkillMetrics(context, profile),

                  const SizedBox(height: 16),

                  _buildSkillLegend(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressSection(BuildContext context, dynamic stageInfo, MindTreeLevelConfig config) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppColors.brandLime : AppColors.primaryLimeLight;

    return GymCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Level ${stageInfo.level}',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 2),
          Text(
            config.title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
            ),
          ),

          const SizedBox(height: 16),

          if (!stageInfo.isMaxLevel) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: stageInfo.progressRatio,
                minHeight: 10,
                backgroundColor: isDark
                    ? AppColors.surfaceContainerHigh
                    : AppColors.surfaceLightClean,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${stageInfo.pointsInCurrentStage} / ${stageInfo.pointsNeededForNextStage + stageInfo.pointsInCurrentStage} XP',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Next: Level ${stageInfo.level + 1} - ${_getNextLevelTitle(stageInfo.level + 1)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ] else ...[
            Icon(
              Icons.emoji_events_outlined,
              color: accent,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              'Maximum level reached',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Your tree has reached its final stage.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillMetrics(BuildContext context, UserProfile profile) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final skills = [
      ('Memory', profile.observationPoints + profile.knowledgePoints, Icons.psychology_outlined),
      ('Observation', profile.observationPoints, Icons.visibility_outlined),
      ('Critical thinking', profile.logicPoints, Icons.psychology_alt_outlined),
      ('Creativity', profile.creativityPoints, Icons.palette_outlined),
      ('Decision making', profile.decisionMakingPoints, Icons.alt_route_outlined),
    ];

    return GymCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skill progress',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 16),
          ...skills.map((skill) => _buildSkillBar(
            context,
            skill.$1,
            skill.$2,
            skill.$3,
            isDark,
          )),
        ],
      ),
    );
  }

  Widget _buildSkillBar(
    BuildContext context,
    String label,
    int points,
    IconData icon,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final accent = isDark ? AppColors.brandLime : AppColors.primaryLimeLight;
    final score = (points / 150.0 * 100.0).clamp(0.0, 100.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${score.round()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 6,
                    backgroundColor: isDark
                        ? AppColors.surfaceContainerHigh
                        : AppColors.surfaceLightClean,
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillLegend(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GymCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tree growth mapping',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          _buildLegendItem('Leaves', 'Memory', AppColors.leafGreen, isDark),
          _buildLegendItem('Branches', 'Observation', AppColors.pineGreen, isDark),
          _buildLegendItem('Trunk', 'Critical thinking', AppColors.terracotta, isDark),
          _buildLegendItem('Flowers', 'Creativity', AppColors.solarYellow, isDark),
          _buildLegendItem('Fruit', 'Decision making', AppColors.warningOrange, isDark),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String treePart, String skill, Color color, bool isDark) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$treePart - $skill',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getNextLevelTitle(int level) {
    if (level < 0 || level > 10) return '';
    return MindTreeLevelConfig.forLevel(level).title;
  }

  void _showInfoDialog(BuildContext context, MindTreeLevelConfig config) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('About Mind Tree'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Mind Tree represents your cognitive growth journey.',
            ),
            const SizedBox(height: 12),
            Text(
              'Current level: ${config.level} - ${config.title}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(config.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
