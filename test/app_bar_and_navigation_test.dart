import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cognitive_gym/models/rank_model.dart';
import 'package:cognitive_gym/routes/app_router.dart';
import 'package:cognitive_gym/screens/games_screen.dart';
import 'package:cognitive_gym/screens/home_screen.dart';
import 'package:cognitive_gym/screens/login_screen.dart';
import 'package:cognitive_gym/services/auth_service.dart';
import 'package:cognitive_gym/services/database_service.dart';
import 'package:cognitive_gym/services/progress_service.dart';
import 'package:cognitive_gym/services/theme_service.dart';
import 'package:cognitive_gym/utils/app_theme.dart';
import 'package:cognitive_gym/widgets/app_drawer.dart';
import 'package:cognitive_gym/widgets/raccoon_avatar.dart';
import 'package:cognitive_gym/widgets/rank_arena_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await DatabaseService.resetForTesting(dbPath: inMemoryDatabasePath);
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AuthService.instance.logout();
    AppRouter.bypassAuthForTesting = false;
  });

  tearDownAll(() async {
    await DatabaseService.resetForTesting();
  });

  group('AppBar UI Modifications', () {
    testWidgets('Raccoon icon is in leading (top-left) with size 40', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const HomeScreen()),
      );
      await tester.pumpAndSettle();

      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);
      final appBar = tester.widget<AppBar>(appBarFinder);

      // Verify RaccoonAvatar is in leading
      expect(appBar.leading, isNotNull);
      final raccoonFinder = find.descendant(
        of: find.byWidget(appBar.leading!),
        matching: find.byType(RaccoonAvatar),
      );
      expect(raccoonFinder, findsOneWidget);

      final raccoonWidget = tester.widget<RaccoonAvatar>(raccoonFinder);
      expect(raccoonWidget.size, 40.0);

      // Verify Raccoon avatar is NOT in actions (top-right)
      if (appBar.actions != null) {
        for (final action in appBar.actions!) {
          expect(
            find.descendant(
              of: find.byWidget(action),
              matching: find.byType(RaccoonAvatar),
            ),
            findsNothing,
          );
        }
      }
    });

    testWidgets('Title Cognitive Gym has increased font size', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const HomeScreen()),
      );
      await tester.pumpAndSettle();

      final titleFinder = find.text('Cognitive Gym');
      expect(titleFinder, findsOneWidget);
      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.style?.fontSize, 22.0);
    });

    testWidgets('Adaptive Training icon is completely removed from AppBar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.darkTheme, home: const HomeScreen()),
      );
      await tester.pumpAndSettle();

      // Find AppBar
      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);

      // Verify no Adaptive training tooltip or psychology icon in the AppBar
      final adaptiveTooltipFinder = find.descendant(
        of: appBarFinder,
        matching: find.byTooltip('Adaptive training'),
      );
      expect(adaptiveTooltipFinder, findsNothing);

      final psychologyIconFinder = find.descendant(
        of: appBarFinder,
        matching: find.byIcon(Icons.psychology_outlined),
      );
      expect(psychologyIconFinder, findsNothing);
    });
  });

  group('Bottom Navigation UI Modifications', () {
    testWidgets(
      'Bottom navigation contains no About tab and retains Home, Account, Journal',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          await AuthService.instance.signUp(
            fullName: 'Test User',
            username: 'testuser',
            email: 'test@cognitivegym.app',
            password: 'password123',
          );
          await AuthService.instance.login(
            emailOrUsername: 'testuser',
            password: 'password123',
          );
        });

        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp.router(
            theme: AppTheme.darkTheme,
            routerConfig: AppRouter.router,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Find NavigationBar
        final navBarFinder = find.byType(NavigationBar);
        expect(navBarFinder, findsOneWidget);
        final navBar = tester.widget<NavigationBar>(navBarFinder);

        // Verify exactly 5 destinations in the mandatory order: Dashboard -> Games -> Achievements -> Journal -> Account
        expect(navBar.destinations.length, 5);

        // Verify About is NOT in NavigationBar
        final aboutInNav = find.descendant(
          of: navBarFinder,
          matching: find.text('About'),
        );
        expect(aboutInNav, findsNothing);

        // Verify Dashboard, Games, Achievements, Journal, Account destinations in exact order
        final dest0 = navBar.destinations[0] as NavigationDestination;
        final dest1 = navBar.destinations[1] as NavigationDestination;
        final dest2 = navBar.destinations[2] as NavigationDestination;
        final dest3 = navBar.destinations[3] as NavigationDestination;
        final dest4 = navBar.destinations[4] as NavigationDestination;

        expect(dest0.label, equals('Dashboard'));
        expect(dest1.label, equals('Games'));
        expect(dest2.label, equals('Achievements'));
        expect(dest3.label, equals('Journal'));
        expect(dest4.label, equals('Account'));

        expect(
          find.descendant(of: navBarFinder, matching: find.text('Dashboard')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Games')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: navBarFinder,
            matching: find.text('Achievements'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Journal')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: navBarFinder, matching: find.text('Account')),
          findsOneWidget,
        );
      },
    );
  });

  group('New Requirements Verification', () {
    testWidgets(
      '1. Restored Login Screen: Unauthenticated app launch opens LoginScreen directly',
      (WidgetTester tester) async {
        // Ensure user is logged out
        await AuthService.instance.logout();
        expect(AuthService.instance.isLoggedIn, isFalse);
        AppRouter.bypassAuthForTesting = false;

        await tester.pumpWidget(
          MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: AppRouter.router,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Should be directly on LoginScreen
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(
          find.text('Enter your credentials to continue your training'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '2. Default Theme: ThemeService defaults to Light Theme on launch',
      (WidgetTester tester) async {
        SharedPreferences.setMockInitialValues({});
        await ThemeService.instance.init();

        expect(ThemeService.instance.currentTheme, AppThemeMode.light);
        final themeData = AppTheme.getThemeData(
          ThemeService.instance.currentTheme,
        );
        expect(themeData.brightness, Brightness.light);
      },
    );

    testWidgets(
      '3. Cognitive Analytics Navigation: Has Home/Back button and no drawer icon',
      (WidgetTester tester) async {
        AppRouter.bypassAuthForTesting = true;
        addTearDown(() {
          AppRouter.bypassAuthForTesting = false;
        });

        await tester.pumpWidget(
          MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: AppRouter.router,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Navigate to Analytics page
        AppRouter.router.go(AppRouter.analyticsRoute);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Find AppBar on AnalyticsScreen
        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);
        final appBar = tester.widget<AppBar>(appBarFinder);

        // Verify leading widget exists and is a back/home button
        expect(appBar.leading, isNotNull);
        final backButtonFinder = find.descendant(
          of: find.byWidget(appBar.leading!),
          matching: find.byIcon(Icons.arrow_back),
        );
        expect(backButtonFinder, findsOneWidget);

        // Verify no drawer on AnalyticsScreen
        expect(find.byType(Drawer), findsNothing);

        // Tap the back button and verify it navigates back to Homepage
        await tester.tap(backButtonFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Cognitive Gym'), findsOneWidget);
        expect(find.text('Dashboard'), findsOneWidget);

        // Drain sqflite lock-check timer
        await tester.pump(const Duration(seconds: 11));
      },
    );

    testWidgets(
      '4. Homepage Information Row: First telemetry row is completely removed',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const HomeScreen()),
        );
        await tester.pumpAndSettle();

        // Verify "System ready" indicator row is completely gone from the top of the homepage
        expect(find.text('System ready'), findsNothing);
        expect(find.textContaining('day streak'), findsNothing);
      },
    );

    testWidgets(
      '5. Homepage Restructure: Cognitive Rank Arena appears at the top above Daily Challenges',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const HomeScreen()),
        );
        await tester.pumpAndSettle();

        final rankArenaFinder = find.byType(RankArenaCard);
        expect(rankArenaFinder, findsOneWidget);

        final dailyChallengesFinder = find.text('Daily challenges');
        expect(dailyChallengesFinder, findsOneWidget);

        // Verify vertical ordering: RankArenaCard must be positioned ABOVE Daily challenges
        final rankArenaTop = tester.getTopLeft(rankArenaFinder).dy;
        final dailyChallengesTop = tester.getTopLeft(dailyChallengesFinder).dy;

        expect(rankArenaTop, lessThan(dailyChallengesTop));

        // Verify category filter is below daily challenges
        final allCategoryFinder = find.text('All');
        expect(allCategoryFinder, findsOneWidget);
        final allCategoryTop = tester.getTopLeft(allCategoryFinder).dy;

        expect(dailyChallengesTop, lessThan(allCategoryTop));
      },
    );

    testWidgets(
      '6. Cognitive Rank Arena maintains functionality and dynamic state updates',
      (WidgetTester tester) async {
        final initialUser = ProgressService.instance.userProfile;
        expect(initialUser, isNotNull);

        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const HomeScreen()),
        );
        await tester.pumpAndSettle();

        // Find RankArenaCard
        final rankCard = tester.widget<RankArenaCard>(
          find.byType(RankArenaCard),
        );
        expect(rankCard.user.totalXp, initialUser.totalXp);
        expect(rankCard.user.level, initialUser.level);

        // Verify rank title is displayed
        final rank = CognitiveRank.getRankForProfile(initialUser);
        expect(find.text(rank.title.toUpperCase()), findsOneWidget);

        // Award XP via ProgressService and verify reactive update
        await ProgressService.instance.recordCustomExerciseReward(xp: 100);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        final updatedCard = tester.widget<RankArenaCard>(
          find.byType(RankArenaCard),
        );
        expect(updatedCard.user.totalXp, initialUser.totalXp + 100);
      },
    );

    testWidgets("7. Homepage: Today's top pick section is completely removed", (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text("Today's top pick"), findsNothing);
      expect(find.text("Adaptive engine recommendation"), findsNothing);
    });

    testWidgets("8. Homepage: Daily Quest section is completely removed", (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text("Daily quest"), findsNothing);
      expect(find.text("Daily training quests"), findsNothing);
    });

    testWidgets(
      "9. Homepage: Cognitive Arena heading is integrated inside RankArenaCard",
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const HomeScreen()),
        );
        await tester.pumpAndSettle();

        final rankCardFinder = find.byType(RankArenaCard);
        expect(rankCardFinder, findsOneWidget);

        final titleInsideCardFinder = find.descendant(
          of: rankCardFinder,
          matching: find.text('Cognitive Arena'),
        );
        expect(titleInsideCardFinder, findsOneWidget);

        final brainEmojiFinder = find.descendant(
          of: rankCardFinder,
          matching: find.text('🧠'),
        );
        expect(brainEmojiFinder, findsOneWidget);
      },
    );

    testWidgets(
      "10. Games Page: Renders game library without introductory container or Adaptive Training",
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const GamesScreen()),
        );
        await tester.pumpAndSettle();

        // Introductory Games container is completely removed
        expect(
          find.text('Challenge your mind. Strengthen your thinking.'),
          findsNothing,
        );

        // Adaptive Training card is completely removed
        expect(find.text('Adaptive Training'), findsNothing);

        // Category chips
        expect(find.text('All'), findsOneWidget);
        expect(find.text('Observation'), findsWidgets);
        expect(find.text('Decision'), findsWidgets);
        expect(find.text('Creativity'), findsWidgets);
        expect(find.text('Logic'), findsWidgets);

        // Core game cards
        expect(find.text('Observation Challenge'), findsOneWidget);
        expect(find.text('Scenario Lab'), findsOneWidget);
        expect(find.text('Story Builder'), findsOneWidget);
        expect(find.text('Sequence Master'), findsOneWidget);
        expect(find.text('Debate Arena'), findsOneWidget);
      },
    );

    testWidgets(
      "11. Drawer: Adaptive Training is completely removed from navigation",
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(drawer: AppDrawer()),
          ),
        );
        await tester.pumpAndSettle();

        // Open drawer
        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold),
        );
        scaffoldState.openDrawer();
        await tester.pumpAndSettle();

        expect(find.text('Adaptive training'), findsNothing);
      },
    );
  });
}
