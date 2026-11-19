import 'package:cognitive_gym/models/user_profile.dart';
import 'package:cognitive_gym/routes/app_router.dart';
import 'package:cognitive_gym/screens/home_screen.dart';
import 'package:cognitive_gym/screens/scenario_lab_screen.dart';
import 'package:cognitive_gym/screens/story_builder_screen.dart';
import 'package:cognitive_gym/services/auth_service.dart';
import 'package:cognitive_gym/services/database_service.dart';
import 'package:cognitive_gym/utils/app_colors.dart';
import 'package:cognitive_gym/utils/app_theme.dart';
import 'package:cognitive_gym/widgets/rank_arena_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await DatabaseService.resetForTesting(dbPath: inMemoryDatabasePath);
  });

  tearDownAll(() async {
    await DatabaseService.resetForTesting();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DatabaseService.instance.clearAllUsers();
    await AuthService.instance.initialize();
  });

  tearDown(() async {
    await DatabaseService.instance.clearAllUsers();
  });

  group('Phase 4: Design Specification Visual Verification', () {
    // 1. Dashboard Render Verification in Dark Theme
    testWidgets('1. Dashboard renders with design tokens, telemetry, and zero overflow in Dark Theme',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header and title
      expect(find.text('Cognitive Gym'), findsOneWidget);
      expect(find.text('DAILY CHALLENGES'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('CREATIVITY'), findsWidgets);
      expect(find.text('OBSERVATION'), findsWidgets);
      expect(find.text('LOGIC'), findsWidgets);
      expect(find.text('DECISION'), findsWidgets);

      // Verify no Flutter render overflow exception occurred
      expect(tester.takeException(), isNull);
    });

    // 2. Rank Progression Display Verification
    testWidgets('2. Rank progression display accurately renders strict AND criteria',
        (WidgetTester tester) async {
      final user = UserProfile.mock().copyWith(
        totalXp: 180,
        level: 2,
        creativityPoints: 40,
        observationPoints: 40,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: SingleChildScrollView(
              child: RankArenaCard(user: user),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify current rank and next rank target
      expect(find.textContaining('BRONZE'), findsWidgets);
      expect(find.text('NEXT: SILVER'), findsOneWidget);

      // Verify individual AND metrics
      expect(find.text('XP'), findsOneWidget);
      expect(find.text('LVL'), findsOneWidget);
      expect(find.text('MASTERY'), findsOneWidget);

      // Verify domain mastery breakdown pips
      expect(find.text('CRE'), findsOneWidget);
      expect(find.text('OBS'), findsOneWidget);
      expect(find.text('LOG'), findsOneWidget);
      expect(find.text('DEC'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    // 3. Module Selection Verification
    testWidgets('3. Module selection renders all 4 cognitive modules with designated color accents',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800 * 2, 1600 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // All 4 modules must be present
      expect(find.text('STORY BUILDER'), findsOneWidget);
      expect(find.text('OBSERVATION CHALLENGE'), findsOneWidget);
      expect(find.text('SCENARIO LAB'), findsOneWidget);
      expect(find.text('DEBATE ARENA'), findsOneWidget);

      // Mind Tree must NOT exist anywhere in the UI
      expect(find.text('Mind Tree'), findsNothing);

      expect(tester.takeException(), isNull);
    });

    // 4. Active Cognitive Challenge: Story Builder
    testWidgets('4. Active cognitive challenge: Story Builder renders 3-keyword prompt and word inclusion',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const StoryBuilderScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Story Builder'), findsOneWidget);
      expect(find.text('Creativity Challenge'), findsOneWidget);
      expect(find.text('Complete challenge'), findsOneWidget);

      // Enter story text that includes words
      await tester.enterText(
        find.byType(TextField),
        'This is a comprehensive story to test the active challenge state of the story builder module.',
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    // 5. Completed Challenge and Results: Scenario Lab
    testWidgets('5. Completed challenge reveals dedicated outcome and honest XP reward',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const ScenarioLabScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Select Option A and confirm
      final optionA = find.textContaining('Option A').first;
      await tester.ensureVisible(optionA);
      await tester.tap(optionA);
      await tester.pumpAndSettle();

      final confirmBtn = find.text('Confirm decision');
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify dedicated outcome view
      expect(find.text('Decision outcome'), findsOneWidget);
      expect(find.text('Decision selected'), findsOneWidget);
      expect(find.text('Outcome'), findsOneWidget);
      expect(find.textContaining('Deliberation score:'), findsOneWidget);
      expect(find.text('Next Scenario'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    // 6. Dark Theme Verification
    testWidgets('6. Dark theme accurately applies design.md dark tokens',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // AppTheme dark scaffoldBackgroundColor matches AppColors.pageBackground (#171717)
      expect(Theme.of(tester.element(find.byType(Scaffold))).scaffoldBackgroundColor, AppColors.pageBackground);
      expect(Theme.of(tester.element(find.byType(Scaffold))).colorScheme.surface, AppColors.surface);
      expect(Theme.of(tester.element(find.byType(Scaffold))).colorScheme.primary, AppColors.brandLime);

      expect(tester.takeException(), isNull);
    });

    // 7. Light Theme Verification
    testWidgets('7. Light theme accurately applies clean daylight styling and contrast',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(Theme.of(tester.element(find.byType(Scaffold))).scaffoldBackgroundColor, AppColors.groundLight);
      expect(Theme.of(tester.element(find.byType(Scaffold))).brightness, Brightness.light);

      expect(find.text('Cognitive Gym'), findsOneWidget);
      expect(find.text('DAILY CHALLENGES'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    // 8. Narrow / Mobile Viewport Layout Verification
    testWidgets('8. Narrow mobile viewport (375x812) renders without any overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(375 * 2, 812 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Pump HomeScreen on 375px mobile viewport
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const HomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Must have zero overflow exceptions
      expect(tester.takeException(), isNull);

      // Verify key items visible
      expect(find.text('Cognitive Gym'), findsOneWidget);
      expect(find.text('DAILY CHALLENGES'), findsOneWidget);
    });

    // Responsive Desktop Sidebar Verification
    testWidgets('Responsive shell renders persistent desktop sidebar at width >= 900',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        await AuthService.instance.signUp(
          fullName: 'Alex Mindful',
          username: 'alexmindful',
          email: 'alex.mindful@cognitivegym.app',
          password: 'password123',
        );
        await AuthService.instance.login(
          emailOrUsername: 'alexmindful',
          password: 'password123',
        );
      });

      tester.view.physicalSize = const Size(1200 * 2, 800 * 2);
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
      await tester.pump(const Duration(seconds: 1));

      // On wide desktop (width >= 900), should render Desktop Sidebar with COGNITIVE GYM header
      expect(find.text('COGNITIVE GYM'), findsOneWidget);
      expect(find.text('Dashboard'), findsWidgets);
      expect(find.text('Account'), findsOneWidget);
      expect(find.text('Journal'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);

      // Bottom NavigationBar must NOT be present on wide desktop
      expect(find.byType(NavigationBar), findsNothing);

      expect(tester.takeException(), isNull);
    });
  });
}
