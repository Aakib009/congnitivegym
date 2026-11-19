import 'package:cognitive_gym/routes/app_router.dart';
import 'package:cognitive_gym/screens/story_builder_screen.dart';
import 'package:cognitive_gym/screens/observation_challenge_screen.dart';
import 'package:cognitive_gym/screens/scenario_lab_screen.dart';
import 'package:cognitive_gym/services/auth_service.dart';
import 'package:cognitive_gym/services/database_service.dart';
import 'package:cognitive_gym/utils/app_theme.dart';
import 'package:cognitive_gym/widgets/app_drawer.dart';
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

  group('Navigation Drawer Tests', () {
    testWidgets('AppDrawer renders user profile and all cognitive modules',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: AppDrawer(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify user profile header
      expect(find.text('Alex Mindful'), findsOneWidget);
      expect(find.textContaining('Level 7'), findsOneWidget);

      // Verify cognitive module items
      expect(find.text('Story builder'), findsOneWidget);
      expect(find.text('Observation challenge'), findsOneWidget);
      expect(find.text('Scenario lab'), findsOneWidget);
      expect(find.text('Debate arena'), findsOneWidget);
      expect(find.text('Mind Tree'), findsNothing);
      expect(find.text('Active'), findsNothing);
      expect(find.text('Coming Soon'), findsNothing);

      // Verify restricted 2-theme switcher
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Violet'), findsNothing);
      expect(find.text('Forest'), findsNothing);
    });
  });

  group('Module Placeholder Screen Tests', () {
    testWidgets('ObservationChallengeScreen renders active challenge screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ObservationChallengeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Challenge rules'), findsOneWidget);
      expect(find.textContaining('Start observation'), findsOneWidget);
    });

    testWidgets('ScenarioLabScreen renders active scenario screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ScenarioLabScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Scenario Lab'), findsOneWidget);
      expect(find.text('Confirm decision'), findsOneWidget);
    });

    testWidgets('StoryBuilderScreen renders active story builder screen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const StoryBuilderScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Write story'), findsOneWidget);
    });
  });

  group('AccountScreen Tab Tests', () {
    testWidgets('Account tab navigation renders Account Profile',
        (WidgetTester tester) async {
      // Seed a user in SQLite and log in so GoRouter redirects to Home Screen
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

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Navigate to Account tab via bottom NavigationBar
      await tester.tap(find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Account'),
      ));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Account Profile'), findsWidgets);
      expect(find.text('Alex Mindful'), findsWidgets);
      expect(find.text('Cognitive Stats & Points'), findsOneWidget);
      expect(find.text('TOTAL POINTS'), findsOneWidget);
    });


  });
}
