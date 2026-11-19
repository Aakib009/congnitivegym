import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/achievement_service.dart';
import '../services/progress_service.dart';
import '../services/sound_service.dart';
import '../utils/app_colors.dart';

/// Dedicated screen displaying all achievements, real-time statistics,
/// dynamic filtering, measurable progress indicators, and unlock milestones.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  String _selectedStatusFilter = 'All'; // 'All', 'Unlocked', 'Locked'

  @override
  void initState() {
    super.initState();
    // Listen to AchievementService for immediate UI refreshes upon unlock
    AchievementService.instance.addListener(_onServiceUpdate);
    ProgressService.instance.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    AchievementService.instance.removeListener(_onServiceUpdate);
    ProgressService.instance.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  String _formatUnlockDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userProfile = ProgressService.instance.userProfile;
    final allItems = AchievementService.allAchievements;

    final unlockedCount = allItems
        .where((a) => AchievementService.instance.isUnlocked(a.id))
        .length;
    final totalCount = allItems.length;
    final lockedCount = totalCount - unlockedCount;

    // Filter achievements list by status (All, Unlocked, Locked)
    final filteredItems = allItems.where((item) {
      final isUnlocked = AchievementService.instance.isUnlocked(item.id);

      // Status filter
      if (_selectedStatusFilter == 'Unlocked' && !isUnlocked) return false;
      if (_selectedStatusFilter == 'Locked' && isUnlocked) return false;

      return true;
    }).toList();

    // Canvas background
    final canvasColor = isDark
        ? const Color(0xFF141414)
        : const Color(0xFFF1F4F8);

    return Scaffold(
      backgroundColor: canvasColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.darkSurface
            : AppColors.surfaceLightClean,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark
                      ? AppColors.textPrimary
                      : AppColors.textPrimaryLight,
                ),
                onPressed: () {
                  SoundService.instance.playPop();
                  Navigator.of(context).pop();
                },
              )
            : null,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withAlpha(isDark ? 40 : 25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                size: 20,
                color: Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Achievements',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? AppColors.textPrimary
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                // Status Filter Tabs (All, Unlocked, Locked)
                _buildStatusFilterRow(
                  isDark: isDark,
                  totalCount: totalCount,
                  unlockedCount: unlockedCount,
                  lockedCount: lockedCount,
                ),

                const SizedBox(height: 16),

                // Achievement Items List
                if (filteredItems.isEmpty)
                  _buildEmptyState(isDark)
                else
                  ...filteredItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildAchievementCard(
                        context: context,
                        isDark: isDark,
                        item: item,
                        userProfile: userProfile,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // STATUS FILTER TABS
  // ===========================================================================
  Widget _buildStatusFilterRow({
    required bool isDark,
    required int totalCount,
    required int unlockedCount,
    required int lockedCount,
  }) {
    final filters = [
      {'label': 'All', 'count': totalCount},
      {'label': 'Unlocked', 'count': unlockedCount},
      {'label': 'Locked', 'count': lockedCount},
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202020) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: filters.map((f) {
          final label = f['label'] as String;
          final count = f['count'] as int;
          final isSelected = _selectedStatusFilter == label;

          return Expanded(
            child: GestureDetector(
              key: Key('filter_tab_${label.toLowerCase()}'),
              onTap: () {
                SoundService.instance.playPop();
                setState(() => _selectedStatusFilter = label);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF2E2E2E) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 40 : 15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? (isDark ? Colors.white : const Color(0xFF0F172A))
                            : (isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark
                                  ? const Color(0xFF10B981).withAlpha(40)
                                  : const Color(0xFF10B981).withAlpha(30))
                            : (isDark
                                  ? const Color(0xFF333333)
                                  : const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : (isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ===========================================================================
  // INDIVIDUAL ACHIEVEMENT CARD
  // ===========================================================================
  Widget _buildAchievementCard({
    required BuildContext context,
    required bool isDark,
    required AchievementItem item,
    required dynamic userProfile,
  }) {
    final theme = Theme.of(context);
    final isUnlocked = AchievementService.instance.isUnlocked(item.id);
    final unlockDate = AchievementService.instance.getUnlockDate(item.id);
    final progress = AchievementService.instance.getProgress(
      item.id,
      userProfile,
    );
    final target = item.targetProgress;
    final progressRatio = target > 0
        ? (progress / target).clamp(0.0, 1.0)
        : 1.0;

    final cardBg = isDark ? const Color(0xFF222222) : Colors.white;
    final cardBorder = isUnlocked
        ? (isDark
              ? const Color(0xFF10B981).withAlpha(90)
              : const Color(0xFF10B981).withAlpha(120))
        : (isDark ? const Color(0xFF333333) : const Color(0xFFD6DEE7));

    // Hidden achievement rendering rules
    final isHiddenAndLocked = item.isHidden && !isUnlocked;
    final displayTitle = isHiddenAndLocked ? 'Hidden Achievement' : item.title;
    final displayDescription = isHiddenAndLocked
        ? 'Keep exploring to discover this secret milestone!'
        : item.description;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: isUnlocked ? 1.5 : 1.0),
        boxShadow: [
          BoxShadow(
            color: isUnlocked
                ? const Color(0xFF10B981).withAlpha(isDark ? 20 : 15)
                : Colors.black.withAlpha(isDark ? 20 : 6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked
                      ? const Color(0xFF10B981).withAlpha(isDark ? 40 : 25)
                      : (isDark
                            ? const Color(0xFF181818)
                            : const Color(0xFFF1F5F9)),
                  border: Border.all(
                    color: isUnlocked
                        ? const Color(0xFF10B981)
                        : (isDark
                              ? const Color(0xFF333333)
                              : const Color(0xFFCBD5E1)),
                    width: isUnlocked ? 2.0 : 1.0,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  isUnlocked ? item.emoji : (item.isHidden ? '🔒' : item.emoji),
                  style: TextStyle(
                    fontSize: 24,
                    color: isUnlocked ? null : Colors.grey,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Title and Description
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayTitle,
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isUnlocked
                                  ? (isDark
                                        ? AppColors.textPrimary
                                        : AppColors.textPrimaryLight)
                                  : (isDark
                                        ? const Color(0xFFCBD5E1)
                                        : const Color(0xFF334155)),
                            ),
                          ),
                        ),
                        // XP reward pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isUnlocked
                                ? const Color(0xFF10B981).withAlpha(30)
                                : (isDark
                                      ? const Color(0xFF2A2A2A)
                                      : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isUnlocked
                                  ? const Color(0xFF10B981).withAlpha(80)
                                  : (isDark
                                        ? const Color(0xFF383838)
                                        : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Text(
                            '+${item.pointsReward} XP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked
                                  ? const Color(0xFF10B981)
                                  : (isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      displayDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.onSurfaceVariantText
                            : AppColors.textSecondaryLight,
                        height: 1.35,
                      ),
                    ),
                    if (item.unlockCondition != null &&
                        item.unlockCondition!.isNotEmpty &&
                        !isUnlocked &&
                        !isHiddenAndLocked) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Unlock: ${item.unlockCondition!}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Divider
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE2E8F0),
          ),

          const SizedBox(height: 10),

          // Footer: Status Badge, Progress, and Unlock Date
          Row(
            children: [
              // Unlocked / Locked Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? const Color(0xFF10B981).withAlpha(isDark ? 35 : 20)
                      : (isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isUnlocked
                          ? Icons.check_circle_rounded
                          : Icons.lock_outline_rounded,
                      size: 13,
                      color: isUnlocked
                          ? const Color(0xFF10B981)
                          : (isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUnlocked ? 'Unlocked' : 'Locked',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isUnlocked
                            ? const Color(0xFF10B981)
                            : (isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Category tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E1E)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF2D2D2D)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  item.category,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),

              const Spacer(),

              // Progress info or Unlock timestamp
              if (isUnlocked && unlockDate != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 13,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatUnlockDate(unlockDate),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                )
              else if (!isUnlocked && !isHiddenAndLocked)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 50,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressRatio,
                          minHeight: 5,
                          backgroundColor: isDark
                              ? const Color(0xFF333333)
                              : const Color(0xFFE2E8F0),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF0EA5E9),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$progress / $target',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // EMPTY FILTER STATE
  // ===========================================================================
  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF333333) : const Color(0xFFD6DEE7),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 36,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No milestones found',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your status or category filters.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
