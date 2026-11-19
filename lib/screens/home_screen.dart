import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/rank_model.dart';
import '../models/user_profile.dart';
import '../routes/app_router.dart';
import '../services/progress_service.dart';
import '../utils/app_colors.dart';
import '../widgets/gym_card.dart';
import '../widgets/raccoon_avatar.dart';
import '../widgets/rank_arena_card.dart';
import '../widgets/section_header.dart';

/// Home screen for Cognitive Gym: live status and stat chips, daily
/// challenges, discipline filters, workout modules, the adaptive top pick,
/// daily quests and lifetime stats. Quiet chrome, one lime accent, discipline
/// colors used only where they identify a discipline.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'ALL';

  static const _categoryTabs = [
    ('All', 'ALL'),
    ('Creativity', 'CREATIVITY'),
    ('Observation', 'OBSERVATION'),
    ('Logic', 'LOGIC'),
    ('Decision', 'DECISION'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: ProgressService.instance,
      builder: (context, _) {
        final user = ProgressService.instance.userProfile;
        final currentRank = CognitiveRank.getRankForProfile(user);

        return Scaffold(
          appBar: _buildTopBar(context, user, currentRank),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 960;

                final mainStage = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RankArenaCard(user: user),
                    const SizedBox(height: 16),
                    _buildDailyChallengesBanner(context, user, isDark),
                    const SizedBox(height: 16),
                    _buildCategoryFilterSection(context, isDark),
                    const SizedBox(height: 16),
                    _buildWorkoutModulesGrid(context, isDark),
                  ],
                );

                final sideColumn = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionHeader(
                      title: 'Telemetry overview',
                      subtitle: 'Cognitive metrics for the active session',
                    ),
                    const SizedBox(height: 8),
                    _buildTelemetryGrid(context, user, isDark),
                  ],
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1600),
                      child: isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 7, child: mainStage),
                                const SizedBox(width: 20),
                                Expanded(flex: 5, child: sideColumn),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                mainStage,
                                const SizedBox(height: 16),
                                sideColumn,
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Top app bar: raccoon avatar on top-left, prominent title, notifications and telemetry actions.
  PreferredSizeWidget _buildTopBar(
    BuildContext context,
    UserProfile user,
    CognitiveRank currentRank,
  ) {
    return AppBar(
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 14.0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: RaccoonAvatar(
            size: 40,
            avatarId: user.avatarId,
            onTap: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      title: Text(
        'Cognitive Gym',
        style: (Theme.of(context).appBarTheme.titleTextStyle ??
                GoogleFonts.rajdhani(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ))
            .copyWith(
          fontSize: 22,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none_outlined),
          tooltip: 'Notifications',
          onPressed: () => _showNotificationsDialog(context),
        ),
        IconButton(
          icon: const Icon(Icons.insights_outlined),
          tooltip: 'Cognitive analytics',
          onPressed: () => context.push(AppRouter.analyticsRoute),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showNotificationsDialog(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor:
              isDark ? AppColors.surface : AppColors.surfaceLightClean,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color:
                  isDark ? AppColors.borderSubtle : AppColors.borderLightClean,
            ),
          ),
          title: Row(
            children: [
              Icon(
                Icons.notifications_none_outlined,
                size: 20,
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 8),
              Text(
                'Notifications',
                style: GoogleFonts.barlowCondensed(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationItem(
                title: 'Cognitive radar active',
                desc:
                    'Your 4 core cognitive disciplines are calibrated and ready for daily conditioning.',
                time: 'Just now',
                color: AppColors.memoryBlue,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildNotificationItem(
                title: 'Daily streak protected',
                desc:
                    'Complete any cognitive drill today to extend your streak multiplier.',
                time: 'Today',
                color:
                    isDark ? AppColors.brandLime : AppColors.primaryLimeLight,
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildNotificationItem(
                title: 'Cognitive rank assessment ready',
                desc:
                    'Balance mastery across creativity, observation, logic, and decision to level up.',
                time: 'Cycle 1',
                color: AppColors.eventOrange,
                isDark: isDark,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Dismiss'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationItem({
    required String title,
    required String desc,
    required String time,
    required Color color,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                desc,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Daily challenges: progress as a number, lime only on the bar.
  Widget _buildDailyChallengesBanner(
    BuildContext context,
    UserProfile user,
    bool isDark,
  ) {
    final exercisesCompleted = user.totalExercisesCompleted;
    const targetExercises = 4;
    final completedInCycle = exercisesCompleted == 0
        ? 0
        : (exercisesCompleted % targetExercises == 0
            ? targetExercises
            : exercisesCompleted % targetExercises);
    final progress = (completedInCycle / targetExercises).clamp(0.0, 1.0);

    return GymCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily challenges',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Complete to earn daily rewards and token bonus',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 14,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textMutedLight,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '10:12',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textMuted
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceContainerLowest
                  : AppColors.groundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    isDark ? AppColors.borderSubtle : AppColors.borderLightClean,
              ),
            ),
            child: Row(
              children: [
                Text(
                  '$completedInCycle of $targetExercises',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: isDark
                          ? AppColors.surfaceContainerHighest
                          : AppColors.borderLightClean,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark
                            ? AppColors.brandLime
                            : AppColors.primaryLimeLight,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.emoji_events_outlined,
                  size: 16,
                  color:
                      isDark ? AppColors.textMuted : AppColors.textMutedLight,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildDomainMissionChip(
                label: 'Creativity',
                color: AppColors.mathYellow,
                isCompleted: user.creativityPoints > 0,
                isDark: isDark,
                onTap: () => context.push(AppRouter.storyBuilderRoute),
              ),
              const SizedBox(width: 8),
              _buildDomainMissionChip(
                label: 'Observation',
                color: AppColors.memoryBlue,
                isCompleted: user.observationPoints > 0,
                isDark: isDark,
                onTap: () => context.push(AppRouter.observationChallengeRoute),
              ),
              const SizedBox(width: 8),
              _buildDomainMissionChip(
                label: 'Decision',
                color: AppColors.eventOrange,
                isCompleted: user.decisionMakingPoints > 0,
                isDark: isDark,
                onTap: () => context.push(AppRouter.scenarioLabRoute),
              ),
              const SizedBox(width: 8),
              _buildDomainMissionChip(
                label: 'Logic',
                color: AppColors.puzzleGreen,
                isCompleted: user.logicPoints > 0,
                isDark: isDark,
                onTap: () => context.push(AppRouter.debateArenaRoute),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDomainMissionChip({
    required String label,
    required Color color,
    required bool isCompleted,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isCompleted
                ? color.withAlpha(isDark ? 24 : 18)
                : (isDark
                    ? AppColors.surfaceContainerLowest
                    : AppColors.groundLight),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isCompleted
                  ? color.withAlpha(110)
                  : (isDark
                      ? AppColors.borderSubtle
                      : AppColors.borderLightClean),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 12,
                color: isCompleted
                    ? color
                    : (isDark
                        ? AppColors.textMuted
                        : AppColors.textMutedLight),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isCompleted
                        ? color
                        : (isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Discipline filter: sentence case, selection is a surface step plus lime.
  Widget _buildCategoryFilterSection(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Disciplines',
          style: GoogleFonts.barlowCondensed(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
          ),
        ),
        const SizedBox(height: 8),
        _buildCategoryFilterTabs(context, isDark),
      ],
    );
  }

  Widget _buildCategoryFilterTabs(BuildContext context, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (label, id) in _categoryTabs) ...[
            _buildCategoryTab(
              context,
              label: label,
              id: id,
              isDark: isDark,
            ),
            if (id != _categoryTabs.last.$2) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryTab(
    BuildContext context, {
    required String label,
    required String id,
    required bool isDark,
  }) {
    final isSelected = _selectedCategory == id;

    return Padding(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = id;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                    ? AppColors.surfaceContainerHigh
                    : AppColors.cardLight)
                : (isDark
                    ? AppColors.surfaceContainer
                    : AppColors.cardLight),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? (isDark
                      ? AppColors.borderDarkStrong
                      : AppColors.borderLightStrong)
                  : (isDark
                      ? AppColors.borderSubtle
                      : AppColors.borderLightClean),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.barlowCondensed(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? (isDark
                      ? AppColors.brandLime
                      : AppColors.primaryLimeLight)
                  : (isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight),
            ),
          ),
        ),
      ),
    );
  }

  /// Workout modules: quiet chrome, discipline color only on the tag dot.
  Widget _buildWorkoutModulesGrid(BuildContext context, bool isDark) {
    final modules = [
      {
        'id': 'CREATIVITY',
        'title': 'Story builder',
        'subtitle': 'Synthesize creative narratives with dynamic word constraints',
        'tag': 'Creativity',
        'tagColor': AppColors.mathYellow,
        'icon': Icons.auto_stories_outlined,
        'mode': '1v1 ranked',
        'route': AppRouter.storyBuilderRoute,
      },
      {
        'id': 'OBSERVATION',
        'title': 'Observation challenge',
        'subtitle': 'Timed visual detail and memory recall under graded focus clocks',
        'tag': 'Observation',
        'tagColor': AppColors.memoryBlue,
        'icon': Icons.visibility_outlined,
        'mode': 'Adaptive trial',
        'route': AppRouter.observationChallengeRoute,
      },
      {
        'id': 'DECISION',
        'title': 'Scenario lab',
        'subtitle': 'Multi-branching dilemma analysis and strategic trade-offs',
        'tag': 'Decision',
        'tagColor': AppColors.eventOrange,
        'icon': Icons.alt_route_outlined,
        'mode': 'Decision tree',
        'route': AppRouter.scenarioLabRoute,
      },
      {
        'id': 'LOGIC',
        'title': 'Debate arena',
        'subtitle': 'Structured sparring across philosophy, ethics and logic',
        'tag': 'Logic',
        'tagColor': AppColors.puzzleGreen,
        'icon': Icons.forum_outlined,
        'mode': 'Dialectical sparring',
        'route': AppRouter.debateArenaRoute,
      },
    ];

    final filtered = _selectedCategory == 'ALL'
        ? modules
        : modules.where((m) => m['id'] == _selectedCategory).toList();

    return Column(
      children: filtered.map((mod) {
        final title = mod['title'] as String;
        final subtitle = mod['subtitle'] as String;
        final tag = mod['tag'] as String;
        final tagColor = mod['tagColor'] as Color;
        final icon = mod['icon'] as IconData;
        final mode = mod['mode'] as String;
        final route = mod['route'] as String;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GymCard(
            onTap: () => context.push(route),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: tagColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tag,
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: tagColor,
                          ),
                        ),
                      ],
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textMutedLight,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceContainerHigh
                            : AppColors.groundLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderSubtle
                              : AppColors.borderLightClean,
                        ),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.textSecondaryLight,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? AppColors.borderSubtle
                            : AppColors.borderLightClean,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          mode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textSecondary
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => context.push(route),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColors.textPrimary
                              : AppColors.primaryLimeLight,
                          foregroundColor:
                              isDark ? const Color(0xFF131313) : Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Start',
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Stats as numbers: label, figure, caption. No icons, no decoration.
  Widget _buildTelemetryGrid(BuildContext context, UserProfile user, bool isDark) {
    final focus = (user.mentalEnergy * 100).toInt();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            isDark: isDark,
            label: 'Focus rate',
            value: '$focus%',
            caption: 'Cognitive focus',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            isDark: isDark,
            label: 'Total XP',
            value: '${user.totalXp}',
            caption: 'Lifetime points',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required bool isDark,
    required String label,
    required String value,
    required String caption,
  }) {
    return GymCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.barlowCondensed(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}
