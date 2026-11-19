import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/scenario_model.dart';
import '../routes/app_router.dart';
import '../services/exercise_scoring_service.dart';
import '../services/progress_service.dart';
import '../services/scenario_lab_service.dart';
import '../services/tts_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/gym_card.dart';

/// Redesigned Scenario Lab screen providing a calm, immersive, interactive story experience.
class ScenarioLabScreen extends StatefulWidget {
  const ScenarioLabScreen({super.key});

  @override
  State<ScenarioLabScreen> createState() => _ScenarioLabScreenState();
}

class _ScenarioLabScreenState extends State<ScenarioLabScreen> {
  late ScenarioModel _currentScenario;
  int? _selectedOptionIndex;
  bool _hasConfirmedChoice = false;
  bool _isNarrating = false;

  // Scoring state. Deliberation time is measured from the moment the scenario
  // was loaded until the decision was confirmed. [_hasRecordedCompletion]
  // guarantees each scenario is only scored/recorded once, so "Re-examine"
  // cannot be used to farm repeated rewards for the same scenario.
  DateTime? _scenarioOpenedAt;
  String? _attemptId;
  bool _hasRecordedCompletion = false;
  ExerciseScoreResult? _lastScoreResult;

  @override
  void initState() {
    super.initState();
    _loadNewScenario();
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  void _loadNewScenario([String? id]) {
    TtsService.instance.stop();
    setState(() {
      _currentScenario = id != null
          ? ScenarioLabService.getScenarioById(id)
          : ScenarioLabService.getRandomScenario();
      _selectedOptionIndex = null;
      _hasConfirmedChoice = false;
      _isNarrating = false;
      // New scenario: restart deliberation measurement and allow exactly one
      // recorded completion for it with a stable attempt ID.
      _scenarioOpenedAt = DateTime.now();
      _attemptId =
          'scenario_${_currentScenario.id}_${_scenarioOpenedAt!.millisecondsSinceEpoch}';
      _hasRecordedCompletion = false;
      _lastScoreResult = null;
    });
  }

  void _confirmChoice() {
    TtsService.instance.stop();
    if (_selectedOptionIndex != null) {
      // Record the completion exactly once per scenario. The scenarios are
      // balanced trade-off dilemmas with no objectively correct option, so
      // the deterministic score is the measured deliberation engagement
      // (see ExerciseScoringService.scoreScenarioLab).
      if (!_hasRecordedCompletion) {
        _hasRecordedCompletion = true;
        final scenarioWordCount = ExerciseScoringService.wordCount(
            '${_currentScenario.background} ${_currentScenario.objective} ${_currentScenario.constraints}');
        final deliberationSeconds = _scenarioOpenedAt == null
            ? 0
            : DateTime.now().difference(_scenarioOpenedAt!).inSeconds;

        final result = ExerciseScoringService.scoreScenarioLab(
          scenarioWordCount: scenarioWordCount,
          deliberationSeconds: deliberationSeconds,
        );
        _lastScoreResult = result;

        ProgressService.instance.recordScenarioLabCompletion(
          performanceScore: result.performanceScore,
          durationSeconds: deliberationSeconds,
          idempotencyKey: _attemptId,
        );
      }
      setState(() {
        _hasConfirmedChoice = true;
        _isNarrating = false;
      });
    }
  }

  void _resetCurrentScenarioChoice() {
    TtsService.instance.stop();
    setState(() {
      _selectedOptionIndex = null;
      _hasConfirmedChoice = false;
      _isNarrating = false;
    });
  }

  /// Combines background, objective, and constraints into a single cohesive story narrative.
  String get _integratedNarrative {
    final bg = _currentScenario.background.trim();
    final obj = _currentScenario.objective.trim();
    final constr = _currentScenario.constraints.trim();

    final parts = <String>[bg];
    if (obj.isNotEmpty) {
      parts.add('Your objective: $obj');
    }
    if (constr.isNotEmpty) {
      parts.add(constr);
    }
    return parts.join(' ');
  }

  /// Toggles Text-to-Speech narration of the scenario narrative.
  void _toggleTts() {
    TtsService.instance.speak(_integratedNarrative, onStateChanged: () {
      if (mounted) {
        setState(() {
          _isNarrating = TtsService.instance.isPlaying;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scenario Lab'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.autorenew_rounded),
            tooltip: 'Next Scenario',
            onPressed: () => _loadNewScenario(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: AnimatedSwitcher(
            duration: AppConstants.animNormal,
            child: !_hasConfirmedChoice
                ? _buildStoryAndDecisionView(theme, colorScheme)
                : _buildResultView(theme, colorScheme),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HERO ILLUSTRATION WIDGET
  // ===========================================================================
  Widget _buildHeroIllustration(ThemeData theme, ColorScheme colorScheme) {
    final imagePath = _currentScenario.imagePath;
    if (imagePath == null || imagePath.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: colorScheme.outline.withAlpha(100),
            width: 1.0,
          ),
          boxShadow: theme.brightness == Brightness.dark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: colorScheme.surfaceContainer,
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: colorScheme.onSurface.withAlpha(100),
                      size: 36,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // STEP 1: INTERACTIVE STORY & DECISION VIEW
  // ===========================================================================
  Widget _buildStoryAndDecisionView(ThemeData theme, ColorScheme colorScheme) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      key: const ValueKey('story_decision_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 0. Hero Illustration Image at the Top
        _buildHeroIllustration(theme, colorScheme),

        // 1. Category Chip & TTS Button Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                _currentScenario.category,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.eventOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // TTS Speaker Button
            InkWell(
              key: const Key('tts_speaker_button'),
              onTap: _toggleTts,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isNarrating
                          ? Icons.volume_up_rounded
                          : Icons.volume_up_outlined,
                      size: 16,
                      color: _isNarrating
                          ? colorScheme.primary
                          : colorScheme.onSurface.withAlpha(160),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isNarrating ? 'Reading' : 'Listen',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _isNarrating
                            ? colorScheme.primary
                            : colorScheme.onSurface.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 2. Scenario Title
        Text(
          _currentScenario.title,
          style: theme.textTheme.titleLarge?.copyWith(height: 1.25),
        ),

        const SizedBox(height: 6),

        // 3. User Role Prompt
        Row(
          children: [
            Icon(
              Icons.person_outline_rounded,
              size: 16,
              color: colorScheme.onSurface.withAlpha(160),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'You are the ${_currentScenario.role}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 4. Integrated Narrative
        GymCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 12.0,
          backgroundColor:
              isDark ? AppColors.surfaceDeep : AppColors.surfaceLightClean,
          borderColor:
              isDark ? AppColors.borderSubtle : AppColors.borderLightClean,
          child: Text(
            _integratedNarrative,
            style: theme.textTheme.bodyLarge?.copyWith(
              height: 1.6,
              color: colorScheme.onSurface,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // 5. Decision Cards
        ..._currentScenario.options.asMap().entries.map((entry) {
          final idx = entry.key;
          final option = entry.value;
          final isSelected = _selectedOptionIndex == idx;
          final accent = colorScheme.primary;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: GymCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 12.0,
              backgroundColor: isSelected
                  ? (isDark
                      ? AppColors.surfaceContainerHigh
                      : AppColors.surfaceLightClean)
                  : (isDark ? AppColors.surface : AppColors.cardLight),
              borderColor: isSelected
                  ? accent
                  : (isDark ? AppColors.borderSubtle : AppColors.borderLightClean),
              borderWidth: isSelected ? 1.5 : 1,
              onTap: () {
                setState(() {
                  _selectedOptionIndex = idx;
                });
              },
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Option Badge (A / B)
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? accent : Colors.transparent,
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
                      String.fromCharCode(65 + idx),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : (isDark
                                ? AppColors.textMutedDark
                                : AppColors.textMutedLight),
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Option Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          option.description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.45,
                            color: colorScheme.onSurface.withAlpha(200),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isSelected) ...[
                    const SizedBox(width: 10),
                    Icon(
                      Icons.check_circle_rounded,
                      color: accent,
                      size: 20,
                    ),
                  ],
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 16),

        // Confirm Button
        CustomButton(
          label: 'Confirm decision',
          icon: Icons.arrow_forward_rounded,
          style: CustomButtonStyle.primary,
          width: double.infinity,
          onPressed: _selectedOptionIndex != null ? _confirmChoice : null,
        ),

        const SizedBox(height: 16),
      ],
    );
  }

  // ===========================================================================
  // STEP 2: DEDICATED RESULT SCREEN
  // ===========================================================================
  Widget _buildResultView(ThemeData theme, ColorScheme colorScheme) {
    final chosenOption = _currentScenario.options[_selectedOptionIndex!];
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      key: const ValueKey('result_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Outcome chip
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              'Decision outcome',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 1. Decision Selected Card
        GymCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 12.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Decision selected',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                chosenOption.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 2. Outcome Card
        GymCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 12.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.auto_stories_outlined,
                    size: 18,
                    color: colorScheme.onSurface.withAlpha(160),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Outcome',
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                chosenOption.consequence,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 3. Reflection Card
        GymCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 12.0,
          backgroundColor: isDark
              ? AppColors.surfaceContainerLow
              : AppColors.surfaceLightClean,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.psychology_outlined,
                    size: 18,
                    color: colorScheme.onSurface.withAlpha(160),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Reflection',
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Consider how this outcome shapes future resilience and aligns with your priorities.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.55,
                  color: colorScheme.onSurface.withAlpha(210),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 4. Deliberation engagement score + real earned rewards.
        if (_lastScoreResult != null) ...[
          Text(
            'Deliberation score: ${_lastScoreResult!.performanceScore.round()}/100',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
        ],
        Center(
          child: Container(
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
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt_rounded,
                  color: colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '+${ExerciseScoringService.scaledGain(15, _lastScoreResult?.performanceScore ?? 0)} decision points · +${_lastScoreResult?.xpEarned ?? _currentScenario.pointsEarned} XP',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Action Buttons: Next Scenario & Re-examine Dilemma
        Row(
          children: [
            Expanded(
              child: CustomButton(
                label: 'Re-examine',
                style: CustomButtonStyle.outline,
                onPressed: _resetCurrentScenarioChoice,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                label: 'Next scenario',
                style: CustomButtonStyle.primary,
                onPressed: () => _loadNewScenario(),
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

        const SizedBox(height: 16),
      ],
    );
  }
}
