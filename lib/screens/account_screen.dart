import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../routes/app_router.dart';
import '../services/achievement_service.dart';
import '../services/auth_service.dart';
import '../services/progress_service.dart';
import '../services/reward_manager.dart';
import '../services/sound_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/avatar_selector.dart';
import '../widgets/custom_button.dart';
import '../widgets/gym_card.dart';
import '../widgets/level_up_dialog.dart';
import '../widgets/raccoon_avatar.dart';
import '../widgets/section_header.dart';

/// Redesigned Account tab serving as the user's profile and cognitive progress hub.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  StreamSubscription<LevelUpEvent>? _levelUpSubscription;

  @override
  void initState() {
    super.initState();
    _levelUpSubscription = RewardManager.instance.onLevelUp.listen((event) {
      if (mounted) {
        LevelUpDialogWidget.show(context, event);
      }
    });
  }

  @override
  void dispose() {
    _levelUpSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Profile',
            onPressed: () => _showEditProfileModal(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            ProgressService.instance,
            AuthService.instance,
          ]),
          builder: (context, _) {
            final authUser = AuthService.instance.currentUser;
            final profile = ProgressService.instance.userProfile;

            // Merge stats from Auth user if available
            final fullName = authUser?.fullName ?? profile.displayName;
            final username = authUser?.username ?? 'alexmindful';
            final email = authUser?.email ?? 'alex.mindful@cognitivegym.app';
            final totalXp = authUser?.totalXP ?? profile.totalXp;
            final exercisesCompleted = authUser?.exercisesCompleted ?? profile.totalExercisesCompleted;
            final currentLevel = profile.level;
            final avatarId = authUser?.avatarId ?? profile.avatarId;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header: Large Avatar, Full Name, Username & Edit Pill
                  _buildProfileHeader(
                    context, theme, colorScheme, isDark, fullName, username, email, avatarId,
                  ),

                  const SizedBox(height: 24),

                  // 2. Cognitive Stats & Points Section
                  _buildPointsSection(
                    context, theme, colorScheme, isDark, profile, totalXp, currentLevel,
                  ),

                  const SizedBox(height: 24),

                  // 3. Achievements Showcase Section
                  _buildAchievementsSection(context, theme, isDark, profile),

                  const SizedBox(height: 24),

                  // 4. User Information Section
                  _buildUserInformationSection(
                    context, theme, colorScheme, isDark, fullName, username, email, exercisesCompleted, currentLevel,
                  ),

                  const SizedBox(height: 24),

                  // 5. Settings & Account Actions Section
                  _buildSettingsSection(context, theme, colorScheme, isDark),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. HEADER SECTION
  // ===========================================================================
  Widget _buildProfileHeader(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    String fullName,
    String username,
    String email,
    String avatarId,
  ) {
    return Center(
      child: Column(
        children: [
          // Large Circular Profile Avatar with decorative glow border
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withAlpha(90),
                width: 2,
              ),
            ),
            child: RaccoonAvatar(
              size: 88.0,
              avatarId: avatarId,
            ),
          ),
          const SizedBox(height: 14),

          // User's Full Name
          Text(
            fullName,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),

          // Username & Email
          Text(
            '@$username • $email',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(height: 12),

          // Edit Profile Pill Button
          OutlinedButton.icon(
            onPressed: () => _showEditProfileModal(context),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit Profile'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. POINTS & COGNITIVE PROGRESS SECTION
  // ===========================================================================
  Widget _buildPointsSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    dynamic profile,
    int totalXp,
    int currentLevel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Cognitive Stats & Points',
          subtitle: 'Live total points accumulated across learning activities',
        ),
        const SizedBox(height: 12),

        // Prominent Points Hero Card
        GymCard(
          padding: const EdgeInsets.all(20.0),
          borderColor: colorScheme.primary.withAlpha(70),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorScheme.primary.withAlpha(60)),
                    ),
                    child: Icon(
                      Icons.military_tech_rounded,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOTAL POINTS',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        '$totalXp XP',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Level Badge Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'LEVEL $currentLevel',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Cognitive Statistics Grid with responsive columns & tactical card design
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 850;
            final isMedium = constraints.maxWidth >= 520;
            final crossAxisCount = isWide ? 4 : (isMedium ? 3 : 2);
            final childAspectRatio = isWide ? 2.3 : (isMedium ? 2.0 : 1.6);

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: childAspectRatio,
              children: [
                _buildStatCard(
                  context: context,
                  title: 'Creativity Points',
                  value: '${profile.creativityPoints} pts',
                  icon: Icons.palette_outlined,
                  color: AppColors.tacticalYellow,
                  isDark: isDark,
                ),
                _buildStatCard(
                  context: context,
                  title: 'Observation Points',
                  value: '${profile.observationPoints} pts',
                  icon: Icons.remove_red_eye_outlined,
                  color: AppColors.tacticalCyan,
                  isDark: isDark,
                ),
                _buildStatCard(
                  context: context,
                  title: 'Logic Points',
                  value: '${profile.logicPoints} pts',
                  icon: Icons.psychology_outlined,
                  color: AppColors.tacticalGreen,
                  isDark: isDark,
                ),
                _buildStatCard(
                  context: context,
                  title: 'Decision Points',
                  value: '${profile.decisionMakingPoints} pts',
                  icon: Icons.alt_route_rounded,
                  color: AppColors.tacticalOrange,
                  isDark: isDark,
                ),
                _buildStatCard(
                  context: context,
                  title: 'Current Streak',
                  value: '${profile.currentStreak} Days',
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.eventOrange,
                  isDark: isDark,
                ),
                _buildStatCard(
                  context: context,
                  title: 'Best Streak',
                  value: '${profile.bestStreak} Days',
                  icon: Icons.emoji_events_rounded,
                  color: AppColors.accentAmber,
                  isDark: isDark,
                ),
                _buildStatCard(
                  context: context,
                  title: 'Achievements',
                  value: '${profile.unlockedAchievements.length} Unlocked',
                  icon: Icons.verified_rounded,
                  color: AppColors.brandLime,
                  isDark: isDark,
                  onTap: () {
                    SoundService.instance.playPop();
                    context.go(AppRouter.achievementsRoute);
                  },
                ),
                _buildStatCard(
                  context: context,
                  title: 'Current Level',
                  value: 'Level $currentLevel',
                  icon: Icons.workspace_premium_rounded,
                  color: AppColors.tacticalCyan,
                  isDark: isDark,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. ACHIEVEMENTS SHOWCASE SECTION (DEDICATED MILESTONE CARD)
  // ===========================================================================
  Widget _buildAchievementsSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    dynamic profile,
  ) {
    final unlockedCount = profile.unlockedAchievements.length;
    final totalCount = AchievementService.allAchievements.length;
    final completionPct = totalCount > 0
        ? ((unlockedCount / totalCount) * 100).clamp(0, 100).toInt()
        : 0;

    final cardBg = isDark ? const Color(0xFF222222) : Colors.white;
    final cardBorder =
        isDark ? const Color(0xFF333333) : const Color(0xFFD6DEE7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Achievements',
          subtitle: 'Track your milestones and accomplishments',
        ),
        const SizedBox(height: 12),

        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () {
              SoundService.instance.playPop();
              context.go(AppRouter.achievementsRoute);
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(isDark ? 25 : 8),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    const Color(0xFFD97706),
                                    const Color(0xFFF59E0B),
                                  ]
                                : [
                                    const Color(0xFFF59E0B),
                                    const Color(0xFFFCD34D),
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withAlpha(50),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Achievements',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textPrimary
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Track your milestones and accomplishments.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? AppColors.onSurfaceVariantText
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF10B981).withAlpha(isDark ? 35 : 20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF10B981).withAlpha(80),
                          ),
                        ),
                        child: Text(
                          '$unlockedCount / $totalCount Unlocked',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: totalCount > 0
                          ? (unlockedCount / totalCount).clamp(0.0, 1.0)
                          : 0.0,
                      minHeight: 6,
                      backgroundColor: isDark
                          ? const Color(0xFF333333)
                          : const Color(0xFFE2E8F0),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$completionPct% Completed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Explore Achievements',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.brandLime
                                  : AppColors.primaryLimeLight,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: isDark
                                ? AppColors.brandLime
                                : AppColors.primaryLimeLight,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // HELPER STAT CARD WIDGET
  // ===========================================================================
  Widget _buildStatCard({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final card = GymCard(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      borderRadius: 12,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withAlpha(isDark ? 30 : 22),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withAlpha(isDark ? 90 : 70),
                width: 1.0,
              ),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? AppColors.onSurfaceVariantText
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: card,
        ),
      );
    }

    return card;
  }

  // ===========================================================================
  // 4. USER INFORMATION SECTION
  // ===========================================================================
  Widget _buildUserInformationSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    String fullName,
    String username,
    String email,
    int exercisesCompleted,
    int currentLevel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Account Information',
          subtitle: 'Personal profile details stored safely in SQLite',
        ),
        const SizedBox(height: 12),

        GymCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              _buildInfoRow(
                context: context,
                icon: Icons.person_outline_rounded,
                label: 'Full Name',
                value: fullName,
              ),
              const Divider(height: 16),
              _buildInfoRow(
                context: context,
                icon: Icons.alternate_email_rounded,
                label: 'Username',
                value: '@$username',
              ),
              const Divider(height: 16),
              _buildInfoRow(
                context: context,
                icon: Icons.email_outlined,
                label: 'Email',
                value: email,
              ),
              const Divider(height: 16),
              _buildInfoRow(
                context: context,
                icon: Icons.fitness_center_rounded,
                label: 'Exercises Completed',
                value: '$exercisesCompleted Completed',
              ),
              const Divider(height: 16),
              _buildInfoRow(
                context: context,
                icon: Icons.workspace_premium_rounded,
                label: 'Cognitive Tier',
                value: 'Level $currentLevel Trainee',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withAlpha(180),
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 5. SETTINGS & ACTIONS SECTION
  // ===========================================================================
  Widget _buildSettingsSection(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Settings & Actions',
          subtitle: 'Account preferences and app details',
        ),
        const SizedBox(height: 12),

        GymCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildActionTile(
                context: context,
                icon: Icons.edit_outlined,
                title: 'Edit Profile',
                onTap: () => _showEditProfileModal(context),
              ),
              const Divider(height: 1),
              _buildActionTile(
                context: context,
                icon: Icons.info_outline_rounded,
                title: 'About Cognitive Gym',
                onTap: () => context.go(AppRouter.aboutRoute),
              ),
              const Divider(height: 1),
              _buildActionTile(
                context: context,
                icon: Icons.logout_rounded,
                title: 'Log Out',
                titleColor: Colors.red,
                iconColor: Colors.red,
                onTap: () => _showLogOutDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? colorScheme.primary),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: titleColor,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: onTap,
      ),
    );
  }

  // ===========================================================================
  // MODALS & DIALOGS
  // ===========================================================================
  void _showEditProfileModal(BuildContext context) {
    final authUser = AuthService.instance.currentUser;
    final currentAvatar = authUser?.avatarId ?? ProgressService.instance.userProfile.avatarId;
    String selectedModalAvatar = currentAvatar;

    final nameController = TextEditingController(
      text: authUser?.fullName ?? ProgressService.instance.userProfile.displayName,
    );
    final usernameController = TextEditingController(
      text: authUser?.username ?? 'alexmindful',
    );
    final emailController = TextEditingController(
      text: authUser?.email ?? 'alex.mindful@cognitivegym.app',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.borderRadiusLarge),
        ),
      ),
      builder: (ctx) {
        String? modalError;

        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit Profile Information',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (modalError != null) ...[
                      Text(
                        modalError!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Avatar Selector inside Edit Profile
                    AvatarSelector(
                      selectedAvatarId: selectedModalAvatar,
                      previewSize: 76.0,
                      showHeader: false,
                      onAvatarSelected: (newId) {
                        setModalState(() {
                          selectedModalAvatar = newId;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.alternate_email_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: 'Save Changes',
                        onPressed: () async {
                          final newName = nameController.text.trim();
                          final newUsername = usernameController.text.trim();
                          final newEmail = emailController.text.trim();

                          if (newName.isEmpty || newUsername.isEmpty || newEmail.isEmpty) {
                            setModalState(() {
                              modalError = 'All fields are required.';
                            });
                            return;
                          }

                          await AuthService.instance.updateProfile(
                            fullName: newName,
                            username: newUsername,
                            email: newEmail,
                            profileImage: selectedModalAvatar,
                          );

                          await ProgressService.instance.updateDisplayName(newName);
                          await ProgressService.instance.updateAvatar(selectedModalAvatar);

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                        },
                      ),
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

  void _showLogOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of Cognitive Gym?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.instance.logout();
              if (context.mounted) {
                context.go(AppRouter.loginRoute);
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
