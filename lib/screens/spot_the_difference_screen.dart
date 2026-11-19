import '../services/achievement_service.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/spot_the_difference.dart';
import '../routes/app_router.dart';
import '../services/exercise_scoring_service.dart';
import '../services/progress_service.dart';
import '../services/sound_service.dart';
import '../services/spot_the_difference_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/gym_card.dart';

enum SpotStage { intro, playing, results }

/// Production-ready Spot the Difference cognitive exercise screen.
class SpotTheDifferenceScreen extends StatefulWidget {
  final SpotDifferenceDifficulty? initialDifficulty;
  final String? initialChallengeId;

  const SpotTheDifferenceScreen({
    super.key,
    this.initialDifficulty,
    this.initialChallengeId,
  });

  @override
  State<SpotTheDifferenceScreen> createState() =>
      _SpotTheDifferenceScreenState();
}

class _SpotTheDifferenceScreenState extends State<SpotTheDifferenceScreen> {
  late SpotDifferenceDifficulty _selectedDifficulty;
  StreamSubscription<AchievementItem>? _achievementSubscription;
  late List<SpotDifferenceChallenge> _allChallenges;
  late int _selectedChallengeIndex;

  SpotStage _stage = SpotStage.intro;
  final Set<String> _discoveredIds = <String>{};
  int _incorrectTaps = 0;
  int _remainingSeconds = 0;
  bool _isSubmitting = false;
  bool _hasRecordedCompletion = false;

  Timer? _countdownTimer;
  DateTime? _sessionStartedAt;
  String? _attemptId;
  ExerciseScoreResult? _lastScoreResult;
  int _lastObservationGain = 0;

  // Visual feedback markers for brief incorrect tap animation
  _TransientTapMarker? _lastIncorrectTap;
  Timer? _markerFadeTimer;

  SpotDifferenceChallenge get _currentChallenge =>
      _allChallenges[_selectedChallengeIndex];

  @override
  void initState() {
    super.initState();
    _selectedDifficulty =
        widget.initialDifficulty ?? SpotDifferenceDifficulty.easy;
    _allChallenges = SpotTheDifferenceService.getAllChallenges();

    _selectedChallengeIndex = 0;
    if (widget.initialChallengeId != null) {
      final idx = _allChallenges.indexWhere(
        (c) => c.id == widget.initialChallengeId,
      );
      if (idx >= 0) _selectedChallengeIndex = idx;
    }
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
    _countdownTimer?.cancel();
    _markerFadeTimer?.cancel();
    super.dispose();
  }

  void _startSession() {
    _countdownTimer?.cancel();
    _markerFadeTimer?.cancel();

    final startedAt = DateTime.now();
    setState(() {
      _discoveredIds.clear();
      _incorrectTaps = 0;
      _remainingSeconds = _selectedDifficulty.timeLimitSeconds;
      _sessionStartedAt = startedAt;
      _attemptId =
          'spot_${_currentChallenge.id}_${_selectedDifficulty.name}_${startedAt.microsecondsSinceEpoch}';
      _lastScoreResult = null;
      _lastObservationGain = 0;
      _isSubmitting = false;
      _hasRecordedCompletion = false;
      _lastIncorrectTap = null;
      _stage = SpotStage.playing;
    });

    _armCountdownTimer();
  }

