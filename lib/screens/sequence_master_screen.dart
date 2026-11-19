import '../services/achievement_service.dart';
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/sequence_master.dart';
import '../routes/app_router.dart';
import '../services/exercise_scoring_service.dart';
import '../services/progress_service.dart';
import '../services/sequence_master_service.dart';
import '../services/sound_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/gym_card.dart';

enum SequenceMasterStage { intro, playing, results }

class SequenceMasterScreen extends StatefulWidget {
  final SequenceMasterDifficulty? initialDifficulty;
  final int? randomSeed;

  const SequenceMasterScreen({
    super.key,
    this.initialDifficulty,
    this.randomSeed,
  });

  @override
  State<SequenceMasterScreen> createState() => _SequenceMasterScreenState();
}

class _SequenceMasterScreenState extends State<SequenceMasterScreen> {
  late final Random _random;
  StreamSubscription<AchievementItem>? _achievementSubscription;
  late SequenceMasterDifficulty _selectedDifficulty;

  SequenceMasterStage _stage = SequenceMasterStage.intro;
  List<SequenceMasterQuestion> _questions = const [];
  List<int?> _userAnswers = const [];
  final Set<String> _seenQuestionIds = <String>{};

  int _currentIndex = 0;
  int _correctCount = 0;
  int _remainingSeconds = 0;
  int? _selectedOptionIndex;
  bool _answered = false;
  bool _timedOut = false;
  bool _isSubmitting = false;
  bool _hasRecordedCompletion = false;

  Timer? _questionTimer;
  DateTime? _sessionStartedAt;
  String? _attemptId;
  ExerciseScoreResult? _lastScoreResult;
  int _lastLogicGain = 0;

  SequenceMasterQuestion get _currentQuestion => _questions[_currentIndex];

  @override
  void initState() {
    super.initState();
    _random = Random(
      widget.randomSeed ?? DateTime.now().microsecondsSinceEpoch,
    );
    _selectedDifficulty =
        widget.initialDifficulty ?? SequenceMasterDifficulty.medium;
    _achievementSubscription = AchievementService.instance.onAchievementUnlocked
        .listen((item) {
          if (mounted) {
            AchievementService.showUnlockSnackBar(context, item);
          }
        });
  }

  @override
  void dispose() {
    _achievementSubscription?.cancel();
    _questionTimer?.cancel();
    super.dispose();
  }

  void _startSession() {
    _questionTimer?.cancel();

    final difficulty = _selectedDifficulty;
    final List<SequenceMasterQuestion> questions;
    try {
      questions = SequenceMasterService.generateQuestions(
        difficulty: difficulty,
        random: _random,
        excludeIds: _seenQuestionIds,
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not build a sequence run. Please try again.'),
        ),
      );
      return;
    }

