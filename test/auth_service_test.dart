import 'package:cognitive_gym/models/user_account.dart';
import 'package:cognitive_gym/routes/app_router.dart';
import 'package:cognitive_gym/screens/login_screen.dart';
import 'package:cognitive_gym/screens/sign_up_screen.dart';
import 'package:cognitive_gym/services/achievement_service.dart';
import 'package:cognitive_gym/services/analytics_service.dart';
import 'package:cognitive_gym/services/auth_service.dart';
import 'package:cognitive_gym/services/database_service.dart';
import 'package:cognitive_gym/services/progress_service.dart';
import 'package:cognitive_gym/services/streak_service.dart';
import 'package:cognitive_gym/utils/app_theme.dart';
import 'package:cognitive_gym/utils/password_security.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
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
    await DatabaseService.instance.clearAllAnalyticsEvents();
    await AuthService.instance.logout();
    await AuthService.instance.initialize();
  });

  tearDown(() async {
    await DatabaseService.instance.clearAllUsers();
    await DatabaseService.instance.clearAllAnalyticsEvents();
    await AuthService.instance.logout();
  });

  group('Phase 2 — Sign-Up & Validation Tests', () {
    test('Valid signup creates account, hashes password, authenticates user, and initializes profile', () async {
      final res = await AuthService.instance.signUp(
        fullName: 'Alex Mindful',
        username: 'alexmindful',
        email: 'alex@cognitivegym.app',
        password: 'securePassword123',
      );

      expect(res.isSuccess, isTrue);
      expect(res.user, isNotNull);
      expect(res.user!.username, equals('alexmindful'));
      expect(res.user!.email, equals('alex@cognitivegym.app'));
      // Verify password is not plaintext
      expect(res.user!.password, isNot(equals('securePassword123')));
      expect(res.user!.password.startsWith('pbkdf2_sha256\$'), isTrue);

      // Verify user is authenticated immediately
      expect(AuthService.instance.isLoggedIn, isTrue);
      expect(AuthService.instance.currentUser?.id, equals(res.user!.id));

      // Verify clean initial user profile (not the old mock level 7)
      final profile = ProgressService.instance.userProfile;
      expect(profile.id, equals(res.user!.id));
      expect(profile.level, equals(1));
      expect(profile.totalXp, equals(0));
      expect(profile.totalExercisesCompleted, equals(0));
    });

    test('Invalid signup rejects empty fields, invalid characters, weak passwords, and duplicates', () async {
      // 1. Empty fields
      final emptyRes = await AuthService.instance.signUp(
        fullName: '',
        username: '',
        email: '',
        password: '',
      );
      expect(emptyRes.isSuccess, isFalse);
      expect(emptyRes.errorMessage, contains('All fields are required'));

      // 2. Short full name
      final shortNameRes = await AuthService.instance.signUp(
        fullName: 'A',
        username: 'validuser',
        email: 'user@test.com',
        password: 'password123',
      );
      expect(shortNameRes.isSuccess, isFalse);
      expect(shortNameRes.errorMessage, contains('Full name must be at least 2 characters'));

      // 3. Short username
      final shortUserRes = await AuthService.instance.signUp(
        fullName: 'Valid Name',
        username: 'ab',
        email: 'user@test.com',
        password: 'password123',
      );
      expect(shortUserRes.isSuccess, isFalse);
      expect(shortUserRes.errorMessage, contains('Username must be at least 3 characters'));

      // 4. Username with spaces
      final spaceUserRes = await AuthService.instance.signUp(
        fullName: 'Valid Name',
        username: 'invalid user',
        email: 'user@test.com',
        password: 'password123',
      );
      expect(spaceUserRes.isSuccess, isFalse);
      expect(spaceUserRes.errorMessage, contains('Username cannot contain spaces'));

      // 5. Invalid email format
      final badEmailRes = await AuthService.instance.signUp(
        fullName: 'Valid Name',
        username: 'validuser',
        email: 'invalid-email',
        password: 'password123',
      );
      expect(badEmailRes.isSuccess, isFalse);
      expect(badEmailRes.errorMessage, contains('valid email address'));

      // 6. Whitespace-only password
      final spacePassRes = await AuthService.instance.signUp(
        fullName: 'Valid Name',
        username: 'validuser',
        email: 'user@test.com',
        password: '      ',
      );
      expect(spacePassRes.isSuccess, isFalse);
      expect(spacePassRes.errorMessage, contains('whitespace only'));

      // 7. Short password (< 6 chars)
      final shortPassRes = await AuthService.instance.signUp(
        fullName: 'Valid Name',
        username: 'validuser',
        email: 'user@test.com',
        password: '123',
      );
      expect(shortPassRes.isSuccess, isFalse);
      expect(shortPassRes.errorMessage, contains('at least 6 characters'));

      // Create initial account
      await AuthService.instance.signUp(
        fullName: 'Existing User',
        username: 'existinguser',
        email: 'existing@cognitivegym.app',
        password: 'password123',
      );

      // 8. Duplicate username (case-insensitive)
      final dupUserRes = await AuthService.instance.signUp(
        fullName: 'Another User',
        username: 'ExistingUser',
        email: 'different@cognitivegym.app',
        password: 'password123',
      );
      expect(dupUserRes.isSuccess, isFalse);
      expect(dupUserRes.errorMessage!.toLowerCase(), contains('username'));

      // 9. Duplicate email (case-insensitive)
      final dupEmailRes = await AuthService.instance.signUp(
        fullName: 'Another User',
        username: 'differentuser',
        email: 'Existing@CognitiveGym.app',
        password: 'password123',
      );
      expect(dupEmailRes.isSuccess, isFalse);
      expect(dupEmailRes.errorMessage!.toLowerCase(), contains('email'));
    });
  });

  group('Phase 3 & Phase 4 — Login, Session Persistence & Upgrades', () {
    test('Valid login validates credentials via username and email', () async {
      await AuthService.instance.signUp(
        fullName: 'Sarah Sage',
        username: 'sarahsage',
        email: 'sarah@cognitivegym.app',
        password: 'securePassword123',
      );

      await AuthService.instance.logout();
      expect(AuthService.instance.isLoggedIn, isFalse);

      // Login via username
      final loginUser = await AuthService.instance.login(
        emailOrUsername: 'sarahsage',
        password: 'securePassword123',
      );
      expect(loginUser.isSuccess, isTrue);
      expect(AuthService.instance.isLoggedIn, isTrue);
      expect(AuthService.instance.currentUser!.fullName, equals('Sarah Sage'));

      await AuthService.instance.logout();

      // Login via email (case-insensitive)
      final loginEmail = await AuthService.instance.login(
        emailOrUsername: 'SARAH@cognitivegym.app',
        password: 'securePassword123',
      );
      expect(loginEmail.isSuccess, isTrue);
      expect(AuthService.instance.isLoggedIn, isTrue);
    });

    test('Invalid login handles wrong password, unknown accounts, and empty inputs', () async {
      await AuthService.instance.signUp(
        fullName: 'Sarah Sage',
        username: 'sarahsage',
        email: 'sarah@cognitivegym.app',
        password: 'securePassword123',
      );
      await AuthService.instance.logout();

      // Unknown account
      final unknownRes = await AuthService.instance.login(
        emailOrUsername: 'unknownuser',
        password: 'anyPassword123',
      );
      expect(unknownRes.isSuccess, isFalse);
      expect(unknownRes.errorMessage, contains('No account found'));

      // Incorrect password
      final wrongRes = await AuthService.instance.login(
        emailOrUsername: 'sarahsage',
        password: 'wrongPassword123',
      );
      expect(wrongRes.isSuccess, isFalse);
      expect(wrongRes.errorMessage, contains('Incorrect password'));

      // Empty input
      final emptyRes = await AuthService.instance.login(
        emailOrUsername: '',
        password: '',
      );
      expect(emptyRes.isSuccess, isFalse);
    });

    test('Session persists across simulated application restart', () async {
      final signupRes = await AuthService.instance.signUp(
        fullName: 'Jordan Builder',
        username: 'jordanb',
        email: 'jordan@cognitivegym.app',
        password: 'password123',
      );
      expect(signupRes.isSuccess, isTrue);

      // Simulate app restart by clearing in-memory state and re-running initialize()
      final userBefore = AuthService.instance.currentUser;
      expect(userBefore, isNotNull);

      // Create new fresh instance check: call initialize() again
      await AuthService.instance.initialize();
      expect(AuthService.instance.isLoggedIn, isTrue);
      expect(AuthService.instance.currentUser?.id, equals(signupRes.user!.id));
    });

    test('Phase 8 Security: Legacy plaintext and sha256 passwords transparently upgrade to PBKDF2 on login', () async {
      // 1. Manually insert an old legacy user with plaintext password in SQLite
      const legacyId = 'usr_legacy_001';
      const plainPassword = 'oldPlaintextPassword123';
      final legacyUser = UserAccount(
        id: legacyId,
        fullName: 'Legacy User',
        username: 'legacyuser',
        email: 'legacy@cognitivegym.app',
        password: plainPassword, // Stored directly as plaintext!
        createdAt: DateTime.now().toIso8601String(),
      );
      await DatabaseService.instance.insertUser(legacyUser);

      // Verify it is indeed plaintext
      final dbUserBefore = await DatabaseService.instance.getUserById(legacyId);
      expect(dbUserBefore!.password, equals(plainPassword));
      expect(PasswordSecurity.needsUpgrade(dbUserBefore.password), isTrue);

      // Log in with legacy plaintext credentials
      final loginRes = await AuthService.instance.login(
        emailOrUsername: 'legacyuser',
        password: plainPassword,
      );
      expect(loginRes.isSuccess, isTrue);

      // Verify the password in SQLite has been upgraded to modern PBKDF2-HMAC-SHA256
      final dbUserAfter = await DatabaseService.instance.getUserById(legacyId);
      expect(dbUserAfter!.password, isNot(equals(plainPassword)));
      expect(dbUserAfter.password.startsWith('pbkdf2_sha256\$'), isTrue);
      expect(PasswordSecurity.verifyPassword(plainPassword, dbUserAfter.password), isTrue);
      expect(PasswordSecurity.needsUpgrade(dbUserAfter.password), isFalse);

      // 2. Manually insert a legacy sha256$ user
      const sha256Id = 'usr_sha256_002';
      const sha256Pass = 'legacyShaPass123';
      final salt = PasswordSecurity.generateSalt();
      final legacyShaHash = 'sha256\$$salt\$${sha256.convert(utf8.encode('$salt:$sha256Pass'))}';
      final sha256User = UserAccount(
        id: sha256Id,
        fullName: 'SHA256 User',
        username: 'sha256user',
        email: 'sha256@cognitivegym.app',
        password: legacyShaHash,
        createdAt: DateTime.now().toIso8601String(),
      );
      await DatabaseService.instance.insertUser(sha256User);
      expect(PasswordSecurity.needsUpgrade(legacyShaHash), isTrue);

      // Log in with sha256 credentials
      final sha256Login = await AuthService.instance.login(
        emailOrUsername: 'sha256user',
        password: sha256Pass,
      );
      expect(sha256Login.isSuccess, isTrue);

      // Verify upgraded to pbkdf2_sha256$
      final dbSha256After = await DatabaseService.instance.getUserById(sha256Id);
      expect(dbSha256After!.password.startsWith('pbkdf2_sha256\$'), isTrue);
      expect(PasswordSecurity.verifyPassword(sha256Pass, dbSha256After.password), isTrue);
      expect(PasswordSecurity.needsUpgrade(dbSha256After.password), isFalse);
    });

  });

  group('Phase 5 & Phase 6 — Logout & Strict User Data Isolation', () {
    test('User A data and exercises are isolated from User B', () async {
      // 1. User A registers
      final userARes = await AuthService.instance.signUp(
        fullName: 'User Alpha',
        username: 'user_alpha',
        email: 'alpha@cognitivegym.app',
        password: 'passwordAlpha123',
      );
      expect(userARes.isSuccess, isTrue);

      // User A completes Story Builder exercise (strong performance)
      await ProgressService.instance.recordStoryBuilderCompletion(
        performanceScore: 95,
        accuracy: 100,
        durationSeconds: 120,
      );
      // XP: 15 participation + 5 excellence bonus; creativity gain at full tier = 15
      expect(ProgressService.instance.userProfile.totalXp, equals(20));
      expect(ProgressService.instance.userProfile.totalExercisesCompleted, equals(1));
      expect(ProgressService.instance.userProfile.creativityPoints, equals(15));

      // User A unlocks an achievement
      final pts = await AchievementService.instance.unlockAchievement('first_lesson');
      expect(pts, greaterThan(0));
      final achievementsA = await AchievementService.instance.getUnlockedAchievementIds();
      expect(achievementsA, contains('first_lesson'));

      // User A records a streak activity
      final streakRes = await StreakService.instance.recordDailyActivity();
      expect(streakRes.newStreak, greaterThanOrEqualTo(1));

      // 2. User A logs out
      await AuthService.instance.logout();
      expect(AuthService.instance.isLoggedIn, isFalse);
      expect(AuthService.instance.currentUser, isNull);

      // In-memory services are reset on logout
      expect(AnalyticsService.instance.analyticsData.isEmpty, isTrue);

      // 3. User B registers
      final userBRes = await AuthService.instance.signUp(
        fullName: 'User Beta',
        username: 'user_beta',
        email: 'beta@cognitivegym.app',
        password: 'passwordBeta123',
      );
      expect(userBRes.isSuccess, isTrue);

      // Verify User B does NOT see User A's progress
      final profileB = ProgressService.instance.userProfile;
      expect(profileB.id, equals(userBRes.user!.id));
      expect(profileB.totalXp, equals(0), reason: 'User B must not see User A XP');
      expect(profileB.totalExercisesCompleted, equals(0), reason: 'User B exercises must be 0');
      expect(profileB.creativityPoints, equals(0));

      // Verify User B does NOT see User A's achievements
      final achievementsB = await AchievementService.instance.getUnlockedAchievementIds();
      expect(achievementsB, isEmpty, reason: 'User B must not see User A achievements');

      // 4. User B logs out, User A logs back in
      await AuthService.instance.logout();
      await AuthService.instance.login(
        emailOrUsername: 'user_alpha',
        password: 'passwordAlpha123',
      );

      // Verify User A's progress is restored accurately
      final profileARestored = ProgressService.instance.userProfile;
      expect(profileARestored.id, equals(userARes.user!.id));
      // 95 score => 15 participation XP + 5 excellence bonus = 20 XP.
      expect(profileARestored.totalXp, equals(20));
      expect(profileARestored.totalExercisesCompleted, equals(1));
      expect(profileARestored.creativityPoints, equals(15));
    });
  });

  group('Phase 7 — Routing & Guards', () {
    setUp(() {
      AppRouter.bypassAuthForTesting = false;
    });

    tearDown(() {
      AppRouter.bypassAuthForTesting = false;
    });

    test('AppRouter.getRedirectForLocation protects routes when logged out and redirects when logged in', () async {
      // 1. Unauthenticated user accessing protected routes
      await AuthService.instance.logout();
      expect(AuthService.instance.isLoggedIn, isFalse);

      expect(
        AppRouter.getRedirectForLocation(AppRouter.homeRoute),
        equals(AppRouter.loginRoute),
        reason: 'Unauthenticated user accessing home should redirect to login',
      );
      expect(
        AppRouter.getRedirectForLocation(AppRouter.accountRoute),
        equals(AppRouter.loginRoute),
        reason: 'Unauthenticated user accessing account should redirect to login',
      );
      expect(
        AppRouter.getRedirectForLocation(AppRouter.analyticsRoute),
        equals(AppRouter.loginRoute),
        reason: 'Unauthenticated user accessing analytics should redirect to login',
      );

      // 2. Unauthenticated user accessing login or signup is allowed (no redirect)
      expect(
        AppRouter.getRedirectForLocation(AppRouter.loginRoute),
        isNull,
        reason: 'Unauthenticated user accessing login should be allowed',
      );
      expect(
        AppRouter.getRedirectForLocation(AppRouter.signUpRoute),
        isNull,
        reason: 'Unauthenticated user accessing signup should be allowed',
      );

      // 3. Authenticated user accessing login or signup redirects to home
      await AuthService.instance.signUp(
        fullName: 'Router User',
        username: 'routeruser',
        email: 'router@cognitivegym.app',
        password: 'password123',
      );
      expect(AuthService.instance.isLoggedIn, isTrue);

      expect(
        AppRouter.getRedirectForLocation(AppRouter.loginRoute),
        equals(AppRouter.homeRoute),
        reason: 'Authenticated user accessing login should redirect to home',
      );
      expect(
        AppRouter.getRedirectForLocation(AppRouter.signUpRoute),
        equals(AppRouter.homeRoute),
        reason: 'Authenticated user accessing signup should redirect to home',
      );

      // 4. Authenticated user accessing protected routes is allowed (no redirect)
      expect(
        AppRouter.getRedirectForLocation(AppRouter.homeRoute),
        isNull,
        reason: 'Authenticated user accessing home should be allowed',
      );
      expect(
        AppRouter.getRedirectForLocation(AppRouter.accountRoute),
        isNull,
        reason: 'Authenticated user accessing account should be allowed',
      );
    });
  });

  group('Authentication UI Widget Tests', () {
    testWidgets('LoginScreen renders header, input fields, and submit button',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const LoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cognitive Gym'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byKey(const Key('login_identifier_field')), findsOneWidget);
      expect(find.byKey(const Key('login_password_field')), findsOneWidget);
      expect(find.byKey(const Key('login_submit_button')), findsOneWidget);
    });

    testWidgets('SignUpScreen renders registration inputs and handles form validation',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const SignUpScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.byKey(const Key('signup_fullname_field')), findsOneWidget);
      expect(find.byKey(const Key('signup_username_field')), findsOneWidget);
      expect(find.byKey(const Key('signup_email_field')), findsOneWidget);
      expect(find.byKey(const Key('signup_password_field')), findsOneWidget);
      expect(find.byKey(const Key('signup_confirm_password_field')), findsOneWidget);

      final submitBtn = find.byKey(const Key('signup_submit_button'));
      expect(submitBtn, findsOneWidget);

      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your full name'), findsOneWidget);
    });
  });
}
