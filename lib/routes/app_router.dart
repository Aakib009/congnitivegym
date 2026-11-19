import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/debate_session.dart';
import '../models/debate_topic.dart';
import '../screens/about_screen.dart';
import '../screens/account_screen.dart';
import '../screens/achievements_screen.dart';
import '../screens/analytics_screen.dart';
import '../screens/debate_arena_screen.dart';
import '../screens/debate_chat_screen.dart';
import '../screens/debate_loading_screen.dart';
import '../screens/games_screen.dart';
import '../screens/home_screen.dart';
import '../screens/journal_screen.dart';
import '../screens/login_screen.dart';
import '../screens/observation_challenge_screen.dart';
import '../screens/scenario_lab_screen.dart';
import '../screens/sequence_master_screen.dart';
import '../screens/spot_the_difference_screen.dart';
import '../screens/sign_up_screen.dart';
import '../screens/story_builder_screen.dart';
import '../services/auth_service.dart';
import '../widgets/scaffold_with_nav_bar.dart';

/// AppRouter centralizes all named route definitions and GoRouter configuration.
class AppRouter {
  AppRouter._();

  /// Flag controlling authentication guard during routing.
  /// Set to true to temporarily bypass login and open the Homepage directly on launch for testing.
  static bool bypassAuthForTesting = true;

  static const String homeRoute = '/';
  static const String gamesRoute = '/games';
  static const String loginRoute = '/login';
  static const String signUpRoute = '/signup';
  static const String accountRoute = '/account';
  static const String journalRoute = '/journal';
  static const String aboutRoute = '/about';
  static const String achievementsRoute = '/achievements';
  static const String analyticsRoute = '/analytics';
  static const String storyBuilderRoute = '/story-builder';
  static const String observationChallengeRoute = '/observation-challenge';
  static const String sequenceMasterRoute = '/sequence-master';
  static const String spotTheDifferenceRoute = '/spot-the-difference';
  static const String scenarioLabRoute = '/scenario-lab';
  static const String debateArenaRoute = '/debate-arena';
  static const String debateLoadingRoute = '/debate-loading';
  static const String debateChatRoute = '/debate-chat';
  static const String mindTreeExerciseRoute = '/mind-tree-exercise';

  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  /// Global root navigator key for overlay presentations and notification context.
  static GlobalKey<NavigatorState> get rootNavigatorKey => _rootNavigatorKey;

  /// Evaluates authentication state and returns redirect destination, or null if allowed.
  static String? getRedirectForLocation(String location) {
    // When testing mode is active, bypass login and allow direct access to all screens
    if (bypassAuthForTesting) {
      return null;
    }

    final auth = AuthService.instance;
    final isLoggedIn = auth.isLoggedIn;
    final isLoggingIn = location == loginRoute;
    final isSigningUp = location == signUpRoute;

    // If user is not logged in, redirect any protected route to login
    if (!isLoggedIn) {
      if (isLoggingIn || isSigningUp) {
        return null; // Allow unauthenticated access to login & signup
      }
      return loginRoute;
    }

    // If user is already logged in and navigates to login or signup, redirect to home
    if (isLoggingIn || isSigningUp) {
      return homeRoute;
    }

    return null;
  }

  /// Configured GoRouter instance with bottom nav, module routes, and authentication guards.
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: homeRoute,
    refreshListenable: AuthService.instance,
    debugLogDiagnostics: true,
    redirect: (BuildContext context, GoRouterState state) {
      return getRedirectForLocation(state.matchedLocation);
    },
    routes: [
      GoRoute(
        path: aboutRoute,
        name: 'about',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: analyticsRoute,
        name: 'analytics',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: loginRoute,
        name: 'login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: signUpRoute,
        name: 'signUp',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: storyBuilderRoute,
        name: 'storyBuilder',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const StoryBuilderScreen(),
      ),
      GoRoute(
        path: observationChallengeRoute,
        name: 'observationChallenge',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => ObservationChallengeScreen(
          initialDifficulty: state.extra is int ? state.extra as int : null,
        ),
      ),
      GoRoute(
        path: sequenceMasterRoute,
        name: 'sequenceMaster',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SequenceMasterScreen(),
      ),
      GoRoute(
        path: spotTheDifferenceRoute,
        name: 'spotTheDifference',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SpotTheDifferenceScreen(),
      ),
      GoRoute(
        path: scenarioLabRoute,
        name: 'scenarioLab',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ScenarioLabScreen(),
      ),
      GoRoute(
        path: debateArenaRoute,
        name: 'debateArena',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const DebateArenaScreen(),
      ),
      GoRoute(
        path: debateLoadingRoute,
        name: 'debateLoading',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final topic = state.extra as DebateTopic?;
          return DebateLoadingScreen(topic: topic);
        },
      ),
      GoRoute(
        path: debateChatRoute,
        name: 'debateChat',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            final topic = map['topic'] as DebateTopic?;
            final userSide =
                map['userSide'] as DebateSide? ?? DebateSide.support;
            return DebateChatScreen(topic: topic, initialUserSide: userSide);
          }
          final topic = state.extra as DebateTopic?;
          return DebateChatScreen(topic: topic);
        },
      ),
      GoRoute(
        path: mindTreeExerciseRoute,
        name: 'mindTreeExercise',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const HomeScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Home Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: homeRoute,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Branch 2: Games Library
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: gamesRoute,
                name: 'games',
                builder: (context, state) => const GamesScreen(),
              ),
            ],
          ),
          // Branch 3: Dedicated Achievements
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: achievementsRoute,
                name: 'achievements',
                builder: (context, state) => const AchievementsScreen(),
              ),
            ],
          ),
          // Branch 4: Cognitive Journal
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: journalRoute,
                name: 'journal',
                builder: (context, state) => const JournalScreen(),
              ),
            ],
          ),
          // Branch 5: Account Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: accountRoute,
                name: 'account',
                builder: (context, state) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
