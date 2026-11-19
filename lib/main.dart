import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'routes/app_router.dart';
import 'screens/startup_error_screen.dart';
import 'services/achievement_service.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/progress_service.dart';
import 'services/reward_manager.dart';
import 'services/theme_service.dart';
import 'utils/app_constants.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? startupError;
  StackTrace? startupStackTrace;

  try {
    // Core application service initializations
    DatabaseService.initializeFactory();
    await AuthService.instance.initialize();
    await ThemeService.instance.init();
    await ProgressService.instance.init();
    await RewardManager.instance.init();
    await AchievementService.instance.init();
  } catch (e, stack) {
    startupError = e.toString();
    startupStackTrace = stack;
    if (kDebugMode) {
      print('[Startup Error] Failed to initialize services: $e\n$stack');
    }
  }

  runApp(
    CognitiveGymApp(
      startupError: startupError,
      startupStackTrace: startupStackTrace,
    ),
  );
}

/// Root widget configuring Material 3 theme and declarative router.
class CognitiveGymApp extends StatefulWidget {
  final String? startupError;
  final StackTrace? startupStackTrace;

  const CognitiveGymApp({super.key, this.startupError, this.startupStackTrace});

  @override
  State<CognitiveGymApp> createState() => _CognitiveGymAppState();
}

class _CognitiveGymAppState extends State<CognitiveGymApp> {
  String? _currentError;
  StackTrace? _currentStackTrace;
  StreamSubscription<AchievementItem>? _achievementSubscription;

  @override
  void initState() {
    super.initState();
    _currentError = widget.startupError;
    _currentStackTrace = widget.startupStackTrace;
    _achievementSubscription = AchievementService.instance.onAchievementUnlocked
        .listen((item) {
          final navContext = AppRouter.rootNavigatorKey.currentContext;
          if (navContext != null && navContext.mounted) {
            AchievementService.showUnlockSnackBar(navContext, item);
          }
        });
  }

  @override
  void dispose() {
    _achievementSubscription?.cancel();
    super.dispose();
  }

  void _resetError() {
    setState(() {
      _currentError = null;
      _currentStackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentError != null) {
      return MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: StartupErrorScreen(
          errorMessage: _currentError!,
          stackTrace: _currentStackTrace,
          onRetry: _resetError,
        ),
      );
    }

    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final currentMode = ThemeService.instance.currentTheme;
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getThemeData(currentMode),
          routerConfig: AppRouter.router,
        );
      },
    );
  }
}
