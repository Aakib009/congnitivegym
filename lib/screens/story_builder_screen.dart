import 'package:flutter/material.dart';
import '../models/story_model.dart';
import '../services/exercise_scoring_service.dart';
import '../services/progress_service.dart';
import '../services/story_storage_service.dart';
import '../services/word_generator_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/gym_card.dart';

/// Screen implementing the Story Builder creativity exercise and story archive.
class StoryBuilderScreen extends StatefulWidget {
  const StoryBuilderScreen({super.key});

  static const int minRequiredWords = 40;

  /// Stretch target at which the length component of the deterministic
  /// score reaches full marks (see ExerciseScoringService.scoreStoryBuilder).
  static const int targetWordCount =
      ExerciseScoringService.storyTargetWordCount;

  @override
  State<StoryBuilderScreen> createState() => _StoryBuilderScreenState();
}

class _StoryBuilderScreenState extends State<StoryBuilderScreen> {
  late List<String> _currentWords;
  final TextEditingController _storyController = TextEditingController();
  int _wordCount = 0;
  bool _isSubmitting = false;
  bool _hasCompletedCurrentChallenge = false;

  int _currentTabIndex = 0; // 0 = Write Challenge, 1 = My Stories
  List<StoryModel> _savedStories = [];
  bool _isLoadingStories = true;

  // Writing session start used to measure real elapsed exercise time.
  DateTime? _writingStartedAt;
  String? _challengeAttemptId;
  ExerciseScoreResult? _lastScoreResult;

  @override
  void initState() {
    super.initState();
    _generateNewWords();
    _storyController.addListener(_onTextChanged);
    _loadSavedStories();
  }

  @override
  void dispose() {
    _storyController.removeListener(_onTextChanged);
    _storyController.dispose();
    super.dispose();
  }

  void _generateNewWords() {
    setState(() {
      _currentWords = WordGeneratorService.getRandomWords(count: 3);
      // A fresh prompt starts a new measurable writing session and stable attempt ID.
      _writingStartedAt = DateTime.now();
      _challengeAttemptId =
          'story_${_writingStartedAt!.millisecondsSinceEpoch}_${_currentWords.join('_')}';
      _lastScoreResult = null;
      _hasCompletedCurrentChallenge = false;
    });
  }

  void _onTextChanged() {
    final count = StoryModel.countWords(_storyController.text);
    if (count != _wordCount) {
      setState(() {
        _wordCount = count;
      });
    }
  }

  Future<void> _loadSavedStories() async {
    setState(() {
      _isLoadingStories = true;
    });
    final stories = await StoryStorageService.getStories();
    if (mounted) {
      setState(() {
        _savedStories = stories;
        _isLoadingStories = false;
      });
    }
  }

  void _resetChallenge() {
    _storyController.clear();
    _generateNewWords();
    setState(() {
      _wordCount = 0;
    });
  }

