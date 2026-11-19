import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/app_router.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/gym_card.dart';

/// Reusable Material 3 placeholder screen for upcoming cognitive training modules.
class ModulePlaceholderScreen extends StatelessWidget {
  final String moduleTitle;
  final String moduleSubtitle;
  final String description;
  final IconData icon;
  final Color iconColor;

  const ModulePlaceholderScreen({
    super.key,
    required this.moduleTitle,
    required this.moduleSubtitle,
    required this.description,
    required this.icon,
    this.iconColor = AppColors.accentCyan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(moduleTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Module Icon Container
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(isDark ? 35 : 20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: iconColor.withAlpha(100),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: 48,
                    color: iconColor,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // "Coming Soon" Badge Pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.accentAmber.withAlpha(isDark ? 30 : 20),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.accentAmber.withAlpha(120),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 15,
                      color: AppColors.accentAmber,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'MODULE IN DEVELOPMENT • COMING SOON',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        fontSize: 11,
                        color: AppColors.accentAmber,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Title & Subtitle
              Text(
                moduleTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                moduleSubtitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Purpose Card
              GymCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: AppColors.accentCyan,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Module Objective',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.accentCyan,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLightClean,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.psychology_rounded,
                            size: 18,
                            color: AppColors.accentCyan,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Designed to build active mental muscle instead of passive AI reliance.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons: Play Story Builder OR Return
              CustomButton(
                label: 'Play Story Builder Now',
                icon: Icons.auto_stories_rounded,
                style: CustomButtonStyle.primary,
                width: double.infinity,
                onPressed: () {
                  context.pushReplacement(AppRouter.storyBuilderRoute);
                },
              ),

              const SizedBox(height: 12),

              CustomButton(
                label: 'Back to Gym Hub',
                style: CustomButtonStyle.outline,
                width: double.infinity,
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRouter.homeRoute);
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Standalone screen instance for Mind Tree
class MindTreeExerciseScreen extends StatelessWidget {
  const MindTreeExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholderScreen(
      moduleTitle: 'Mind Tree',
      moduleSubtitle: 'Virtual Growth & Cognitive Balance',
      description:
          'Nurture your symbolic virtual Mind Tree through regular active thinking sessions. Watch your tree blossom as your mental equilibrium and focus consistency flourish over time.',
      icon: Icons.nature_people_rounded,
      iconColor: AppColors.accentEmerald,
    );
  }
}
