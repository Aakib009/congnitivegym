import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/observation_challenge.dart';
import '../routes/app_router.dart';
import '../services/exercise_scoring_service.dart';
import '../services/observation_challenge_service.dart';
import '../services/progress_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/gym_card.dart';
import '../widgets/observation_scene_painter.dart';

enum ObservationStage { intro, memorize, quiz, results }

/// Difficulty option data structure for Observation Challenge.
class DifficultyOption {
  final String label;
  final String emoji;
  final int durationSeconds;
  final String description;
  final Color color;

  const DifficultyOption({
    required this.label,
    required this.emoji,
    required this.durationSeconds,
    required this.description,
    required this.color,
  });
}

/// Main Screen implementing the Observation Challenge cognitive exercise.
class ObservationChallengeScreen extends StatefulWidget {
  final int? initialDifficulty;

  const ObservationChallengeScreen({super.key, this.initialDifficulty});

  @override
  State<ObservationChallengeScreen> createState() =>
      _ObservationChallengeScreenState();
}

class _ObservationChallengeScreenState
    extends State<ObservationChallengeScreen> {
  late ObservationChallenge _challenge;
  ObservationStage _stage = ObservationStage.intro;

  // Difficulty Options (Easy 30s, Medium 15s, Hard 8s)
  static const List<DifficultyOption> _difficulties = [
    DifficultyOption(
      label: 'Easy',
      emoji: '🟢',
      durationSeconds: 30,
      description: 'Image visible for 30 seconds. Relaxed pace to study details.',
      color: AppColors.accentEmerald,
    ),
    DifficultyOption(
      label: 'Medium',
      emoji: '🟡',
      durationSeconds: 15,
      description: 'Image visible for 15 seconds. Balanced pace for focused minds.',
      color: AppColors.accentAmber,
    ),
    DifficultyOption(
      label: 'Hard',
      emoji: '🔴',
      durationSeconds: 8,
      description: 'Image visible for 8 seconds. Fast-paced recall challenge.',
      color: AppColors.accentCrimson,
    ),
  ];

  int _selectedDurationSeconds = 15; // Default Medium

  // Memorization Timer State
  Timer? _timer;
  int _remainingSeconds = 15;

  // Quiz State
  int _currentQuestionIndex = 0;
  final Map<int, int> _userAnswers = {}; // Question index -> Selected option index
  bool _isSubmitting = false;
  bool _hasRecordedCompletion = false;

  // Scoring state: selected difficulty, real challenge start timestamp, and
  // the deterministic score computed at completion (shown on the results view
  // and passed to ProgressService / Analytics).
  ObservationDifficulty _selectedDifficulty = ObservationDifficulty.medium;
  DateTime? _challengeStartedAt;
  String? _challengeAttemptId;
  ExerciseScoreResult? _lastScoreResult;

  @override
  void initState() {
    super.initState();
    if (widget.initialDifficulty != null) {
      final clamped = widget.initialDifficulty!.clamp(0, _difficulties.length - 1);
      _selectedDurationSeconds = _difficulties[clamped].durationSeconds;
      _selectedDifficulty = ObservationDifficulty.values[clamped];
    }
    _loadNewChallenge();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadNewChallenge([String? id]) {
    _timer?.cancel();
    setState(() {
      _challenge = id != null
          ? ObservationChallengeService.getChallengeById(id)
          : ObservationChallengeService.getRandomChallenge();
      _stage = ObservationStage.intro;
      _remainingSeconds = _selectedDurationSeconds;
      _currentQuestionIndex = 0;
      _userAnswers.clear();
      _hasRecordedCompletion = false;
    });
  }

  /// Opens modern difficulty selection popup dialog once before starting challenge.
  Future<void> _promptDifficultyAndStart() async {
    final selected = await showDialog<DifficultyOption>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.tune_rounded, color: colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                'Select difficulty',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Choose how long the scene stays visible before the quiz:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withAlpha(180),
                ),
              ),
              const SizedBox(height: 16),
              ..._difficulties.map((opt) {
                final isSelected = _selectedDurationSeconds == opt.durationSeconds;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop(opt);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.surfaceContainerHigh
                                : AppColors.surfaceLightClean)
                            : colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline.withAlpha(100),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary.withAlpha(20)
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              opt.durationSeconds == 30
                                  ? Icons.self_improvement_rounded
                                  : (opt.durationSeconds == 15
                                      ? Icons.bolt_rounded
                                      : Icons.flash_on_rounded),
                              size: 18,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withAlpha(160),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      opt.label,
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${opt.durationSeconds}s',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: isSelected
                                            ? colorScheme.primary
                                            : colorScheme.onSurface.withAlpha(160),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  opt.description,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurface.withAlpha(160),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            size: 18,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface.withAlpha(120),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      final difficultyIndex =
          _difficulties.indexWhere((d) => d.label == selected.label);
      setState(() {
        _selectedDurationSeconds = selected.durationSeconds;
        if (difficultyIndex >= 0) {
          _selectedDifficulty = ObservationDifficulty.values[difficultyIndex];
        }
      });
      _startMemorizationTimer(selected.durationSeconds);
    }
  }

  void _startMemorizationTimer([int? duration]) {
    final initialSeconds = duration ?? _selectedDurationSeconds;
    // Start measuring real elapsed exercise time (memorization + quiz) and establish attempt ID.
    _challengeStartedAt = DateTime.now();
    _challengeAttemptId =
        'obs_${_challenge.id}_${_selectedDifficulty.name}_${_challengeStartedAt!.millisecondsSinceEpoch}';
    setState(() {
      _selectedDurationSeconds = initialSeconds;
      _stage = ObservationStage.memorize;
      _remainingSeconds = initialSeconds;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _stage = ObservationStage.quiz;
        });
      }
    });
  }

  void _selectOption(int optionIndex) {
    setState(() {
      _userAnswers[_currentQuestionIndex] = optionIndex;
    });
  }

  Future<void> _nextQuestion() async {
    if (_isSubmitting || _stage != ObservationStage.quiz || _hasRecordedCompletion) return;

    if (_currentQuestionIndex < _challenge.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      setState(() {
        _isSubmitting = true;
        _hasRecordedCompletion = true;
      });

      try {
        // Compute the deterministic performance score from real measured data
        // (accuracy dominant, difficulty-aware) and record the completion.
        final total = _challenge.questions.length;
        final correct = _calculateCorrectCount();
        final startedAt = _challengeStartedAt;
        final durationSeconds = startedAt == null
            ? _selectedDurationSeconds + total * 5
            : DateTime.now().difference(startedAt).inSeconds;

        final result = ExerciseScoringService.scoreObservationChallenge(
          totalQuestions: total,
          correctAnswers: correct,
          difficulty: _selectedDifficulty,
          durationSeconds: durationSeconds,
        );

        _lastScoreResult = result;
        await ProgressService.instance.recordObservationChallengeCompletion(
          performanceScore: result.performanceScore,
          accuracy: result.accuracy ?? 0.0,
          durationSeconds: durationSeconds,
          difficulty: _selectedDifficulty,
          idempotencyKey: _challengeAttemptId,
        );

        if (mounted) {
          setState(() {
            _stage = ObservationStage.results;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error recording completion: $e'),
              backgroundColor: Colors.red,
            ),
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
  }

  int _calculateCorrectCount() {
    int count = 0;
    for (int i = 0; i < _challenge.questions.length; i++) {
      if (_userAnswers[i] == _challenge.questions[i].correctOptionIndex) {
        count++;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_challenge.title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Next Random Challenge',
            onPressed: () => _loadNewChallenge(),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: AppConstants.animNormal,
          child: _buildCurrentStageView(theme, isDark),
        ),
      ),
    );
  }

  Widget _buildCurrentStageView(ThemeData theme, bool isDark) {
    switch (_stage) {
      case ObservationStage.intro:
        return _buildIntroView(theme, isDark);
      case ObservationStage.memorize:
        return _buildMemorizeView(theme, isDark);
      case ObservationStage.quiz:
        return _buildQuizView(theme, isDark);
      case ObservationStage.results:
        return _buildResultsView(theme, isDark);
    }
  }

  // --- STAGE 1: INTRO ---
  Widget _buildIntroView(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      key: const ValueKey('intro'),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 10),

          Container(
            width: 56,
            height: 56,
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
            child: const Icon(
              Icons.visibility_outlined,
              size: 26,
              color: AppColors.memoryBlue,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            _challenge.title,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          Text(
            'Visual attention and memory recall',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.memoryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 20),

          GymCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      color: AppColors.memoryBlue,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Challenge rules',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.memoryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _challenge.description,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                const SizedBox(height: 12),
                const BulletPoint(
                  text:
                      '1. Study the scene during your chosen timer (Easy 30s, Medium 15s, Hard 8s).',
                ),
                const SizedBox(height: 6),
                const BulletPoint(
                  text: '2. When time expires, the image disappears automatically.',
                ),
                const SizedBox(height: 6),
                const BulletPoint(
                  text: '3. Answer 5 observation questions from memory alone.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          CustomButton(
            label: 'Start observation',
            icon: Icons.play_arrow_rounded,
            style: CustomButtonStyle.primary,
            width: double.infinity,
            onPressed: _promptDifficultyAndStart,
          ),
        ],
      ),
    );
  }

  // --- STAGE 2: MEMORIZE (TIMER + IMAGE) ---
  Widget _buildMemorizeView(ThemeData theme, bool isDark) {
    final progress = _remainingSeconds / _selectedDurationSeconds.toDouble();

    return Column(
      key: const ValueKey('memorize'),
      children: [
        // Top Countdown Timer Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardSurface : AppColors.softDew,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? AppColors.borderDark
                    : AppColors.borderLightClean,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.timer_outlined,
                    color: AppColors.memoryBlue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Observe carefully',
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),

              Text(
                '${_remainingSeconds}s',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.brandLime : AppColors.primaryLimeLight,
                ),
              ),
            ],
          ),
        ),

        // Linear Progress Bar Indicator
        LinearProgressIndicator(
          value: progress,
          minHeight: 4,
          backgroundColor: isDark
              ? AppColors.surfaceRaised
              : AppColors.borderLightClean,
          valueColor:
              const AlwaysStoppedAnimation<Color>(AppColors.memoryBlue),
        ),

        const SizedBox(height: 16),

        // Fullscreen / Large Rounded Scene Illustration
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GymCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Expanded(
                    child: ObservationSceneWidget(
                      imagePath: _challenge.imagePath,
                      sceneType: _challenge.sceneType,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Memorize details: colors, object counts, positions',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  // --- STAGE 3: QUIZ (QUESTIONS) ---
  Widget _buildQuizView(ThemeData theme, bool isDark) {
    final currentQ = _challenge.questions[_currentQuestionIndex];
    final selectedOption = _userAnswers[_currentQuestionIndex];

    return SingleChildScrollView(
      key: const ValueKey('quiz'),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Progress Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_challenge.questions.length}',
                style: theme.textTheme.titleSmall,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                child: Text(
                  'Scene hidden',
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Linear Question Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) /
                  _challenge.questions.length.toDouble(),
              minHeight: 6,
              backgroundColor: isDark
                  ? AppColors.surfaceContainerHigh
                  : AppColors.borderLightClean,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.memoryBlue),
            ),
          ),

          const SizedBox(height: 20),

          // Question Card
          GymCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.help_outline_rounded,
                      color: AppColors.memoryBlue,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Observation question',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.memoryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  currentQ.questionText,
                  style: theme.textTheme.titleMedium?.copyWith(height: 1.4),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Multiple choice options
          Column(
            children: currentQ.options.asMap().entries.map((entry) {
              final idx = entry.key;
              final optionText = entry.value;
              final isSelected = selectedOption == idx;
              final accent =
                  isDark ? AppColors.brandLime : AppColors.primaryLimeLight;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: GymCard(
                  padding: EdgeInsets.zero,
                  backgroundColor: isSelected
                      ? (isDark
                          ? AppColors.surfaceContainerHigh
                          : AppColors.surfaceLightClean)
                      : null,
                  borderColor: isSelected
                      ? accent
                      : (isDark
                          ? AppColors.borderDark
                          : AppColors.borderLightClean),
                  borderWidth: isSelected ? 1.5 : 1,
                  onTap: () => _selectOption(idx),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? accent.withAlpha(25)
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? accent
                                  : (isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLightClean),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            String.fromCharCode(65 + idx), // A, B, C, D
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? accent
                                  : (isDark
                                      ? AppColors.textMutedDark
                                      : AppColors.textMutedLight),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            optionText,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: accent,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Next / Submit Button
          CustomButton(
            label: _currentQuestionIndex == _challenge.questions.length - 1
                ? 'Submit challenge'
                : 'Next question',
            icon: _currentQuestionIndex == _challenge.questions.length - 1
                ? Icons.check_rounded
                : Icons.arrow_forward_rounded,
            style: CustomButtonStyle.primary,
            width: double.infinity,
            isLoading: _isSubmitting,
            onPressed: (selectedOption != null &&
                    !_isSubmitting &&
                    !_hasRecordedCompletion)
                ? _nextQuestion
                : null,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // --- STAGE 4: RESULTS ---
  Widget _buildResultsView(ThemeData theme, bool isDark) {
    final correctCount = _calculateCorrectCount();
    final totalCount = _challenge.questions.length;
    final percentage = (correctCount / totalCount * 100).toInt();

    // Real computed metrics from the deterministic scoring engine.
    final result = _lastScoreResult;
    final performancePct =
        result?.performanceScore.round() ?? percentage;
    final observationGain = ExerciseScoringService.scaledGain(
        15, result?.performanceScore ?? percentage.toDouble());
    final xpEarned = result?.xpEarned ?? ExerciseScoringService.observationBaseXp;

    return SingleChildScrollView(
      key: const ValueKey('results'),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          const SizedBox(height: 10),

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
              size: 24,
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'Observation complete',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 4),

          Text(
            'Score: $correctCount / $totalCount ($percentage%)',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 4),

          // Normalized 0-100 performance score (accuracy-dominant and
          // difficulty-aware; computed by ExerciseScoringService).
          Text(
            'Performance score: $performancePct/100 (${_selectedDifficulty.name})',
            style: theme.textTheme.bodyMedium,
          ),

          const SizedBox(height: 16),

          // Real earned rewards (performance-dependent skill gain + XP).
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceContainerLow
                  : AppColors.surfaceLightClean,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark
                    ? AppColors.borderSubtle
                    : AppColors.borderLightClean,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt_rounded,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '+$observationGain observation points · +$xpEarned XP',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Answer Review Breakdown Title
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Answer breakdown',
              style: theme.textTheme.titleSmall,
            ),
          ),

          const SizedBox(height: 8),

          // Questions Review Cards
          ..._challenge.questions.asMap().entries.map((entry) {
            final idx = entry.key;
            final q = entry.value;
            final userChoice = _userAnswers[idx];
            final isCorrect = userChoice == q.correctOptionIndex;
            final accent =
                isDark ? AppColors.brandLime : AppColors.primaryLimeLight;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: GymCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          isCorrect
                              ? Icons.check_circle_outline_rounded
                              : Icons.cancel_outlined,
                          color: isCorrect ? accent : AppColors.errorRed,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${idx + 1}. ${q.questionText}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your answer: ${userChoice != null ? q.options[userChoice] : "None"}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isCorrect ? accent : AppColors.errorRed,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (!isCorrect)
                      Text(
                        'Correct answer: ${q.correctAnswer}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (q.explanation != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        q.explanation!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textMutedDark
                              : AppColors.textMutedLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 20),

          // Action Buttons: Next Random Challenge OR Exit
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  label: 'Retry challenge',
                  style: CustomButtonStyle.outline,
                  onPressed: _promptDifficultyAndStart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton(
                  label: 'Next challenge',
                  style: CustomButtonStyle.primary,
                  onPressed: () => _loadNewChallenge(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          CustomButton(
            label: 'Back to home',
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

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class BulletPoint extends StatelessWidget {
  final String text;

  const BulletPoint({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Icon(
            Icons.circle,
            size: 6,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
