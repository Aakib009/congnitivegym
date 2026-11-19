import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/cognitive_analytics_model.dart';
import '../routes/app_router.dart';
import '../services/analytics_service.dart';
import '../utils/app_colors.dart';
import '../widgets/analytics/exercise_breakdown_bar_chart.dart';
import '../widgets/analytics/skill_radar_chart.dart';
import '../widgets/analytics/xp_trend_line_chart.dart';
import '../widgets/gym_card.dart';

/// Comprehensive Analytics Dashboard Screen displaying visual fl_chart charts,
/// metric cards, skill balance radar, XP growth trend, and performance insights.
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.loadAnalytics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Home',
          onPressed: () => context.go(AppRouter.homeRoute),
        ),
        title: const Text('Cognitive Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reload analytics',
            onPressed: () => AnalyticsService.instance.loadAnalytics(),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: AnalyticsService.instance,
        builder: (context, _) {
          final service = AnalyticsService.instance;
          final status = service.status;
          final data = service.analyticsData;

          if (status == AnalyticsStatus.loading) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Loading analytics...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          if (status == AnalyticsStatus.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 44,
                      color: AppColors.errorRed,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      service.errorMessage ??
                          'An error occurred loading analytics.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => service.loadAnalytics(),
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 800;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTimeRangeSelector(
                          context,
                          service.selectedTimeRange,
                        ),

                        const SizedBox(height: 16),

                        _buildSummaryCards(context, data, isWide),

                        const SizedBox(height: 20),

                        if (data.isEmpty)
                          _buildEmptyStateCard(context)
                        else ...[
                          if (isWide) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildChartCard(
                                    context: context,
                                    title: 'XP accumulation trend',
                                    subtitle:
                                        'Daily experience growth timeline',
                                    icon: Icons.show_chart_rounded,
                                    child: XpTrendLineChart(
                                      xpTrend: data.xpTrend,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildChartCard(
                                    context: context,
                                    title: 'Skill balance',
                                    subtitle: 'Across 5 skill axes',
                                    icon: Icons.radar_rounded,
                                    child: SkillRadarChart(
                                      skillMetrics: data.skillMetrics,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildChartCard(
                                    context: context,
                                    title: 'Exercise distribution',
                                    subtitle: 'Completions by module',
                                    icon: Icons.bar_chart_rounded,
                                    child: ExerciseBreakdownBarChart(
                                      breakdown: data.exerciseBreakdown,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildInsightsCard(context, data),
                                ),
                              ],
                            ),
                          ] else ...[
                            _buildChartCard(
                              context: context,
                              title: 'XP accumulation trend',
                              subtitle: 'Daily experience growth timeline',
                              icon: Icons.show_chart_rounded,
                              child: XpTrendLineChart(xpTrend: data.xpTrend),
                            ),
                            const SizedBox(height: 16),
                            _buildChartCard(
                              context: context,
                              title: 'Skill balance',
                              subtitle: 'Across 5 skill axes',
                              icon: Icons.radar_rounded,
                              child: SkillRadarChart(
                                skillMetrics: data.skillMetrics,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildChartCard(
                              context: context,
                              title: 'Exercise distribution',
                              subtitle: 'Completions by module',
                              icon: Icons.bar_chart_rounded,
                              child: ExerciseBreakdownBarChart(
                                breakdown: data.exerciseBreakdown,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildInsightsCard(context, data),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTimeRangeSelector(
    BuildContext context,
    AnalyticsTimeRange currentRange,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GymCard(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      borderRadius: 10,
      child: Row(
        children: [
          Text(
            'Time range',
            style: theme.textTheme.titleSmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
          ),
          const Spacer(),
          SegmentedButton<AnalyticsTimeRange>(
            segments: const [
              ButtonSegment(
                value: AnalyticsTimeRange.sevenDays,
                label: Text('7 days'),
              ),
              ButtonSegment(
                value: AnalyticsTimeRange.thirtyDays,
                label: Text('30 days'),
              ),
              ButtonSegment(
                value: AnalyticsTimeRange.allTime,
                label: Text('All time'),
              ),
            ],
            selected: {currentRange},
            onSelectionChanged: (Set<AnalyticsTimeRange> newSelection) {
              AnalyticsService.instance.setTimeRange(newSelection.first);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    CognitiveAnalyticsData data,
    bool isWide,
  ) {
    final cards = [
      _SummaryMetric(
        label: 'Total XP earned',
        value: '${data.totalXpEarned}',
        icon: Icons.bolt_outlined,
      ),
      _SummaryMetric(
        label: 'Exercises finished',
        value: '${data.totalExercisesCompleted}',
        icon: Icons.check_circle_outline_rounded,
      ),
      _SummaryMetric(
        label: 'Average score',
        value: '${(data.averageScore * 100).toInt()}%',
        icon: Icons.star_outline_rounded,
      ),
      _SummaryMetric(
        label: 'Training time',
        value: '${data.totalDurationMinutes}m',
        icon: Icons.timer_outlined,
      ),
    ];

    if (isWide) {
      return Row(
        children: cards
            .map(
              (c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: c,
                ),
              ),
            )
            .toList(),
      );
    } else {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.3,
        children: cards,
      );
    }
  }

  Widget _buildEmptyStateCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GymCard(
      padding: const EdgeInsets.all(32.0),
      borderRadius: 12,
      child: Column(
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 44,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
          const SizedBox(height: 12),
          Text('No analytics yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Complete a few exercises in Story Builder, Observation Challenge, Sequence Master, Scenario Lab, or Debate Arena to build your profile.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.go(AppRouter.homeRoute),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Start an exercise'),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = isDark
        ? AppColors.textMutedDark
        : AppColors.textMutedLight;

    return GymCard(
      padding: const EdgeInsets.all(16.0),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: mutedColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInsightsCard(BuildContext context, CognitiveAnalyticsData data) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor = isDark
        ? AppColors.textMutedDark
        : AppColors.textMutedLight;

    return GymCard(
      padding: const EdgeInsets.all(16.0),
      borderRadius: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Insights', style: theme.textTheme.titleSmall),
          const SizedBox(height: 16),
          _buildInsightItem(context, 'Strongest skill', data.strongestSkill),
          const SizedBox(height: 12),
          _buildInsightItem(context, 'Weakest skill', data.weakestSkill),
          const SizedBox(height: 12),
          _buildInsightItem(
            context,
            'Top exercise',
            data.mostPracticedExercise,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.groundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLightClean,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.psychology_outlined, color: mutedColor, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data.performanceRecommendation,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ', style: theme.textTheme.bodyMedium),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GymCard(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      borderRadius: 10,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceContainerHigh
                  : AppColors.surfaceLightClean,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLightClean,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              size: 18,
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: theme.textTheme.titleLarge),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
