import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:cognitive_gym/models/animal_avatar.dart';
import 'package:cognitive_gym/models/user_account.dart';
import 'package:cognitive_gym/routes/app_router.dart';
import 'package:cognitive_gym/screens/achievements_screen.dart';
import 'package:cognitive_gym/screens/login_screen.dart';
import 'package:cognitive_gym/screens/sign_up_screen.dart';
import 'package:cognitive_gym/services/auth_service.dart';
import 'package:cognitive_gym/services/database_service.dart';
import 'package:cognitive_gym/services/progress_service.dart';
import 'package:cognitive_gym/services/sound_service.dart';
import 'package:cognitive_gym/utils/app_theme.dart';
import 'package:cognitive_gym/widgets/animal_avatar_painters.dart';
import 'package:cognitive_gym/widgets/avatar_selector.dart';
import 'package:cognitive_gym/widgets/raccoon_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await DatabaseService.resetForTesting(dbPath: inMemoryDatabasePath);
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global/events'),
      (MethodCall methodCall) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers/events'),
      (MethodCall methodCall) async => null,
    );
    SharedPreferences.setMockInitialValues({});
    SoundService.instance.isSoundEnabled = false;
    await DatabaseService.resetForTesting(dbPath: inMemoryDatabasePath);
    AppRouter.bypassAuthForTesting = false;
  });

  tearDown(() async {
    await AuthService.instance.logout();
    AppRouter.bypassAuthForTesting = false;
  });

  tearDownAll(() async {
    await DatabaseService.resetForTesting();
  });

  group('Part 1: Restored Login Screen & Auth Routing Guard', () {
    testWidgets('Unauthenticated app launch opens LoginScreen directly', (WidgetTester tester) async {
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

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Enter your credentials to continue your training'), findsOneWidget);
    });

    test('AppRouter redirect redirects unauthenticated access to login and allows home for logged in', () async {
      await AuthService.instance.logout();
      expect(AuthService.instance.isLoggedIn, isFalse);
      AppRouter.bypassAuthForTesting = false;

      // Unauthenticated home -> /login
      expect(AppRouter.getRedirectForLocation(AppRouter.homeRoute), equals(AppRouter.loginRoute));
      // Unauthenticated login -> null (allowed)
      expect(AppRouter.getRedirectForLocation(AppRouter.loginRoute), isNull);
      // Unauthenticated signup -> null (allowed)
      expect(AppRouter.getRedirectForLocation(AppRouter.signUpRoute), isNull);

      // Authenticate
      AuthService.instance.setCurrentUserForTesting(
        const UserAccount(
          id: 'u1',
          fullName: 'Test User',
          username: 'testuser',
          email: 'test@example.com',
          password: 'pw',
          createdAt: '2026-01-01',
        ),
      );
      expect(AuthService.instance.isLoggedIn, isTrue);

      // Authenticated home -> null (allowed)
      expect(AppRouter.getRedirectForLocation(AppRouter.homeRoute), isNull);
      // Authenticated login -> / (redirect to home)
      expect(AppRouter.getRedirectForLocation(AppRouter.loginRoute), equals(AppRouter.homeRoute));
    });
  });

  group('Part 2: 7 Animal Avatars & Registry', () {
    test('AppAvatars registry defines all 7 required animal avatars in exact order', () {
      expect(AppAvatars.all.length, equals(7));
      expect(AppAvatars.all.map((a) => a.id).toList(), equals([
        'elephant',
        'tiger',
        'lion',
        'raccoon',
        'rabbit',
        'bear',
        'cat',
      ]));
      expect(AppAvatars.defaultAvatarId, equals('raccoon'));
    });

    test('AppAvatars.normalize safely handles null, empty, legacy paths, and case-insensitivity', () {
      expect(AppAvatars.normalize(null), equals('raccoon'));
      expect(AppAvatars.normalize(''), equals('raccoon'));
      expect(AppAvatars.normalize('   '), equals('raccoon'));
      expect(AppAvatars.normalize('assets/images/raccoon_avatar.png'), equals('raccoon'));
      expect(AppAvatars.normalize('TIGER'), equals('tiger'));
      expect(AppAvatars.normalize('Elephant'), equals('elephant'));
      expect(AppAvatars.normalize('unknown_avatar'), equals('raccoon'));
    });

    test('AnimalAvatarPainter provides CustomPainter for all 7 avatars', () {
      for (final avatar in AppAvatars.all) {
        final painter = AnimalAvatarPainter.forId(avatar.id);
        expect(painter, isNotNull);
      }
    });

    testWidgets('CustomPainters for all 7 animals paint cleanly without exceptions', (WidgetTester tester) async {
      for (final avatar in AppAvatars.all) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: const Size(100, 100),
                painter: AnimalAvatarPainter.forId(avatar.id),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull, reason: '${avatar.name} painter should paint without throwing');
      }
    });
  });

  group('Part 3: Interactive AvatarSelector Widget', () {
    testWidgets('AvatarSelector displays all 7 avatars in a single unified carousel with directional arrows',
        (WidgetTester tester) async {
      String selected = 'raccoon';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (ctx, setState) {
                return AvatarSelector(
                  selectedAvatarId: selected,
                  onAvatarSelected: (newId) {
                    setState(() {
                      selected = newId;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify all 7 animal names appear
      for (final avatar in AppAvatars.all) {
        expect(find.text(avatar.name), findsOneWidget);
      }

      // Verify Left and Right chevron arrows exist
      final leftArrow = find.byKey(const ValueKey('avatar_carousel_arrow_left'));
      final rightArrow = find.byKey(const ValueKey('avatar_carousel_arrow_right'));
      expect(leftArrow, findsOneWidget);
      expect(rightArrow, findsOneWidget);

      // Tap on 'Tiger'
      await tester.tap(find.text('Tiger'));
      await tester.pumpAndSettle();

      expect(selected, equals('tiger'));
    });

    testWidgets('AvatarSelector renders smoothly in Dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AvatarSelector(
              selectedAvatarId: 'lion',
              onAvatarSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lion'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Part 4: Avatar Selection ONLY on SignUp Screen & Clean Login Screen', () {
    testWidgets('LoginScreen focuses solely on authentication without AvatarSelector',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Avatar selection must be completely absent from LoginScreen
      expect(find.byType(AvatarSelector), findsNothing);
      expect(find.text('CHOOSE YOUR AVATAR'), findsNothing);

      // Brand icon and credentials form are cleanly displayed
      expect(find.byIcon(Icons.psychology_outlined), findsOneWidget);
      expect(find.text('Cognitive Gym'), findsOneWidget);
      expect(find.text('Enter your credentials to continue your training'), findsOneWidget);
      expect(find.byKey(const Key('login_identifier_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
    });

    testWidgets('SignUpScreen includes unified AvatarSelector with directional arrows and allows selecting avatars',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 1600);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SignUpScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AvatarSelector), findsOneWidget);
      expect(find.text('CHOOSE YOUR AVATAR'), findsOneWidget);

      // Verify each animal name appears in the single selector (no duplicate previews)
      for (final avatar in AppAvatars.all) {
        expect(find.text(avatar.name), findsOneWidget);
      }

      // Directional arrow buttons exist
      expect(find.byKey(const ValueKey('avatar_carousel_arrow_left')), findsOneWidget);
      expect(find.byKey(const ValueKey('avatar_carousel_arrow_right')), findsOneWidget);

      // Default selection is Raccoon
      expect(find.text('Raccoon'), findsOneWidget);

      // Select 'Elephant' from carousel
      await tester.tap(find.text('Elephant'));
      await tester.pumpAndSettle();

      // Form inputs and submit button are present and responsive
      expect(find.byKey(const Key('signup_fullname_field')), findsOneWidget);
      expect(find.byKey(const Key('signup_username_field')), findsOneWidget);
      expect(find.byKey(const Key('signup_email_field')), findsOneWidget);
      expect(find.byKey(const Key('signup_password_field')), findsOneWidget);
      expect(find.byKey(const Key('signup_confirm_password_field')), findsOneWidget);
      expect(find.byKey(const Key('signup_submit_button')), findsOneWidget);
    });
  });

  group('Part 5: Persistence Across Session and Components', () {
    test('New user sign up with Bear avatar persists in SQLite and restores on login', () async {
      // 1. Sign Up with Bear
      final signUpRes = await AuthService.instance.signUp(
        fullName: 'Bear Explorer',
        username: 'bearexplorer',
        email: 'bear@example.com',
        password: 'Password123!',
        avatarId: 'bear',
      );
      expect(signUpRes.isSuccess, isTrue);
      expect(signUpRes.user!.avatarId, equals('bear'));
      expect(ProgressService.instance.userProfile.avatarId, equals('bear'));

      // 2. Logout
      await AuthService.instance.logout();
      expect(AuthService.instance.isLoggedIn, isFalse);

      // 3. Login
      final loginRes = await AuthService.instance.login(
        emailOrUsername: 'bearexplorer',
        password: 'Password123!',
      );
      expect(loginRes.isSuccess, isTrue);
      expect(loginRes.user!.avatarId, equals('bear'));
      expect(ProgressService.instance.userProfile.avatarId, equals('bear'));

      // 4. Update Profile to Cat
      final updateRes = await AuthService.instance.updateProfile(profileImage: 'cat');
      expect(updateRes.isSuccess, isTrue);
      expect(updateRes.user!.avatarId, equals('cat'));
      expect(ProgressService.instance.userProfile.avatarId, equals('cat'));
    });

    test('Default avatar is Raccoon if none is provided on registration', () async {
      final res = await AuthService.instance.signUp(
        fullName: 'Default User',
        username: 'defaultuser',
        email: 'default@example.com',
        password: 'Password123!',
      );
      expect(res.isSuccess, isTrue);
      expect(res.user!.avatarId, equals('raccoon'));
      expect(ProgressService.instance.userProfile.avatarId, equals('raccoon'));
    });

    testWidgets('RaccoonAvatar widget renders with given avatarId', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RaccoonAvatar(
              size: 48,
              avatarId: 'rabbit',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RaccoonAvatar), findsOneWidget);
      final widget = tester.widget<RaccoonAvatar>(find.byType(RaccoonAvatar));
      expect(widget.avatarId, equals('rabbit'));
    });
  });

  group('Part 6: Bottom Navigation with Direct Access to Achievements', () {
    testWidgets('Bottom navigation includes Dashboard, Achievements, Journal, Account in exact sequence',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        await AuthService.instance.signUp(
          fullName: 'Nav User',
          username: 'navuser',
          email: 'navuser@cognitivegym.app',
          password: 'password123',
        );
        await AuthService.instance.login(
          emailOrUsername: 'navuser',
          password: 'password123',
        );
      });

      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final navBarFinder = find.byType(NavigationBar);
      expect(navBarFinder, findsOneWidget);
      final navBar = tester.widget<NavigationBar>(navBarFinder);

      expect(navBar.destinations.length, 4);

      final dest0 = navBar.destinations[0] as NavigationDestination;
      final dest1 = navBar.destinations[1] as NavigationDestination;
      final dest2 = navBar.destinations[2] as NavigationDestination;
      final dest3 = navBar.destinations[3] as NavigationDestination;

      expect(dest0.label, equals('Dashboard'));
      expect(dest1.label, equals('Achievements'));
      expect(dest2.label, equals('Journal'));
      expect(dest3.label, equals('Account'));

      // Tap on Achievements tab (index 1)
      await tester.tap(find.descendant(of: navBarFinder, matching: find.text('Achievements')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AchievementsScreen), findsOneWidget);
    });
  });
}
