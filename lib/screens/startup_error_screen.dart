import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/progress_service.dart';
import '../services/reward_manager.dart';
import '../services/theme_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/gym_card.dart';

/// Clean Material 3 Startup Error Screen displayed if an unhandled initialization exception occurs.
class StartupErrorScreen extends StatefulWidget {
  final String errorMessage;
  final StackTrace? stackTrace;
  final VoidCallback? onRetry;

  const StartupErrorScreen({
    super.key,
    required this.errorMessage,
    this.stackTrace,
    this.onRetry,
  });

  @override
  State<StartupErrorScreen> createState() => _StartupErrorScreenState();
}

class _StartupErrorScreenState extends State<StartupErrorScreen> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    setState(() {
      _isRetrying = true;
    });

    try {
      DatabaseService.initializeFactory();
      await ThemeService.instance.init();
      await AuthService.instance.initialize();
      await ProgressService.instance.init();
      await RewardManager.instance.init();

      if (widget.onRetry != null) {
        widget.onRetry!();
      } else {
        // Trigger app rebuild
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.error.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 56,
                    color: colorScheme.error,
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'Initialization Warning',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Cognitive Gym encountered an issue while starting local services or SQLite database.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface.withAlpha(160),
                  ),
                ),
                const SizedBox(height: 24),

                GymCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.error_outline_rounded,
                              size: 18, color: colorScheme.error),
                          const SizedBox(width: 8),
                          Text(
                            'ERROR DETAILS',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.errorMessage,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                CustomButton(
                  label: _isRetrying ? 'Retrying Initialization...' : 'Retry Startup',
                  icon: Icons.refresh_rounded,
                  style: CustomButtonStyle.primary,
                  isLoading: _isRetrying,
                  width: double.infinity,
                  onPressed: _isRetrying ? null : _handleRetry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
