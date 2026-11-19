import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/rank_model.dart';
import '../models/user_profile.dart';
import '../routes/app_router.dart';
import '../services/auth_service.dart';
import '../services/progress_service.dart';
import '../services/sound_service.dart';
import '../services/theme_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import 'raccoon_avatar.dart';
import 'rank_emblem.dart';

/// Navigation drawer for Cognitive Gym: profile header, training modules,
/// theme selection and core app navigation. Quiet chrome, discipline colors
/// only as identity dots.
class AppDrawer extends StatelessWidget {
  final UserProfile? userProfile;

  const AppDrawer({super.key, this.userProfile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final user = userProfile ??
        (AuthService.instance.currentUser != null
            ? ProgressService.instance.userProfile
            : UserProfile.mock());

    return Drawer(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(context, user),

            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? AppColors.borderSubtle : AppColors.borderLightClean,
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                children: [
                  _buildSectionLabel(context, 'Training modules'),
                  const SizedBox(height: 8),

                  _buildModuleTile(
                    context: context,
                    icon: Icons.auto_stories_outlined,
                    accent: AppColors.mathYellow,
                    title: 'Story builder',
                    subtitle: 'Creative word synthesis exercise',
                    isActive: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRouter.storyBuilderRoute);
                    },
                  ),
                  const SizedBox(height: 4),

                  _buildModuleTile(
                    context: context,
                    icon: Icons.visibility_outlined,
                    accent: AppColors.memoryBlue,
                    title: 'Observation challenge',
                    subtitle: 'Visual detail and memory recall',
                    isActive: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRouter.observationChallengeRoute);
                    },
                  ),
                  const SizedBox(height: 4),

                  _buildModuleTile(
                    context: context,
                    icon: Icons.alt_route_outlined,
                    accent: AppColors.eventOrange,
                    title: 'Scenario lab',
                    subtitle: 'Divergent decision making',
                    isActive: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRouter.scenarioLabRoute);
                    },
                  ),
                  const SizedBox(height: 4),

                  _buildModuleTile(
                    context: context,
                    icon: Icons.forum_outlined,
                    accent: AppColors.puzzleGreen,
                    title: 'Debate arena',
                    subtitle: 'Critical argument and AI dialogue',
                    isActive: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRouter.debateArenaRoute);
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildThemeSelector(context),

                  const SizedBox(height: 20),

                  _buildSectionLabel(context, 'App sections'),
                  const SizedBox(height: 4),

                  _buildNavTile(
                    context: context,
                    icon: Icons.home_outlined,
                    title: 'Home',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(AppRouter.homeRoute);
                    },
                  ),
                  _buildNavTile(
                    context: context,
                    icon: Icons.insights_outlined,
                    title: 'Analytics',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push(AppRouter.analyticsRoute);
                    },
                  ),
                  _buildNavTile(
                    context: context,
                    icon: Icons.person_outline_rounded,
                    title: 'Account profile',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(AppRouter.accountRoute);
                    },
                  ),
                  _buildNavTile(
                    context: context,
                    icon: Icons.menu_book_outlined,
                    title: 'Cognitive journal',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go(AppRouter.journalRoute);
                    },
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 14,
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textMutedLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Cognitive Gym v${AppConstants.appVersion}',
                    style: theme.textTheme.bodySmall?.copyWith(
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
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, UserProfile user) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentRank = CognitiveRank.getRankForProfile(user);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          RaccoonAvatar(size: 44, avatarId: user.avatarId),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.displayName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Level ${user.level} · ${currentRank.tier.title}',
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: currentRank.color,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: user.xpProgress,
                    minHeight: 4,
                    backgroundColor: isDark
                        ? AppColors.surfaceContainerHigh
                        : AppColors.borderLightClean,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(currentRank.color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          RankEmblem(tier: currentRank.tier, size: 34),
        ],
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentTheme = ThemeService.instance.currentTheme;

    final themes = [
      (AppThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
      (AppThemeMode.light, 'Light', Icons.light_mode_outlined),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceContainerLow
            : AppColors.groundLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.borderSubtle : AppColors.borderLightClean,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette_outlined,
                size: 14,
                color: isDark
                    ? AppColors.textMuted
                    : AppColors.textMutedLight,
              ),
              const SizedBox(width: 6),
              Text(
                'Appearance',
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
          const SizedBox(height: 8),
          Row(
            children: themes.map((t) {
              final (mode, label, icon) = t;
              final isSelected = currentTheme == mode;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: InkWell(
                    onTap: () => ThemeService.instance.setTheme(mode),
                    borderRadius: BorderRadius.circular(6),
                    child: AnimatedContainer(
                      duration: AppConstants.animFast,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                ? AppColors.surfaceContainerHigh
                                : AppColors.cardLight)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icon,
                            size: 16,
                            color: isSelected
                                ? (isDark
                                    ? AppColors.brandLime
                                    : AppColors.primaryLimeLight)
                                : (isDark
                                    ? AppColors.textSecondary
                                    : AppColors.textSecondaryLight),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? (isDark
                                      ? AppColors.textPrimary
                                      : AppColors.textPrimaryLight)
                                  : (isDark
                                      ? AppColors.textSecondary
                                      : AppColors.textSecondaryLight),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textMuted : AppColors.textMutedLight,
        ),
      ),
    );
  }

  Widget _buildModuleTile({
    required BuildContext context,
    required IconData icon,
    required Color accent,
    required String title,
    required String subtitle,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hairline =
        isDark ? AppColors.borderSubtle : AppColors.borderLightClean;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          SoundService.instance.playNavigation();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive
                ? (isDark
                    ? AppColors.surfaceContainerLow
                    : AppColors.groundLight)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: hairline),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceContainerHigh
                      : AppColors.cardLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: hairline),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
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
        ),
      ),
    );
  }

  Widget _buildNavTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      horizontalTitleGap: 10,
      minLeadingWidth: 20,
      leading: Icon(
        icon,
        size: 18,
        color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
      ),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
        ),
      ),
      onTap: onTap,
    );
  }
}
