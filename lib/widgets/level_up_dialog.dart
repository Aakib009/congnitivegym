import 'package:flutter/material.dart';
import '../models/rank_model.dart';
import '../services/reward_manager.dart';
import '../services/sound_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_constants.dart';
import 'confetti_celebration.dart';
import 'custom_button.dart';
import 'rank_emblem.dart';

/// Modal dialog presented when the user levels up to a new Mind Tree Stage.
class LevelUpDialogWidget extends StatefulWidget {
  final LevelUpEvent levelUpEvent;

  const LevelUpDialogWidget({
    super.key,
    required this.levelUpEvent,
  });

  /// Displays the LevelUpDialogWidget with confetti overlay.
  static Future<void> show(BuildContext context, LevelUpEvent event) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => LevelUpDialogWidget(levelUpEvent: event),
    );
  }

  @override
  State<LevelUpDialogWidget> createState() => _LevelUpDialogWidgetState();
}

class _LevelUpDialogWidgetState extends State<LevelUpDialogWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _treeGrowthAnimation;

  @override
  void initState() {
    super.initState();
    SoundService.instance.playLevelUp();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );

    _treeGrowthAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final event = widget.levelUpEvent;
    final stageInfo = event.stageInfo;
    final isLevel10 = event.isMasteryLevel10;

    return Stack(
      children: [
        // Confetti Canvas Particle Overlay
        const ConfettiCelebrationWidget(),

        // Dialog Card
        Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Dialog(
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppConstants.borderRadiusLarge),
              ),
              backgroundColor: isLevel10
                  ? const Color(0xFF1E1602)
                  : (isDark
                      ? AppColors.darkCardSurface
                      : AppColors.lightSurface),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tactical Rank Promotion Emblem
                    ScaleTransition(
                      scale: _treeGrowthAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (isLevel10 ? AppColors.rankGrandmaster : theme.colorScheme.primary).withAlpha(25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (isLevel10 ? AppColors.rankGrandmaster : theme.colorScheme.primary).withAlpha(90),
                            width: 2,
                          ),
                        ),
                        child: RankEmblem(
                          tier: CognitiveRankTier.values[(stageInfo.level - 1).clamp(0, CognitiveRankTier.values.length - 1)],
                          size: 56,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Level Up Title
                    Text(
                      isLevel10
                          ? 'APEX GRANDMASTER UNLOCKED!'
                          : 'RANK PROMOTION!',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isLevel10
                            ? AppColors.rankGrandmaster
                            : theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      'Level ${stageInfo.level} · ${CognitiveRankTier.values[(stageInfo.level - 1).clamp(0, CognitiveRankTier.values.length - 1)].title.toUpperCase()}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isLevel10
                            ? AppColors.rankGrandmaster
                            : (isDark ? Colors.white : AppColors.textPrimaryLight),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),

                    Text(
                      isLevel10
                          ? 'Outstanding achievement! You have reached the pinnacle of Cognitive Gym mastery. Your mental acuity and discipline are supreme.'
                          : 'Your daily cognitive training has unlocked a new competitive rank tier in the Cognitive Gym arena.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Required Points Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.groundDark : Colors.white,
                        borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusPill),
                        border: Border.all(
                          color: (isLevel10 ? AppColors.rankGrandmaster : theme.colorScheme.primary).withAlpha(120),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.military_tech_rounded,
                            color: isLevel10 ? AppColors.rankGrandmaster : theme.colorScheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${stageInfo.requiredPoints} XP Milestone',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Continue Action Button
                    CustomButton(
                      label: isLevel10 ? 'Claim Apex Honor' : 'Continue Training',
                      style: CustomButtonStyle.primary,
                      width: double.infinity,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
