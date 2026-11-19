import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/debate_session.dart';
import '../models/debate_topic.dart';
import '../routes/app_router.dart';
import '../services/debate_arena_service.dart';
import '../utils/app_colors.dart';
import '../widgets/gym_card.dart';

/// Screen listing curated debate topics in a two-column grid.
class DebateArenaScreen extends StatelessWidget {
  const DebateArenaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topics = DebateArenaService.getAllTopics();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debate Arena'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            itemCount: topics.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 280,
            ),
            itemBuilder: (context, index) {
              final topic = topics[index];
              return _buildTopicGridCard(context, theme, topic);
            },
          ),
        ),
      ),
    );
  }

  /// Topic card: quiet surface, category color only on the tag text.
  Widget _buildTopicGridCard(
    BuildContext context,
    ThemeData theme,
    DebateTopic topic,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return GymCard(
      padding: const EdgeInsets.all(14),
      onTap: () => _showStanceSelectionSheet(context, topic),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceContainerHigh
                      : AppColors.surfaceLightClean,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLightClean,
                    width: 1,
                  ),
                ),
                child: Icon(topic.icon, size: 16, color: mutedColor),
              ),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceContainerHigh
                        : AppColors.surfaceLightClean,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    topic.category,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.puzzleGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (topic.imagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 88,
                width: double.infinity,
                child: Image.asset(
                  topic.imagePath!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: isDark
                        ? AppColors.surfaceContainerLow
                        : AppColors.surfaceLightClean,
                    child: Center(
                      child: Icon(topic.icon, color: mutedColor, size: 24),
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          Text(
            topic.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(height: 1.25),
          ),

          const SizedBox(height: 4),

          Expanded(
            child: Text(
              topic.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.3,
                color: mutedColor,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Start debate',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Stance selection sheet allowing users to choose support or oppose.
  void _showStanceSelectionSheet(BuildContext context, DebateTopic topic) {
    DebateSide selectedSide = DebateSide.support;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLightClean,
                  width: 1,
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black26,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Choose your stance',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),

                    Text(
                      topic.title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      topic.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mutedColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 18),

                    _buildStanceTile(
                      context: context,
                      title: 'Support',
                      subtitle: 'Argue in favor of this position',
                      icon: Icons.thumb_up_alt_outlined,
                      isSelected: selectedSide == DebateSide.support,
                      onTap: () {
                        setSheetState(() => selectedSide = DebateSide.support);
                      },
                    ),

                    const SizedBox(height: 8),

                    _buildStanceTile(
                      context: context,
                      title: 'Oppose',
                      subtitle: 'Argue against this position',
                      icon: Icons.thumb_down_alt_outlined,
                      isSelected: selectedSide == DebateSide.oppose,
                      onTap: () {
                        setSheetState(() => selectedSide = DebateSide.oppose);
                      },
                    ),

                    const SizedBox(height: 20),

                    FilledButton(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        context.push(
                          AppRouter.debateChatRoute,
                          extra: {
                            'topic': topic,
                            'userSide': selectedSide,
                          },
                        );
                      },
                      child: const Text('Enter arena'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStanceTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = theme.colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.surfaceContainerHigh
                  : AppColors.surfaceLightClean)
              : (isDark
                  ? AppColors.surfaceContainerLow
                  : AppColors.cardLight),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? accent
                : (isDark ? AppColors.borderDark : AppColors.borderLightClean),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? accent
                  : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? accent : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected
                  ? accent
                  : (isDark ? Colors.white30 : Colors.black26),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