    final startedAt = DateTime.now();
    setState(() {
      _questions = questions;
      _userAnswers = List<int?>.filled(questions.length, null);
      _currentIndex = 0;
      _selectedOptionIndex = null;
      _answered = false;
      _timedOut = false;
      _correctCount = 0;
      _remainingSeconds = difficulty.secondsPerQuestion;
      _sessionStartedAt = startedAt;
      _attemptId =
          'sequence_${difficulty.name}_${startedAt.microsecondsSinceEpoch}';
      _lastScoreResult = null;
      _lastLogicGain = 0;
      _isSubmitting = false;
      _hasRecordedCompletion = false;
      _stage = SequenceMasterStage.playing;
      _seenQuestionIds.addAll(questions.map((question) => question.id));
    });
    _armQuestionTimer();
  }

  void _armQuestionTimer() {
    _questionTimer?.cancel();
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_stage != SequenceMasterStage.playing || _answered) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        SoundService.instance.playPop();
        setState(() {
          _remainingSeconds = 0;
          _answered = true;
          _timedOut = true;
        });
        return;
      }
      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  void _answerQuestion(int optionIndex) {
    if (_answered || _stage != SequenceMasterStage.playing) return;

    _questionTimer?.cancel();
    final question = _currentQuestion;
    final isCorrect = question.isCorrect(optionIndex);
    if (isCorrect) {
      SoundService.instance.playConfirmation();
    } else {
      SoundService.instance.playPop();
    }

    setState(() {
      _selectedOptionIndex = optionIndex;
      _userAnswers[_currentIndex] = optionIndex;
      _answered = true;
      _timedOut = false;
      if (isCorrect) {
        _correctCount += 1;
      }
    });
  }

  void _nextQuestion() {
    if (!_answered || _stage != SequenceMasterStage.playing) return;
    if (_currentIndex == _questions.length - 1) {
      _finishSession();
      return;
    }

    setState(() {
      _currentIndex += 1;
      _selectedOptionIndex = null;
      _answered = false;
      _timedOut = false;
      _remainingSeconds = _selectedDifficulty.secondsPerQuestion;
    });
    _armQuestionTimer();
  }

  Future<void> _finishSession() async {
    if (_isSubmitting || _hasRecordedCompletion || _questions.isEmpty) return;

    _questionTimer?.cancel();
    setState(() {
      _isSubmitting = true;
    });

    final total = _questions.length;
    final startedAt = _sessionStartedAt;
    final durationSeconds = startedAt == null
        ? 0
        : DateTime.now().difference(startedAt).inSeconds;

    try {
      final result = ExerciseScoringService.scoreSequenceMaster(
        totalQuestions: total,
        correctAnswers: _correctCount,
        difficulty: _selectedDifficulty,
        durationSeconds: durationSeconds,
      );
      final logicGain = ExerciseScoringService.scaledGain(
        ExerciseScoringService.sequenceMasterBaseLogicPoints,
        result.performanceScore,
      );

      await ProgressService.instance.recordSequenceMasterCompletion(
        performanceScore: result.performanceScore,
        accuracy: result.accuracy ?? 0,
        durationSeconds: durationSeconds,
        difficulty: _selectedDifficulty,
        correctAnswers: _correctCount,
        idempotencyKey: _attemptId,
      );

      if (!mounted) return;
      setState(() {
        _lastScoreResult = result;
        _lastLogicGain = logicGain;
        _hasRecordedCompletion = true;
        _stage = SequenceMasterStage.results;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save this run. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _changeDifficulty() {
    _questionTimer?.cancel();
    setState(() {
      _stage = SequenceMasterStage.intro;
      _questions = const [];
      _userAnswers = const [];
      _selectedOptionIndex = null;
      _answered = false;
      _timedOut = false;
      _lastScoreResult = null;
      _lastLogicGain = 0;
    });
  }

  void _returnToGames() {
    _questionTimer?.cancel();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.gamesRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sequence Master'), centerTitle: true),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: AppConstants.animNormal,
          child: switch (_stage) {
            SequenceMasterStage.intro => _buildIntro(),
            SequenceMasterStage.playing => _buildPlaying(),
            SequenceMasterStage.results => _buildResults(),
          },
        ),
      ),
    );
  }

  Widget _buildIntro() {
    final theme = Theme.of(context);
    final accent = AppColors.logicPink;

    return _PageScroll(
      key: const ValueKey('sequence-intro'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Align(
            child: _RoundIcon(icon: Icons.timeline_rounded, color: accent),
          ),
          const SizedBox(height: 16),
          Text(
            'Sequence Master',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Pattern logic and sequence reasoning',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: accent,
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
                    Icon(Icons.rule_rounded, color: accent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'How it works',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Find the rule behind each sequence. Every run mixes alphabet, '
                  'number, mixed, and visual patterns.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final category in SequenceCategory.values)
                      _CategoryChip(category: category),
                  ],
                ),
                const SizedBox(height: 14),
                _RuleBullet(
                  text:
                      'Choose from four answers. The result and rule appear immediately.',
                  color: accent,
                ),
                const SizedBox(height: 8),
                _RuleBullet(
                  text:
                      'Easy and Medium hide one value. Hard hides two values per sequence.',
                  color: accent,
                ),
                const SizedBox(height: 8),
                _RuleBullet(
                  text:
                      'Correct answers build logic points and XP. Higher difficulties reward more.',
                  color: accent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Choose your difficulty', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          _DifficultyPicker(
            selected: _selectedDifficulty,
            onSelected: (difficulty) {
              setState(() {
                _selectedDifficulty = difficulty;
              });
            },
          ),
          const SizedBox(height: 22),
          CustomButton(
            key: const ValueKey('sequence-start-button'),
            label: 'Start sequence',
            icon: Icons.play_arrow_rounded,
            width: double.infinity,
            onPressed: _startSession,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPlaying() {
    final theme = Theme.of(context);
    final question = _currentQuestion;
    final total = _questions.length;
    final progress = total == 0 ? 0.0 : (_currentIndex + 1) / total;
    final categoryColor = _categoryColor(question.category);
    final timerUrgent = _remainingSeconds <= 5 && !_answered;
    final isLastQuestion = _currentIndex == total - 1;

    return _PageScroll(
      key: const ValueKey('sequence-playing'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sequence ${_currentIndex + 1} of $total',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_selectedDifficulty.label} • ${question.category.label}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: categoryColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _TimerBadge(seconds: _remainingSeconds, urgent: timerUrgent),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.brightness == Brightness.dark
                  ? AppColors.surfaceContainerHigh
                  : AppColors.borderLightClean,
              valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
            ),
          ),
          const SizedBox(height: 20),
          GymCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CategoryChip(category: question.category),
                    const Spacer(),
                    _MetaTag(
                      label: _selectedDifficulty.label,
                      color: _difficultyColor(_selectedDifficulty),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  question.prompt,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (
                      var index = 0;
                      index < question.sequence.length;
                      index++
                    )
                      _SequenceToken(
                        key: ValueKey('sequence-token-$index'),
                        token: question.sequence[index],
                        accent: categoryColor,
                      ),
                  ],
                ),
                if (question.isMultipleBlank) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Two values are hidden. Choose the pair that completes the pattern.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.brightness == Brightness.dark
                          ? AppColors.textMutedDark
                          : AppColors.textMutedLight,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 560;
              final itemWidth = twoColumns
                  ? (constraints.maxWidth - 12) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (var index = 0; index < question.options.length; index++)
                    SizedBox(
                      width: itemWidth,
                      child: _AnswerOptionCard(
                        key: ValueKey('sequence-option-$index'),
                        index: index,
                        label: question.options[index],
                        state: _optionState(question, index),
                        onTap: _answered ? null : () => _answerQuestion(index),
                      ),
                    ),
                ],
              );
            },
          ),
          if (_answered) ...[
            const SizedBox(height: 16),
            _AnswerFeedback(
              question: question,
              selectedIndex: _selectedOptionIndex,
              timedOut: _timedOut,
            ),
          ],
          const SizedBox(height: 20),
          CustomButton(
            key: const ValueKey('sequence-next-button'),
            label: isLastQuestion ? 'View results' : 'Next sequence',
            icon: isLastQuestion
                ? Icons.assessment_rounded
                : Icons.arrow_forward_rounded,
            width: double.infinity,
            isLoading: _isSubmitting,
            onPressed: _answered && !_isSubmitting ? _nextQuestion : null,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final total = _questions.length;
    final correct = _correctCount;
    final accuracy = total == 0 ? 0.0 : (correct / total) * 100;
    final result = _lastScoreResult;
    final performance = result?.performanceScore.round() ?? accuracy.round();
    final xp = result?.xpEarned ?? 0;
    final accent = AppColors.logicPink;

    return _PageScroll(
      key: const ValueKey('sequence-results'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Align(
            child: _RoundIcon(
              icon: Icons.workspace_premium_rounded,
              color: accent,
              size: 52,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Sequence complete',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            '$correct / $total',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${accuracy.round()}% accuracy • ${_selectedDifficulty.label} difficulty',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Performance $performance/100',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
          ),
          const SizedBox(height: 18),
          GymCard(
            backgroundColor: accent.withAlpha(isDark ? 24 : 12),
            borderColor: accent.withAlpha(isDark ? 110 : 80),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 16,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, color: accent, size: 19),
                    const SizedBox(width: 6),
                    Text(
                      '+$xp XP',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.psychology_alt_rounded, color: accent, size: 19),
                    const SizedBox(width: 6),
                    Text(
                      '+$_lastLogicGain logic points',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 560 ? 4 : 2;
              final width =
                  (constraints.maxWidth - ((columns - 1) * 10)) / columns;
              final stats = [
                _ResultStat(
                  label: 'Correct',
                  value: '$correct',
                  color: AppColors.accentEmerald,
                ),
                _ResultStat(
                  label: 'Incorrect',
                  value: '${total - correct}',
                  color: AppColors.errorRed,
                ),
                _ResultStat(
                  label: 'Accuracy',
                  value: '${accuracy.round()}%',
                  color: theme.colorScheme.primary,
                ),
                _ResultStat(
                  label: 'Performance',
                  value: '$performance',
                  color: accent,
                ),
              ];
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final stat in stats) SizedBox(width: width, child: stat),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          Text('Answer breakdown', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          for (var index = 0; index < _questions.length; index++) ...[
            _ReviewCard(
              key: ValueKey('sequence-review-$index'),
              index: index,
              question: _questions[index],
              selectedIndex: _userAnswers[index],
            ),
            if (index != _questions.length - 1) const SizedBox(height: 8),
          ],
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final actions = [
                CustomButton(
                  key: const ValueKey('sequence-replay-button'),
                  label: 'Replay',
                  icon: Icons.replay_rounded,
                  width: constraints.maxWidth < 520 ? double.infinity : null,
                  onPressed: _startSession,
                ),
                CustomButton(
                  key: const ValueKey('sequence-games-button'),
                  label: 'Back to games',
                  icon: Icons.sports_esports_rounded,
                  style: CustomButtonStyle.outline,
                  width: constraints.maxWidth < 520 ? double.infinity : null,
                  onPressed: _returnToGames,
                ),
              ];
              if (constraints.maxWidth < 520) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    actions[0],
                    const SizedBox(height: 10),
                    actions[1],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: actions[0]),
                  const SizedBox(width: 12),
                  Expanded(child: actions[1]),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            key: const ValueKey('sequence-change-difficulty-button'),
            onPressed: _changeDifficulty,
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: const Text('Change difficulty'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  _OptionState _optionState(SequenceMasterQuestion question, int index) {
    if (!_answered) return _OptionState.idle;
    if (index == question.correctOptionIndex) return _OptionState.correct;
    if (index == _selectedOptionIndex) return _OptionState.incorrect;
    return _OptionState.muted;
  }
}

class _PageScroll extends StatelessWidget {
  final Widget child;

  const _PageScroll({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: child,
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _RoundIcon({required this.icon, required this.color, this.size = 56});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 28 : 18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(isDark ? 110 : 70)),
      ),
      child: Icon(icon, size: size * 0.46, color: color),
    );
  }
}

class _RuleBullet extends StatelessWidget {
  final String text;
  final Color color;

  const _RuleBullet({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle_outline_rounded,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
        ),
      ],
    );
  }
}

class _DifficultyPicker extends StatelessWidget {
  final SequenceMasterDifficulty selected;
  final ValueChanged<SequenceMasterDifficulty> onSelected;

  const _DifficultyPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final cards = [
      for (final difficulty in SequenceMasterDifficulty.values)
        _DifficultyCard(
          key: ValueKey('sequence-difficulty-${difficulty.name}'),
          difficulty: difficulty,
          isSelected: difficulty == selected,
          onTap: () => onSelected(difficulty),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 660) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                cards[index],
                if (index != cards.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cards[0]),
              const SizedBox(width: 12),
              Expanded(child: cards[1]),
              const SizedBox(width: 12),
              Expanded(child: cards[2]),
            ],
          ),
        );
      },
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final SequenceMasterDifficulty difficulty;
  final bool isSelected;
  final VoidCallback onTap;

  const _DifficultyCard({
    super.key,
    required this.difficulty,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _difficultyColor(difficulty);

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${difficulty.label}: ${difficulty.questionCount} sequences, ${difficulty.secondsPerQuestion} seconds each',
      child: GymCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        backgroundColor: isSelected
            ? (isDark
                  ? AppColors.surfaceContainerHigh
                  : AppColors.surfaceLightClean)
            : null,
        borderColor: isSelected
            ? color
            : (isDark ? AppColors.borderDark : AppColors.borderLightClean),
        borderWidth: isSelected ? 1.6 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withAlpha(isDark ? 30 : 20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _difficultyIcon(difficulty),
                    size: 18,
                    color: color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    difficulty.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  size: 18,
                  color: isSelected
                      ? color
                      : (isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              difficulty.description,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.35,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _MetaTag(
                  label: '${difficulty.questionCount} sequences',
                  color: color,
                ),
                _MetaTag(
                  label: '${difficulty.secondsPerQuestion}s each',
                  color: color,
                ),
                _MetaTag(
                  label: difficulty.blankCount == 1
                      ? '1 blank'
                      : '${difficulty.blankCount} blanks',
                  color: color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaTag extends StatelessWidget {
  final String label;
  final Color color;

  const _MetaTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 24 : 14),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withAlpha(isDark ? 90 : 55)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final SequenceCategory category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(category);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 26 : 16),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withAlpha(isDark ? 90 : 55)),
      ),
      child: Text(
        category.label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _SequenceToken extends StatelessWidget {
  final String token;
  final Color accent;

  const _SequenceToken({super.key, required this.token, required this.accent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isBlank = token == SequenceMasterQuestion.blankToken;
    final color = isBlank
        ? accent
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    return Semantics(
      label: isBlank ? 'Missing value' : token,
      child: Container(
        constraints: const BoxConstraints(minWidth: 46),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isBlank
              ? accent.withAlpha(isDark ? 30 : 20)
              : (isDark
                    ? AppColors.surfaceContainerHigh
                    : AppColors.surfaceLightClean),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isBlank
                ? accent
                : (isDark ? AppColors.borderDark : AppColors.borderLightClean),
            width: isBlank ? 1.4 : 1,
          ),
        ),
        child: Text(
          token,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TimerBadge extends StatelessWidget {
  final int seconds;
  final bool urgent;

  const _TimerBadge({required this.seconds, required this.urgent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = urgent ? AppColors.errorRed : theme.colorScheme.primary;

    return Semantics(
      label: 'Time remaining: $seconds seconds',
      child: AnimatedContainer(
        key: const ValueKey('sequence-timer'),
        duration: AppConstants.animFast,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withAlpha(isDark ? 26 : 14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(isDark ? 110 : 70)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 17, color: color),
            const SizedBox(width: 6),
            Text(
              '${seconds}s',
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _OptionState { idle, correct, incorrect, muted }

class _AnswerOptionCard extends StatelessWidget {
  final int index;
  final String label;
  final _OptionState state;
  final VoidCallback? onTap;

  const _AnswerOptionCard({
    super.key,
    required this.index,
    required this.label,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = switch (state) {
      _OptionState.correct => AppColors.accentEmerald,
      _OptionState.incorrect => AppColors.errorRed,
      _ => theme.colorScheme.primary,
    };
    final borderColor = switch (state) {
      _OptionState.correct || _OptionState.incorrect => color,
      _OptionState.muted =>
        isDark ? AppColors.borderDark : AppColors.borderLightClean,
      _ =>
        isDark
            ? AppColors.borderLightStrong.withAlpha(130)
            : AppColors.borderLightStrong,
    };
    final backgroundColor = switch (state) {
      _OptionState.correct => color.withAlpha(isDark ? 24 : 14),
      _OptionState.incorrect => color.withAlpha(isDark ? 24 : 14),
      _ => null,
    };
    final textColor = state == _OptionState.muted
        ? (isDark ? AppColors.textMutedDark : AppColors.textMutedLight)
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);
    final letter = String.fromCharCode(65 + index);

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: 'Option $letter: $label',
      child: GymCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        borderRadius: AppConstants.radiusControl,
        borderColor: borderColor,
        borderWidth: state == _OptionState.idle || state == _OptionState.muted
            ? 1
            : 1.5,
        backgroundColor: backgroundColor,
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withAlpha(
                  state == _OptionState.idle ? 0 : (isDark ? 28 : 16),
                ),
                border: Border.all(
                  color: state == _OptionState.muted
                      ? borderColor
                      : color.withAlpha(170),
                  width: 1.4,
                ),
              ),
              child: Text(
                letter,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: state == _OptionState.muted
                      ? (isDark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight)
                      : color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: state == _OptionState.correct
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
            ),
            if (state == _OptionState.correct)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.accentEmerald,
                size: 20,
              ),
            if (state == _OptionState.incorrect)
              const Icon(
                Icons.cancel_rounded,
                color: AppColors.errorRed,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _AnswerFeedback extends StatelessWidget {
  final SequenceMasterQuestion question;
  final int? selectedIndex;
  final bool timedOut;

  const _AnswerFeedback({
    required this.question,
    required this.selectedIndex,
    required this.timedOut,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCorrect = selectedIndex == question.correctOptionIndex;
    final accent = isCorrect ? AppColors.accentEmerald : AppColors.errorRed;
    final title = isCorrect
        ? 'Correct'
        : timedOut
        ? "Time's up"
        : 'Not quite';
    final selectedLabel = selectedIndex == null
        ? null
        : question.options[selectedIndex!];

    return GymCard(
      key: const ValueKey('sequence-feedback'),
      backgroundColor: accent.withAlpha(isDark ? 20 : 10),
      borderColor: accent,
      borderWidth: 1.2,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCorrect
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
            color: accent,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                if (selectedLabel != null && !isCorrect)
                  Text(
                    'You chose $selectedLabel.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                Text(
                  'Correct answer: ${question.correctAnswer}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  question.explanation,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textMutedDark
                        : AppColors.textMutedLight,
                    height: 1.35,
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

class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GymCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final int index;
  final SequenceMasterQuestion question;
  final int? selectedIndex;

  const _ReviewCard({
    super.key,
    required this.index,
    required this.question,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isCorrect = selectedIndex == question.correctOptionIndex;
    final accent = isCorrect ? AppColors.accentEmerald : AppColors.errorRed;
    final selectedLabel = selectedIndex == null
        ? 'No answer'
        : question.options[selectedIndex!];

    return GymCard(
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
                color: accent,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${index + 1}. ${question.sequenceText}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your answer: $selectedLabel',
            style: theme.textTheme.bodySmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (!isCorrect)
            Text(
              'Correct answer: ${question.correctAnswer}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.accentEmerald,
                fontWeight: FontWeight.w500,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            question.explanation,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textMutedDark
                  : AppColors.textMutedLight,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

Color _categoryColor(SequenceCategory category) {
  return switch (category) {
    SequenceCategory.alphabet => AppColors.mathYellow,
    SequenceCategory.number => AppColors.memoryBlue,
    SequenceCategory.mixed => AppColors.puzzleGreen,
    SequenceCategory.visual => AppColors.logicPink,
  };
}

Color _difficultyColor(SequenceMasterDifficulty difficulty) {
  return switch (difficulty) {
    SequenceMasterDifficulty.easy => AppColors.accentEmerald,
    SequenceMasterDifficulty.medium => AppColors.accentAmber,
    SequenceMasterDifficulty.hard => AppColors.accentCrimson,
  };
}

IconData _difficultyIcon(SequenceMasterDifficulty difficulty) {
  return switch (difficulty) {
    SequenceMasterDifficulty.easy => Icons.self_improvement_rounded,
    SequenceMasterDifficulty.medium => Icons.bolt_rounded,
    SequenceMasterDifficulty.hard => Icons.flash_on_rounded,
  };
}
