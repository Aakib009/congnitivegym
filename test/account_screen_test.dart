import 'package:cognitive_gym/screens/account_screen.dart';
import 'package:cognitive_gym/services/auth_service.dart';
import 'package:cognitive_gym/services/database_service.dart';
import 'package:cognitive_gym/services/progress_service.dart';
import 'package:cognitive_gym/services/reward_manager.dart';
import 'package:cognitive_gym/utils/app_theme.dart';
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

  group('AccountScreen Widget Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await DatabaseService.instance.close();
      await AuthService.instance.initialize();
      await ProgressService.instance.init();
      await ProgressService.instance.resetProgress();
      await RewardManager.instance.init();
    });

    tearDown(() async {
      await DatabaseService.instance.close();
    });

    testWidgets(
        'Renders AccountScreen with header, points card, stats, and settings',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AccountScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Account Profile'), findsOneWidget);
      expect(find.text('Alex Mindful'), findsWidgets);
      expect(find.textContaining('alex.mindful@cognitivegym.app'), findsWidgets);
      expect(find.text('Edit Profile'), findsWidgets);

      // Verify Points Section & Mind Tree Stage
      expect(find.text('Cognitive Stats & Points'), findsOneWidget);
      expect(find.text('TOTAL POINTS'), findsOneWidget);
      expect(find.text('0 XP'), findsOneWidget);

      // Verify Learning Stats Grid
      expect(find.text('Creativity Points'), findsOneWidget);
      expect(find.text('Observation Points'), findsOneWidget);
      expect(find.text('Logic Points'), findsOneWidget);
      expect(find.text('Current Streak'), findsOneWidget);
      expect(find.text('Best Streak'), findsOneWidget);
      expect(find.text('Achievements'), findsWidgets);

      // Verify Dedicated Achievement Showcase Card
      expect(find.text('Track your milestones and accomplishments'), findsWidgets);
      expect(find.text('Explore Achievements'), findsOneWidget);
      expect(find.textContaining('Unlocked'), findsWidgets);

      // Verify Account Information Section
      expect(find.text('Account Information'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);

      // Verify Settings Actions
      expect(find.text('Settings & Actions'), findsOneWidget);
      expect(find.text('About Cognitive Gym'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
    });

    testWidgets(
        'Reactively updates points and level when RewardManager awards points',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AccountScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0 XP'), findsOneWidget);

      // Award points via RewardManager
      await RewardManager.instance.awardLesson(
        lessonId: 'test_lesson_1',
        isPerfect: true,
      );
      await tester.pumpAndSettle();

      expect(find.text('0 XP'), findsNothing);
    });
  });
}
