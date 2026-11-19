import 'package:cognitive_gym/main.dart';
import 'package:cognitive_gym/services/anti_gravity_service.dart';
import 'package:cognitive_gym/services/auth_service.dart';
import 'package:cognitive_gym/services/database_service.dart';
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

  group('Cognitive Gym Smoke Tests', () {
    testWidgets('CognitiveGymApp renders without crashing', (WidgetTester tester) async {
      await tester.runAsync(() async {
        await AuthService.instance.signUp(
          fullName: 'Alex Mindful',
          username: 'alexmindful',
          email: 'alex@cognitivegym.app',
          password: 'password123',
        );
        await AuthService.instance.login(
          emailOrUsername: 'alexmindful',
          password: 'password123',
        );
      });

      await tester.pumpWidget(const CognitiveGymApp());
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));


      expect(find.text('Cognitive Gym'), findsWidgets);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('CognitiveGymApp renders StartupErrorScreen when startup exception occurs',
        (WidgetTester tester) async {
      await tester.pumpWidget(const CognitiveGymApp(
        startupError: 'Database failed to open: SQLite database locked',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Initialization Warning'), findsOneWidget);
      expect(find.textContaining('Database failed to open'), findsOneWidget);
      expect(find.text('Retry Startup'), findsOneWidget);
    });

    test('AntiGravityService initializes and fetches metrics', () async {
      final service = AntiGravityService();
      final initialized = await service.initializeApi();
      expect(initialized, isTrue);

      final metrics = await service.fetchMetrics();
      expect(metrics.spatialEquilibrium, greaterThan(0));
      expect(metrics.isAntiGravityFieldActive, isTrue);
    });
  });
}
