import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/journal_entry.dart';
import '../services/journal_service.dart';
import '../services/sound_service.dart';
import '../utils/app_colors.dart';
import '../widgets/custom_button.dart';

/// Interactive Cognitive Journal and Mindfulness logging screen backed by SQLite persistence.
/// Provides high-contrast, polished reflection cards with distinct background separation,
/// a personal diary writing experience, 2x2 category grid, and full Light & Dark theme compatibility.
class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  static const List<Map<String, dynamic>> _moods = [
    {'emoji': '🌿', 'label': 'Calm', 'icon': Icons.spa_outlined},
    {'emoji': '⚡', 'label': 'Energetic', 'icon': Icons.bolt_rounded},
    {'emoji': '🌀', 'label': 'Focused', 'icon': Icons.center_focus_strong_rounded},
    {'emoji': '☁️', 'label': 'Foggy', 'icon': Icons.cloud_outlined},
    {'emoji': '😴', 'label': 'Resting', 'icon': Icons.bedtime_outlined},
  ];

  static const List<Map<String, dynamic>> _categoryData = [
    {
      'id': 'Reflection',
      'label': 'Reflection',
      'icon': Icons.self_improvement_rounded,
    },
    {
      'id': 'Pre-Workout',
      'label': 'Pre-Workout',
      'icon': Icons.fitness_center_rounded,
    },
    {
      'id': 'Post-Workout',
      'label': 'Post-Workout',
      'icon': Icons.task_alt_rounded,
    },
    {
      'id': 'Mindful Insight',
      'label': 'Mindful Insight',
      'icon': Icons.lightbulb_outline_rounded,
    },
  ];

  int _selectedMoodIndex = 0;
  String _selectedCategory = 'Reflection';
  final TextEditingController _textController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (!JournalService.instance.hasInitialLoaded) {
      JournalService.instance.loadEntries();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Color _getMoodColor(String label) {
    switch (label.toLowerCase()) {
      case 'calm':
        return const Color(0xFF10B981); // Emerald
      case 'energetic':
        return const Color(0xFFF59E0B); // Amber
      case 'focused':
        return const Color(0xFF0EA5E9); // Sky/Cyan
      case 'foggy':
        return const Color(0xFF8B5CF6); // Violet
      case 'resting':
        return const Color(0xFF6366F1); // Indigo
      default:
        return const Color(0xFF10B981);
    }
  }

  Color _getCategoryColor(String category, bool isDark) {
    switch (category.toLowerCase()) {
      case 'pre-workout':
        return isDark ? AppColors.brandLime : const Color(0xFF15803D);
      case 'post-workout':
        return isDark ? AppColors.mathYellow : const Color(0xFFB45309);
      case 'mindful insight':
        return const Color(0xFF8B5CF6);
      case 'reflection':
      default:
        return isDark ? AppColors.memoryBlue : const Color(0xFF0284C7);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _logEntry() async {
    if (_isSubmitting) return;

    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showSnackBar('Write a brief reflection before saving.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final mood = _moods[_selectedMoodIndex];
      final entry = await JournalService.instance.addEntry(
        moodEmoji: mood['emoji']! as String,
        moodLabel: mood['label']! as String,
        entryText: text,
        category: _selectedCategory,
      );

      if (entry != null && mounted) {
        _textController.clear();
        SoundService.instance.playRewardSuccess();
        _showSnackBar('Reflection saved. +5 Mindfulness XP (${mood['label']})');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _confirmDelete(JournalEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete reflection?'),
        content: const Text(
          'This journal entry will be deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await JournalService.instance.deleteEntry(entry.id);
      if (mounted) {
        _showSnackBar('Reflection deleted.');
      }
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day;

    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $period';

    if (isToday) return 'Today, $timeStr';
    if (isYesterday) return 'Yesterday, $timeStr';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, $timeStr';
  }

  /// Compact, welcoming header element introducing the personal diary space.
  Widget _buildJournalWelcomeHeader(BuildContext context, bool isDark) {
    final now = DateTime.now();
    const daysOfWeek = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final formattedDate =
        '${daysOfWeek[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}, ${now.year}';

    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : const Color(0xFFD6DEE7);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1E293B).withAlpha(120),
                  AppColors.cardDark,
                ]
              : [
                  const Color(0xFFF0FDF4),
                  Colors.white,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Calming Notebook / Journal Emblem
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.brandLime.withAlpha(25)
                  : const Color(0xFF15803D).withAlpha(18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? AppColors.brandLime.withAlpha(80)
                    : const Color(0xFF15803D).withAlpha(60),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.auto_stories_rounded,
                size: 22,
                color: isDark ? AppColors.brandLime : const Color(0xFF15803D),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Text & Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Mindful Space',
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceContainerHigh
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : const Color(0xFFCBD5E1),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: isDark
                                ? AppColors.brandLime
                                : const Color(0xFF15803D),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'A moment for yourself. A space for your thoughts.',
                  style: TextStyle(
                    fontSize: 12.5,
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

  /// 2x2 Compact, evenly dimensioned category selector grid.
  Widget _buildCategorySelector(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildCategoryCard(_categoryData[0], isDark)),
            const SizedBox(width: 8),
            Expanded(child: _buildCategoryCard(_categoryData[1], isDark)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildCategoryCard(_categoryData[2], isDark)),
            const SizedBox(width: 8),
            Expanded(child: _buildCategoryCard(_categoryData[3], isDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> catData, bool isDark) {
    final id = catData['id'] as String;
    final label = catData['label'] as String;
    final icon = catData['icon'] as IconData;
    final isSelected = _selectedCategory == id;
    final catColor = _getCategoryColor(id, isDark);

    return InkWell(
      onTap: () {
        SoundService.instance.playSoftTap();
        setState(() {
          _selectedCategory = id;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? catColor.withAlpha(isDark ? 35 : 22)
              : (isDark
                  ? AppColors.surfaceContainerLow
                  : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? catColor
                : (isDark
                    ? AppColors.borderDark
                    : const Color(0xFFD6DEE7)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? catColor
                  : (isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? catColor
                      : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Distinct background canvas colors
    final pageBgColor = isDark ? AppColors.pageBackground : const Color(0xFFF1F4F8);
    final cardBgColor = isDark ? AppColors.cardDark : Colors.white;
    final cardBorderColor = isDark ? AppColors.borderDark : const Color(0xFFD6DEE7);
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final textPrimaryColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: pageBgColor,
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
                  color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
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
                color: (isDark ? AppColors.brandLime : const Color(0xFF15803D))
                    .withAlpha(isDark ? 40 : 25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                size: 20,
                color: isDark ? AppColors.brandLime : const Color(0xFF15803D),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Cognitive Journal',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Journal Welcome Header (welcoming, personal diary element)
                _buildJournalWelcomeHeader(context, isDark),

                // 2. Mindfulness Check-In Input Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: cardBorderColor, width: 1.2),
                    boxShadow: isDark
                        ? [
                            BoxShadow(
                              color: Colors.black.withAlpha(45),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withAlpha(12),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                            BoxShadow(
                              color: const Color(0xFF0F172A).withAlpha(6),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.brandLime.withAlpha(25)
                                  : const Color(0xFF15803D).withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.psychology_outlined,
                              size: 20,
                              color: isDark
                                  ? AppColors.brandLime
                                  : const Color(0xFF15803D),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'How is your mind feeling right now?',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: textPrimaryColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Record your focus state before or after a training session.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: mutedColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Mood Selector Row
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(_moods.length, (idx) {
                              final item = _moods[idx];
                              final isSelected = _selectedMoodIndex == idx;
                              final moodColor =
                                  _getMoodColor(item['label'] as String);

                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                                  child: InkWell(
                                    onTap: () {
                                      SoundService.instance.playSoftTap();
                                      setState(() {
                                        _selectedMoodIndex = idx;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? moodColor.withAlpha(isDark ? 35 : 22)
                                            : (isDark
                                                ? AppColors.surfaceContainerLow
                                                : const Color(0xFFF8FAFC)),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isSelected
                                              ? moodColor
                                              : (isDark
                                                  ? AppColors.borderDark
                                                  : const Color(0xFFE2E8F0)),
                                          width: isSelected ? 1.5 : 1,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            item['icon'] as IconData,
                                            size: 22,
                                            color: isSelected ? moodColor : mutedColor,
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            item['label'] as String,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              fontSize: 11,
                                              color: isSelected ? moodColor : mutedColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),

                      const SizedBox(height: 18),

                      // 2x2 Category Grid (Compact, equal dimensions, perfectly aligned)
                      _buildCategorySelector(isDark),

                      const SizedBox(height: 18),

                      // Spacious Personal Diary Writing Area
                      Container(
                        constraints: BoxConstraints(
                          minHeight:
                              MediaQuery.sizeOf(context).width >= 600 ? 320 : 260,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF191B1F)
                              : const Color(0xFFFAFCFF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : const Color(0xFFCBD5E1),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isDark ? 25 : 8),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _textController,
                          minLines: 12,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textAlignVertical: TextAlignVertical.top,
                          style: TextStyle(
                            fontSize: 14.5,
                            color: textPrimaryColor,
                            height: 1.6,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Take a moment to reflect. How was your day? What did you learn, experience, or feel today?',
                            hintStyle: TextStyle(
                              color: mutedColor.withAlpha(isDark ? 180 : 200),
                              fontSize: 14,
                              height: 1.55,
                              fontStyle: FontStyle.italic,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      CustomButton(
                        label: 'Log entry',
                        icon: Icons.check_rounded,
                        style: CustomButtonStyle.primary,
                        width: double.infinity,
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting ? null : _logEntry,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Recent Reflections Container (Title & Entries housed INSIDE)
                ListenableBuilder(
                  listenable: JournalService.instance,
                  builder: (context, _) {
                    final service = JournalService.instance;
                    final count = service.entries.length;

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cardBorderColor, width: 1.2),
                        boxShadow: isDark
                            ? [
                                BoxShadow(
                                  color: Colors.black.withAlpha(45),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withAlpha(12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                                BoxShadow(
                                  color: const Color(0xFF0F172A).withAlpha(6),
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header inside the container: Icon + Title + Subtitle + Count Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.memoryBlue.withAlpha(25)
                                          : const Color(0xFF0284C7).withAlpha(20),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.history_edu_rounded,
                                      size: 20,
                                      color: isDark
                                          ? AppColors.memoryBlue
                                          : const Color(0xFF0284C7),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Recent reflections',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: textPrimaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Your saved mindfulness entries',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: mutedColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (count > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.surfaceContainerHigh
                                        : const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.borderDark
                                          : const Color(0xFFCBD5E1),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    '$count ${count == 1 ? 'entry' : 'entries'}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.textSecondary
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Internal subtle divider
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: isDark
                                ? AppColors.borderDark.withAlpha(80)
                                : const Color(0xFFE2E8F0),
                          ),

                          const SizedBox(height: 16),

                          // Loading, Empty State, or List of Entries inside container
                          if (service.isLoading && service.entries.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Center(
                                child: Text(
                                  'Loading reflections...',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: mutedColor,
                                  ),
                                ),
                              ),
                            )
                          else if (service.entries.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24.0),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.surfaceContainerHigh
                                            : const Color(0xFFF1F5F9),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.borderDark
                                              : const Color(0xFFCBD5E1),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.auto_stories_outlined,
                                        size: 24,
                                        color: isDark
                                            ? AppColors.textSecondary
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No reflections yet',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: textPrimaryColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Log your first reflection above to start your journal.',
                                      textAlign: TextAlign.center,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: mutedColor,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Column(
                              children: service.entries.map((entry) {
                                final moodColor = _getMoodColor(entry.moodLabel);
                                final catColor =
                                    _getCategoryColor(entry.category, isDark);

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12.0),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1B1B1B)
                                        : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.borderDark
                                          : const Color(0xFFE2E8F0),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Entry Header
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: moodColor.withAlpha(isDark ? 35 : 22),
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(
                                                color: moodColor.withAlpha(isDark ? 90 : 70),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              entry.moodEmoji,
                                              style: const TextStyle(fontSize: 15),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  entry.moodLabel,
                                                  style: theme.textTheme.titleSmall
                                                      ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14.5,
                                                    color: textPrimaryColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 7,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: catColor.withAlpha(
                                                        isDark ? 30 : 16),
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: catColor.withAlpha(
                                                          isDark ? 80 : 50),
                                                      width: 0.9,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    entry.category,
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: catColor,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.schedule_rounded,
                                                size: 13,
                                                color: mutedColor,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDate(entry.createdAt),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: mutedColor,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                icon: Icon(
                                                  Icons.delete_outline_rounded,
                                                  size: 19,
                                                  color: AppColors.errorRed
                                                      .withAlpha(200),
                                                ),
                                                tooltip: 'Delete reflection',
                                                padding: const EdgeInsets.all(4),
                                                constraints:
                                                    const BoxConstraints(),
                                                onPressed: () =>
                                                    _confirmDelete(entry),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      // Dividing line
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10.0),
                                        child: Divider(
                                          height: 1,
                                          thickness: 1,
                                          color: isDark
                                              ? AppColors.borderSubtle
                                              : const Color(0xFFF1F5F9),
                                        ),
                                      ),

                                      // Entry Body Text
                                      Text(
                                        entry.entryText,
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.55,
                                          color: textPrimaryColor,
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