  Future<void> _onCompleteChallenge() async {
    if (_isSubmitting || _hasCompletedCurrentChallenge) return;

    if (_wordCount < StoryBuilderScreen.minRequiredWords) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Write at least ${StoryBuilderScreen.minRequiredWords} words to complete the challenge. (Current: $_wordCount)',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final missingWords =
        StoryModel.getMissingWords(_storyController.text, _currentWords);
    if (missingWords.isNotEmpty) {
      final missingListStr = missingWords.map((w) => '• $w').join('\n');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "You haven't used all three required words yet. Try incorporating every given word into your story before submitting.",
              ),
              const SizedBox(height: 10),
              const Text(
                'Missing words:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(missingListStr),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Deterministic scoring from measurable properties of the story
      // (required-word coverage, length depth, vocabulary richness).
      final writingStartedAt = _writingStartedAt;
      final durationSeconds = writingStartedAt == null
          ? 0
          : DateTime.now().difference(writingStartedAt).inSeconds;

      final result = ExerciseScoringService.scoreStoryBuilder(
        storyText: _storyController.text,
        requiredWords: _currentWords,
        minWordCount: StoryBuilderScreen.minRequiredWords,
        targetWordCount: StoryBuilderScreen.targetWordCount,
      );
      _lastScoreResult = result;

      // Record the completion and use the real earned XP on the story card
      // and success dialog (no hardcoded reward values).
      final xpEarned =
          await ProgressService.instance.recordStoryBuilderCompletion(
        performanceScore: result.performanceScore,
        accuracy: result.accuracy ?? 0.0,
        durationSeconds: durationSeconds,
        idempotencyKey: _challengeAttemptId,
      );

      final newStory = StoryModel(
        id: _challengeAttemptId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        words: List<String>.from(_currentWords),
        content: _storyController.text.trim(),
        createdAt: DateTime.now(),
        wordCount: _wordCount,
        pointsEarned: xpEarned,
      );

      final success = await StoryStorageService.saveStory(newStory);

      if (mounted) {
          if (success) {
            setState(() {
              _hasCompletedCurrentChallenge = true;
            });
            await _loadSavedStories();
            _showSuccessDialog(newStory);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to save story. Please try again.'),
              ),
            );
          }
        }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving challenge: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessDialog(StoryModel story) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: isDark
              ? AppColors.darkCardSurface
              : AppColors.lightSurface,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
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
                    Icons.workspace_premium_outlined,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  'Challenge complete',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),

                Text(
                  'You wove all three words into an original story.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                Text(
                  _lastScoreResult == null
                      ? 'Challenge complete'
                      : 'Performance score: ${_lastScoreResult!.performanceScore.round()}/100',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceContainerLow
                        : AppColors.surfaceLightClean,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderSubtle
                          : AppColors.borderLightClean,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, color: colorScheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '+${ExerciseScoringService.scaledGain(15, _lastScoreResult?.performanceScore ?? 0)} creativity points · +${story.pointsEarned} XP',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        label: 'View stories',
                        style: CustomButtonStyle.outline,
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _resetChallenge();
                          setState(() {
                            _currentTabIndex = 1;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        label: 'New story',
                        style: CustomButtonStyle.primary,
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          _resetChallenge();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteStory(StoryModel story) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Story'),
        content: const Text(
          'Are you sure you want to delete this story from your journal? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StoryStorageService.deleteStory(story.id);
      await _loadSavedStories();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Story Builder'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'About Challenge',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: isDark
                    ? AppColors.darkCardSurface
                    : AppColors.lightSurface,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_stories_outlined,
                            color: isDark
                                ? AppColors.textSecondary
                                : AppColors.textSecondaryLight,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text('Why Story Builder?',
                              style: theme.textTheme.titleMedium),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Story Builder is a pure creativity exercise. By synthesizing three unrelated concepts into a coherent story, your brain activates divergent thinking pathways.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• No grammar or spell checking\n• No AI evaluation or grading\n• Focus purely on imaginative expression',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 20),
                      CustomButton(
                        label: 'Close',
                        width: double.infinity,
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation Segmented Switcher
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceContainerLow
                      : AppColors.surfaceLightClean,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLightClean,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        index: 0,
                        label: 'Write story',
                        icon: Icons.create_outlined,
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        index: 1,
                        label: 'My stories (${_savedStories.length})',
                        icon: Icons.bookmark_border_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: _currentTabIndex == 0
                  ? _buildWriteStoryView(theme, isDark)
                  : _buildMyStoriesView(theme, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String label,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final isSelected = _currentTabIndex == index;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTabIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: AppConstants.animFast,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.surfaceContainerHigh
                  : AppColors.cardLight)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.brandLime : AppColors.primaryLimeLight)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? (isDark ? AppColors.brandLime : AppColors.primaryLimeLight)
                  : (isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? (isDark ? AppColors.brandLime : AppColors.primaryLimeLight)
                    : (isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- VIEW 1: WRITE STORY CHALLENGE ---
  Widget _buildWriteStoryView(ThemeData theme, bool isDark) {
    final isWordCountMet = _wordCount >= StoryBuilderScreen.minRequiredWords;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Challenge Description Header
          GymCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.psychology_outlined,
                          color: AppColors.mathYellow,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Creativity Challenge',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: isDark
                                ? AppColors.mathYellow
                                : AppColors.accentYellowLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: _generateNewWords,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Shuffle'),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            isDark ? AppColors.brandLime : AppColors.primaryLimeLight,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Create a short story using all three words.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Connect these distinct ideas into your own creative narrative.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Required word cards
          Row(
            children: _currentWords.asMap().entries.map((entry) {
              final idx = entry.key;
              final word = entry.value;
              final textLower = _storyController.text.toLowerCase();
              final isWordIncluded = textLower.contains(word.toLowerCase());
              final accent =
                  isDark ? AppColors.brandLime : AppColors.primaryLimeLight;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: idx < 2 ? 8.0 : 0.0,
                  ),
                  child: GymCard(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 8),
                    backgroundColor: isWordIncluded
                        ? (isDark
                            ? AppColors.surfaceContainerHigh
                            : AppColors.surfaceLightClean)
                        : (isDark ? AppColors.surface : AppColors.cardLight),
                    borderColor: isWordIncluded
                        ? accent
                        : (isDark ? AppColors.borderDark : AppColors.borderLightClean),
                    borderWidth: isWordIncluded ? 1.5 : 1.0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '0${idx + 1}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: isWordIncluded
                                    ? accent
                                    : (isDark
                                        ? AppColors.textMutedDark
                                        : AppColors.textMutedLight),
                              ),
                            ),
                            if (isWordIncluded) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.check_circle_rounded, size: 12, color: accent),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            word,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isWordIncluded ? accent : null,
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

          const SizedBox(height: 20),

          // Editor & Word Counter Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your story',
                style: theme.textTheme.titleSmall,
              ),
              AnimatedContainer(
                duration: AppConstants.animFast,
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isWordCountMet
                      ? (isDark
                          ? AppColors.surfaceContainerHigh
                          : AppColors.surfaceLightClean)
                      : (isDark
                          ? AppColors.surfaceContainerLow
                          : AppColors.surfaceLightClean),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isWordCountMet
                        ? (isDark ? AppColors.brandLime : AppColors.primaryLimeLight)
                        : (isDark
                            ? AppColors.borderDark
                            : AppColors.borderLightClean),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isWordCountMet
                          ? Icons.check_circle_outline_rounded
                          : Icons.edit_note_rounded,
                      size: 15,
                      color: isWordCountMet
                          ? (isDark ? AppColors.brandLime : AppColors.primaryLimeLight)
                          : (isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$_wordCount / ${StoryBuilderScreen.minRequiredWords} words',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isWordCountMet
                            ? (isDark ? AppColors.brandLime : AppColors.primaryLimeLight)
                            : (isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Story editor
          TextField(
            controller: _storyController,
            minLines: 8,
            maxLines: 15,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            decoration: const InputDecoration(
              hintText: 'Connect all three words in one story.',
              contentPadding: EdgeInsets.all(18),
            ),
          ),

          const SizedBox(height: 24),

          // Submit Button
          CustomButton(
            label: _hasCompletedCurrentChallenge
                ? 'Challenge completed'
                : 'Complete challenge',
            icon: Icons.check_rounded,
            style: CustomButtonStyle.primary,
            width: double.infinity,
            isLoading: _isSubmitting,
            onPressed: (_isSubmitting || _hasCompletedCurrentChallenge)
                ? null
                : _onCompleteChallenge,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- VIEW 2: MY STORIES ARCHIVE ---
  Widget _buildMyStoriesView(ThemeData theme, bool isDark) {
    if (_isLoadingStories) {
      return Center(
        child: CircularProgressIndicator(
          color: isDark ? AppColors.brandLime : AppColors.primaryLimeLight,
        ),
      );
    }

    if (_savedStories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceContainerHigh
                      : AppColors.surfaceLightClean,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLightClean,
                  ),
                ),
                child: Icon(
                  Icons.menu_book_outlined,
                  size: 24,
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No stories yet',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Complete a Story Builder challenge to save your stories here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? AppColors.textMutedDark
                      : AppColors.textMutedLight,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              CustomButton(
                label: 'Start challenge',
                style: CustomButtonStyle.primary,
                onPressed: () {
                  setState(() {
                    _currentTabIndex = 0;
                  });
                },
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: _savedStories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final story = _savedStories[index];
        final dateStr = _formatDate(story.createdAt);

        return GymCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Date & Points
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateStr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceContainerHigh
                              : AppColors.surfaceLightClean,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLightClean,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 14,
                              color: isDark
                                  ? AppColors.brandLime
                                  : AppColors.primaryLimeLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '+${story.pointsEarned} points',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.textPrimary
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 18),
                        color: isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                        tooltip: 'Delete story',
                        onPressed: () => _confirmDeleteStory(story),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Required words
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: story.words.map((w) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceContainerLow
                          : AppColors.surfaceLightClean,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLightClean,
                      ),
                    ),
                    child: Text(
                      '#$w',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 12),

              // Story Content Text
              Text(
                story.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 12),

              // Footer Info
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${story.wordCount} words',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dt) {
    final months = [
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
      'Dec'
    ];
    final month = months[dt.month - 1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$month ${dt.day}, ${dt.year} at $hour:$minute';
  }
}