  void _armCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_stage != SpotStage.playing) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        SoundService.instance.playPop();
        _finishSession(timedOut: true);
        return;
      }
      setState(() {
        _remainingSeconds -= 1;
      });
    });
  }

  void _handleImageTap(double normX, double normY, int panelIndex) {
    if (_stage != SpotStage.playing || _isSubmitting) return;

    final challenge = _currentChallenge;
    final hit = challenge.findMatchingDifference(
      normX: normX,
      normY: normY,
      discoveredIds: _discoveredIds,
    );

    if (hit != null) {
      SoundService.instance.playConfirmation();
      setState(() {
        _discoveredIds.add(hit.id);
      });

      // Check if all differences in this challenge have been discovered
      if (_discoveredIds.length >= challenge.totalDifferences) {
        SoundService.instance.playRewardSuccess();
        _finishSession(timedOut: false);
      }
    } else {
      SoundService.instance.playPop();
      setState(() {
        _incorrectTaps += 1;
        _lastIncorrectTap = _TransientTapMarker(
          x: normX,
          y: normY,
          panelIndex: panelIndex,
        );
      });

      _markerFadeTimer?.cancel();
      _markerFadeTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) {
          setState(() {
            _lastIncorrectTap = null;
          });
        }
      });
    }
  }

  Future<void> _finishSession({required bool timedOut}) async {
    if (_isSubmitting || _hasRecordedCompletion) return;

    _countdownTimer?.cancel();
    _markerFadeTimer?.cancel();

    setState(() {
      _isSubmitting = true;
    });

    final startedAt = _sessionStartedAt;
    final durationSeconds = startedAt == null
        ? 0
        : DateTime.now().difference(startedAt).inSeconds;

    try {
      final challenge = _currentChallenge;
      final result = ExerciseScoringService.scoreSpotTheDifference(
        totalDifferences: challenge.totalDifferences,
        discoveredDifferences: _discoveredIds.length,
        incorrectTaps: _incorrectTaps,
        difficulty: _selectedDifficulty,
        durationSeconds: durationSeconds,
      );

      final observationGain = ExerciseScoringService.scaledGain(
        ExerciseScoringService.spotTheDifferenceBaseObservationPoints,
        result.performanceScore,
      );

      await ProgressService.instance.recordSpotTheDifferenceCompletion(
        performanceScore: result.performanceScore,
        accuracy: result.accuracy ?? 0.0,
        durationSeconds: durationSeconds,
        difficulty: _selectedDifficulty,
        differencesFound: _discoveredIds.length,
        idempotencyKey: _attemptId,
      );

      if (!mounted) return;
      setState(() {
        _lastScoreResult = result;
        _lastObservationGain = observationGain;
        _hasRecordedCompletion = true;
        _stage = SpotStage.results;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save this challenge. Please try again.'),
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

  void _nextChallenge() {
    _countdownTimer?.cancel();
    setState(() {
      _selectedChallengeIndex =
          (_selectedChallengeIndex + 1) % _allChallenges.length;
      _discoveredIds.clear();
      _incorrectTaps = 0;
      _stage = SpotStage.intro;
    });
  }

  void _returnToGames() {
    _countdownTimer?.cancel();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.gamesRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Spot the Difference',
          style: GoogleFonts.rajdhani(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: AppConstants.animNormal,
          child: switch (_stage) {
            SpotStage.intro => _buildIntro(),
            SpotStage.playing => _buildPlaying(),
            SpotStage.results => _buildResults(),
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // INTRO VIEW
  // ===========================================================================
  Widget _buildIntro() {
    final theme = Theme.of(context);
    final accent = AppColors.memoryBlue;
    final challenge = _currentChallenge;

    return _PageScroll(
      key: const ValueKey('spot-intro'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          Align(
            child: _RoundIcon(
              icon: Icons.center_focus_strong_rounded,
              color: accent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Spot the Difference',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Visual discrimination & spatial observation',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // How it Works Card
          GymCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.rule_rounded, color: accent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Mission Brief',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Two near-identical images are displayed. Inspect both images and tap '
                  'every discrepancy you discover. Found differences illuminate on both sides.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
                const SizedBox(height: 14),
                _RuleBullet(
                  text: 'Tap the suspected difference on either image.',
                  color: accent,
                ),
                const SizedBox(height: 8),
                _RuleBullet(
                  text: 'Accurate touches reveal glowing tactical markers.',
                  color: accent,
                ),
                const SizedBox(height: 8),
                _RuleBullet(
                  text:
                      'Misses register as mistakes and affect final observation accuracy.',
                  color: accent,
                ),
                const SizedBox(height: 8),
                _RuleBullet(
                  text:
                      'Find all ${challenge.totalDifferences} differences before the clock expires.',
                  color: accent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Challenge Selection Card
          Text('Selected Challenge', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          GymCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withAlpha(24),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: accent.withAlpha(90)),
                      ),
                      child: Text(
                        challenge.themeTag.toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_selectedChallengeIndex + 1} of ${_allChallenges.length}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.brightness == Brightness.dark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  challenge.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  challenge.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _selectedChallengeIndex > 0
                          ? () {
                              SoundService.instance.playTap();
                              setState(() {
                                _selectedChallengeIndex--;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      label: const Text('Previous'),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          _selectedChallengeIndex < _allChallenges.length - 1
                          ? () {
                              SoundService.instance.playTap();
                              setState(() {
                                _selectedChallengeIndex++;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text('Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Difficulty Picker
          Text('Select Difficulty', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          _DifficultyPicker(
            selected: _selectedDifficulty,
            onSelected: (diff) {
              SoundService.instance.playTap();
              setState(() {
                _selectedDifficulty = diff;
              });
            },
          ),
          const SizedBox(height: 22),

          // Launch CTA
          CustomButton(
            key: const ValueKey('spot-start-button'),
            label: 'Start inspection',
            icon: Icons.play_arrow_rounded,
            width: double.infinity,
            onPressed: _startSession,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ===========================================================================
  // PLAYING VIEW
  // ===========================================================================
  Widget _buildPlaying() {
    final theme = Theme.of(context);
    final challenge = _currentChallenge;
    final total = challenge.totalDifferences;
    final found = _discoveredIds.length;
    final progress = total == 0 ? 0.0 : found / total;
    final timerUrgent = _remainingSeconds <= 10;
    final accent = AppColors.memoryBlue;

    return Column(
      children: [
        // Top HUD Telemetry Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          challenge.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${_selectedDifficulty.label} • Found $found of $total',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_incorrectTaps > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '($_incorrectTaps mistakes)',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.errorRed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _TimerBadge(seconds: _remainingSeconds, urgent: timerUrgent),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: theme.brightness == Brightness.dark
                      ? AppColors.surfaceContainerHigh
                      : AppColors.borderLightClean,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.accentEmerald,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Interactive Dual Image Viewer
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;

              if (isWide) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _InteractiveImagePanel(
                          key: const ValueKey('spot-image-panel-a'),
                          label: 'IMAGE A',
                          assetPath: challenge.imageAssetA,
                          aspectRatio: challenge.aspectRatio,
                          discoveredDifferences: challenge.differences
                              .where((d) => _discoveredIds.contains(d.id))
                              .toList(),
                          transientTap: _lastIncorrectTap?.panelIndex == 0
                              ? _lastIncorrectTap
                              : null,
                          onTapNormalized: (x, y) => _handleImageTap(x, y, 0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InteractiveImagePanel(
                          key: const ValueKey('spot-image-panel-b'),
                          label: 'IMAGE B',
                          assetPath: challenge.imageAssetB,
                          aspectRatio: challenge.aspectRatio,
                          discoveredDifferences: challenge.differences
                              .where((d) => _discoveredIds.contains(d.id))
                              .toList(),
                          transientTap: _lastIncorrectTap?.panelIndex == 1
                              ? _lastIncorrectTap
                              : null,
                          onTapNormalized: (x, y) => _handleImageTap(x, y, 1),
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _InteractiveImagePanel(
                          key: const ValueKey('spot-image-panel-a'),
                          label: 'IMAGE A',
                          assetPath: challenge.imageAssetA,
                          aspectRatio: challenge.aspectRatio,
                          discoveredDifferences: challenge.differences
                              .where((d) => _discoveredIds.contains(d.id))
                              .toList(),
                          transientTap: _lastIncorrectTap?.panelIndex == 0
                              ? _lastIncorrectTap
                              : null,
                          onTapNormalized: (x, y) => _handleImageTap(x, y, 0),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _InteractiveImagePanel(
                          key: const ValueKey('spot-image-panel-b'),
                          label: 'IMAGE B',
                          assetPath: challenge.imageAssetB,
                          aspectRatio: challenge.aspectRatio,
                          discoveredDifferences: challenge.differences
                              .where((d) => _discoveredIds.contains(d.id))
                              .toList(),
                          transientTap: _lastIncorrectTap?.panelIndex == 1
                              ? _lastIncorrectTap
                              : null,
                          onTapNormalized: (x, y) => _handleImageTap(x, y, 1),
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // RESULTS VIEW
  // ===========================================================================
  Widget _buildResults() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final challenge = _currentChallenge;
    final total = challenge.totalDifferences;
    final found = _discoveredIds.length;
    final result = _lastScoreResult;
    final accuracy = result?.accuracy ?? 0.0;
    final performance = result?.performanceScore.round() ?? 0;
    final xp = result?.xpEarned ?? 0;
    final accent = AppColors.memoryBlue;

    return _PageScroll(
      key: const ValueKey('spot-results'),
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
            'Observation Complete',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$found / $total Differences',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${accuracy.round()}% touch accuracy • ${_selectedDifficulty.label} difficulty',
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

          // Rewards summary card
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
                    Icon(Icons.visibility_rounded, color: accent, size: 19),
                    const SizedBox(width: 6),
                    Text(
                      '+$_lastObservationGain observation points',
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

          // Stat Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 560 ? 4 : 2;
              final width =
                  (constraints.maxWidth - ((columns - 1) * 10)) / columns;
              final stats = [
                _ResultStat(
                  label: 'Found',
                  value: '$found/$total',
                  color: AppColors.accentEmerald,
                ),
                _ResultStat(
                  label: 'Mistakes',
                  value: '$_incorrectTaps',
                  color: _incorrectTaps > 0
                      ? AppColors.errorRed
                      : AppColors.accentEmerald,
                ),
                _ResultStat(
                  label: 'Accuracy',
                  value: '${accuracy.round()}%',
                  color: theme.colorScheme.primary,
                ),
                _ResultStat(
                  label: 'Score',
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

          // Breakdown of Discovered Differences
          Text(
            'Difference Breakdown',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < challenge.differences.length; i++) ...[
            _DifferenceReviewCard(
              index: i + 1,
              difference: challenge.differences[i],
              wasDiscovered: _discoveredIds.contains(
                challenge.differences[i].id,
              ),
            ),
            if (i != challenge.differences.length - 1)
              const SizedBox(height: 8),
          ],
          const SizedBox(height: 24),

          // Bottom Action CTAs
          LayoutBuilder(
            builder: (context, constraints) {
              final isStacked = constraints.maxWidth < 520;
              final actions = [
                CustomButton(
                  key: const ValueKey('spot-replay-button'),
                  label: 'Replay Challenge',
                  icon: Icons.replay_rounded,
                  width: isStacked ? double.infinity : null,
                  onPressed: _startSession,
                ),
                CustomButton(
                  key: const ValueKey('spot-next-button'),
                  label: 'Next Challenge',
                  icon: Icons.skip_next_rounded,
                  style: CustomButtonStyle.secondary,
                  width: isStacked ? double.infinity : null,
                  onPressed: _nextChallenge,
                ),
              ];

              if (isStacked) {
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
          const SizedBox(height: 10),
          CustomButton(
            key: const ValueKey('spot-games-button'),
            label: 'Back to Games',
            icon: Icons.sports_esports_rounded,
            style: CustomButtonStyle.outline,
            width: double.infinity,
            onPressed: _returnToGames,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// =============================================================================
// INTERACTIVE IMAGE PANEL (COORDINATE MAPPING & TOUCH HIT-TESTING)
// =============================================================================
class _InteractiveImagePanel extends StatelessWidget {
  final String label;
  final String assetPath;
  final double aspectRatio;
  final List<DifferenceTarget> discoveredDifferences;
  final _TransientTapMarker? transientTap;
  final void Function(double normX, double normY) onTapNormalized;

  const _InteractiveImagePanel({
    super.key,
    required this.label,
    required this.assetPath,
    required this.aspectRatio,
    required this.discoveredDifferences,
    required this.transientTap,
    required this.onTapNormalized,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GymCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final containerW = constraints.maxWidth;
              final containerH = constraints.maxHeight;
              final containerAspect = containerW / containerH;

              double renderedW;
              double renderedH;
              double offsetX;
              double offsetY;

              if (containerAspect > aspectRatio) {
                // Constrained by height
                renderedH = containerH;
                renderedW = containerH * aspectRatio;
                offsetX = (containerW - renderedW) / 2;
                offsetY = 0;
              } else {
                // Constrained by width
                renderedW = containerW;
                renderedH = containerW / aspectRatio;
                offsetX = 0;
                offsetY = (containerH - renderedH) / 2;
              }

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  final localX = details.localPosition.dx;
                  final localY = details.localPosition.dy;

                  // Verify tap falls inside actual rendered image bounds
                  if (localX < offsetX ||
                      localX > offsetX + renderedW ||
                      localY < offsetY ||
                      localY > offsetY + renderedH) {
                    return;
                  }

                  final normX = (localX - offsetX) / renderedW;
                  final normY = (localY - offsetY) / renderedH;
                  onTapNormalized(normX, normY);
                },
                child: Stack(
                  children: [
                    // Rendered Image Asset
                    Positioned(
                      left: offsetX,
                      top: offsetY,
                      width: renderedW,
                      height: renderedH,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusControl,
                        ),
                        child: Image.asset(
                          assetPath,
                          fit: BoxFit.fill,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: isDark
                                    ? AppColors.surfaceContainerHigh
                                    : AppColors.borderLightClean,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image_rounded,
                                    size: 32,
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),

                    // Discovered Difference Markers (Glow Rings)
                    for (var i = 0; i < discoveredDifferences.length; i++)
                      Positioned(
                        left:
                            offsetX +
                            (discoveredDifferences[i].x * renderedW) -
                            18,
                        top:
                            offsetY +
                            (discoveredDifferences[i].y * renderedH) -
                            18,
                        child: _DiscoveredMarker(index: i + 1),
                      ),

                    // Transient Incorrect Tap Animation Marker
                    if (transientTap != null)
                      Positioned(
                        left: offsetX + (transientTap!.x * renderedW) - 14,
                        top: offsetY + (transientTap!.y * renderedH) - 14,
                        child: const _MissMarker(),
                      ),
                  ],
                ),
              );
            },
          ),

          // Label Badge in Top-Left Corner
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(160),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                label,
                style: GoogleFonts.barlowCondensed(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Discovered Difference Tactical Marker
class _DiscoveredMarker extends StatelessWidget {
  final int index;

  const _DiscoveredMarker({required this.index});

  @override
  Widget build(BuildContext context) {
    const ringColor = AppColors.accentEmerald;
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ringColor.withAlpha(45),
        border: Border.all(color: ringColor, width: 2.2),
        boxShadow: [
          BoxShadow(
            color: ringColor.withAlpha(120),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Text(
        '$index',
        style: GoogleFonts.barlowCondensed(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// Transient Miss Marker (Red X)
class _MissMarker extends StatelessWidget {
  const _MissMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.errorRed.withAlpha(50),
        border: Border.all(color: AppColors.errorRed, width: 1.8),
      ),
      child: const Icon(
        Icons.close_rounded,
        color: AppColors.errorRed,
        size: 18,
      ),
    );
  }
}

class _TransientTapMarker {
  final double x;
  final double y;
  final int panelIndex;

  const _TransientTapMarker({
    required this.x,
    required this.y,
    required this.panelIndex,
  });
}

// =============================================================================
// SUPPORTING WIDGETS
// =============================================================================
class _PageScroll extends StatelessWidget {
  final Widget child;

  const _PageScroll({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
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

class _DifferenceReviewCard extends StatelessWidget {
  final int index;
  final DifferenceTarget difference;
  final bool wasDiscovered;

  const _DifferenceReviewCard({
    required this.index,
    required this.difference,
    required this.wasDiscovered,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = wasDiscovered ? AppColors.accentEmerald : AppColors.errorRed;

    return GymCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            wasDiscovered ? Icons.check_circle_rounded : Icons.cancel_outlined,
            color: accent,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$index. ${difference.description}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            wasDiscovered ? 'Found' : 'Missed',
            style: theme.textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DifficultyPicker extends StatelessWidget {
  final SpotDifferenceDifficulty selected;
  final ValueChanged<SpotDifferenceDifficulty> onSelected;

  const _DifficultyPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final cards = [
      for (final diff in SpotDifferenceDifficulty.values)
        _DifficultyOptionCard(
          key: ValueKey('spot-diff-${diff.name}'),
          difficulty: diff,
          isSelected: diff == selected,
          onTap: () => onSelected(diff),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 660) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i != cards.length - 1) const SizedBox(height: 10),
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

class _DifficultyOptionCard extends StatelessWidget {
  final SpotDifferenceDifficulty difficulty;
  final bool isSelected;
  final VoidCallback onTap;

  const _DifficultyOptionCard({
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
          '${difficulty.label}: ${difficulty.timeLimitSeconds} seconds limit',
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
                  width: 32,
                  height: 32,
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
            const SizedBox(height: 8),
            Text(
              difficulty.description,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.35,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: color.withAlpha(isDark ? 24 : 14),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: color.withAlpha(isDark ? 90 : 55)),
              ),
              child: Text(
                '${difficulty.timeLimitSeconds}s Limit',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _difficultyColor(SpotDifferenceDifficulty difficulty) {
  return switch (difficulty) {
    SpotDifferenceDifficulty.easy => AppColors.accentEmerald,
    SpotDifferenceDifficulty.medium => AppColors.accentAmber,
    SpotDifferenceDifficulty.hard => AppColors.accentCrimson,
  };
}

IconData _difficultyIcon(SpotDifferenceDifficulty difficulty) {
  return switch (difficulty) {
    SpotDifferenceDifficulty.easy => Icons.self_improvement_rounded,
    SpotDifferenceDifficulty.medium => Icons.bolt_rounded,
    SpotDifferenceDifficulty.hard => Icons.flash_on_rounded,
  };
}
