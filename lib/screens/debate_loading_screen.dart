import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/debate_topic.dart';
import '../routes/app_router.dart';
import '../utils/app_colors.dart';
import '../widgets/gym_card.dart';

/// Brief loading screen shown before a debate starts.
class DebateLoadingScreen extends StatefulWidget {
  final DebateTopic? topic;

  const DebateLoadingScreen({
    super.key,
    this.topic,
  });

  @override
  State<DebateLoadingScreen> createState() => _DebateLoadingScreenState();
}

class _DebateLoadingScreenState extends State<DebateLoadingScreen> {
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _navigationTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        context.pushReplacement(AppRouter.debateChatRoute, extra: widget.topic);
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mutedColor =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final topicTitle = widget.topic?.title ?? 'Debate Arena dilemma';

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GymCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceContainerHigh
                              : AppColors.surfaceLightClean,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Debate Arena',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.puzzleGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        topicTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  ),
                ),

                const SizedBox(height: 18),

                Text(
                  'Preparing debate',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Setting up the discussion space.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
