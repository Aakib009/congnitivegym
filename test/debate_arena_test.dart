import 'package:cognitive_gym/models/debate_session.dart';
import 'package:cognitive_gym/models/debate_topic.dart';
import 'package:cognitive_gym/models/user_account.dart';
import 'package:cognitive_gym/screens/debate_arena_screen.dart';
import 'package:cognitive_gym/screens/debate_chat_screen.dart';
import 'package:cognitive_gym/screens/debate_loading_screen.dart';
import 'package:cognitive_gym/services/auth_service.dart';
import 'package:cognitive_gym/services/debate_arena_service.dart';
import 'package:cognitive_gym/services/offline_debate_service.dart';
import 'package:cognitive_gym/services/open_router_service.dart';
import 'package:cognitive_gym/services/progress_service.dart';
import 'package:cognitive_gym/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DebateArenaService Unit Tests', () {
    test('getAllTopics returns 9 predefined debate topics', () {
      final topics = DebateArenaService.getAllTopics();
      expect(topics.length, equals(9));
    });

    test('Each topic contains valid title, category, icon, and description', () {
      final topics = DebateArenaService.getAllTopics();
      for (final t in topics) {
        expect(t.id, isNotEmpty);
        expect(t.title, isNotEmpty);
        expect(t.category, isNotEmpty);
        expect(t.description, isNotEmpty);
      }
    });

    test('Topic titles match all required debate prompts', () {
      final topics = DebateArenaService.getAllTopics();
      final titles = topics.map((t) => t.title).toList();

      expect(titles, contains('Is patriotism beneficial or harmful?'));
      expect(titles, contains('Will AI make humanity more intelligent or more dependent?'));
      expect(titles, contains('Is entrepreneurship better than employment?'));
      expect(titles, contains('Are exams outdated measures of intelligence?'));
      expect(titles, contains('Should happiness be life\'s ultimate goal?'));
      expect(titles, contains('Can hard work beat talent?'));
      expect(titles, contains('Should voting require basic civic knowledge?'));
      expect(titles, contains('Does modern life make people lonelier?'));
      expect(titles, contains('Should philosophy be mandatory in schools?'));
    });
  });

  group('OpenRouterService Singleton Unit Tests', () {
    test('OpenRouterService instance exists and is accessible', () {
      final service = OpenRouterService.instance;
      expect(service, isNotNull);
    });
  });

  group('DebateArenaScreen Widget Tests', () {
    testWidgets('Renders Debate Arena grid layout and topic cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DebateArenaScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Debate Arena'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.textContaining('Start debate'), findsWidgets);
      expect(find.text('Is patriotism beneficial or harmful?'), findsOneWidget);
    });
  });

  group('DebateLoadingScreen Widget Tests', () {
    testWidgets('Renders loading screen with a single stable status message',
        (WidgetTester tester) async {
      const sampleTopic = DebateTopic(
        id: 'topic_02',
        title: 'Will AI make humanity more intelligent or more dependent?',
        category: 'Tech & Future',
        icon: Icons.smart_toy_outlined,
        description: 'Test description',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DebateLoadingScreen(topic: sampleTopic),
        ),
      );
      await tester.pump();

      expect(find.text('Preparing debate'), findsOneWidget);
      expect(find.text('Will AI make humanity more intelligent or more dependent?'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 650));
      expect(find.text('Preparing debate'), findsOneWidget);
    });
  });

  group('DebateChatScreen Widget Tests', () {
    setUp(() {
      OpenRouterService.instance.mockHandler = (messages) async {
        return 'Welcome to the debate! This is a mock opening argument.';
      };
    });

    tearDown(() {
      OpenRouterService.instance.mockHandler = null;
    });

    testWidgets('Renders Debate Arena chat interface',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const sampleTopic = DebateTopic(
        id: 'topic_02',
        title: 'Will AI make humanity more intelligent or more dependent?',
        category: 'Tech & Future',
        icon: Icons.smart_toy_outlined,
        description: 'Test description',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DebateChatScreen(topic: sampleTopic),
        ),
      );
      await tester.pump();

      expect(find.text('Debate Arena'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Debate message displays authenticated user name instead of Alex Mindful',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testAccount = UserAccount(
        id: 'user_jane_99',
        fullName: 'Jane Doe',
        username: 'janedoe',
        email: 'jane@example.com',
        password: 'dummy',
        createdAt: '2026-01-01T00:00:00Z',
      );
      AuthService.instance.setCurrentUserForTesting(testAccount);
      addTearDown(() => AuthService.instance.setCurrentUserForTesting(null));

      const sampleTopic = DebateTopic(
        id: 'topic_02',
        title: 'Will AI make humanity more intelligent or more dependent?',
        category: 'Tech & Future',
        icon: Icons.smart_toy_outlined,
        description: 'Test description',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DebateChatScreen(topic: sampleTopic),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextField), 'This is my first argument.');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('Alex Mindful'), findsNothing);
    });
  });

  group('OfflineDebateService Deterministic Engine Unit Tests', () {
    test('All 9 predefined topics have valid opening statements for both stances', () {
      final topics = DebateArenaService.getAllTopics();
      expect(topics.length, equals(9));

      for (final topic in topics) {
        final supportOpening = OfflineDebateService.instance.getOpponentOpeningStatement(
          topic: topic,
          userSide: DebateSide.support,
        );
        final opposeOpening = OfflineDebateService.instance.getOpponentOpeningStatement(
          topic: topic,
          userSide: DebateSide.oppose,
        );

        expect(supportOpening, isNotEmpty, reason: 'Support opening for ${topic.id} must exist');
        expect(opposeOpening, isNotEmpty, reason: 'Oppose opening for ${topic.id} must exist');
        expect(supportOpening.length, greaterThan(30));
        expect(opposeOpening.length, greaterThan(30));
        expect(supportOpening, isNot(equals(opposeOpening)));
      }
    });

    test('Round rebuttals exist and advance logically across rounds 1, 2, and 3+', () {
      final topics = DebateArenaService.getAllTopics();

      for (final topic in topics) {
        final round1 = OfflineDebateService.instance.getOpponentRebuttal(
          topic: topic,
          userSide: DebateSide.support,
          turn: 1,
        );
        final round2 = OfflineDebateService.instance.getOpponentRebuttal(
          topic: topic,
          userSide: DebateSide.support,
          turn: 2,
        );
        final round3 = OfflineDebateService.instance.getOpponentRebuttal(
          topic: topic,
          userSide: DebateSide.support,
          turn: 3,
        );

        expect(round1, isNotEmpty);
        expect(round2, isNotEmpty);
        expect(round3, isNotEmpty);
        expect(round1, isNot(equals(round2)));
      }
    });

    test('Closing synthesis summarizes topic dialectic constructively', () {
      final topics = DebateArenaService.getAllTopics();
      for (final topic in topics) {
        final synthesis = OfflineDebateService.instance.getOpponentClosing(
          topic: topic,
          userSide: DebateSide.support,
        );
        expect(synthesis, isNotEmpty);
        expect(synthesis.length, greaterThan(40));
      }
    });

    test('evaluateArgument scores adhere strictly to transparent rubric boundaries', () {
      final sampleTopic = DebateArenaService.getAllTopics().first;

      // 1. Boundary: Empty argument
      final emptyAnalysis = OfflineDebateService.instance.evaluateArgument(
        argument: '',
        topic: sampleTopic,
        userSide: DebateSide.support,
        turn: 1,
      );
      expect(emptyAnalysis.totalScore, equals(0));
      expect(emptyAnalysis.relevanceScore, equals(0));
      expect(emptyAnalysis.reasoningScore, equals(0));
      expect(emptyAnalysis.structureScore, equals(0));
      expect(emptyAnalysis.clarityScore, equals(0));
      expect(emptyAnalysis.feedbackSummary, contains('No argument'));

      // 2. Boundary: Minimal argument (< 3 words)
      final shortAnalysis = OfflineDebateService.instance.evaluateArgument(
        argument: 'Patriotism is good.',
        topic: sampleTopic,
        userSide: DebateSide.support,
        turn: 1,
      );
      expect(shortAnalysis.totalScore, inInclusiveRange(0, 45));
      expect(shortAnalysis.relevanceScore, inInclusiveRange(0, 25));
      expect(shortAnalysis.reasoningScore, inInclusiveRange(0, 30));
      expect(shortAnalysis.structureScore, inInclusiveRange(0, 25));
      expect(shortAnalysis.clarityScore, inInclusiveRange(0, 20));

      // 3. Robust, well-reasoned argument with logical connectives and topic keywords
      final structuredAnalysis = OfflineDebateService.instance.evaluateArgument(
        argument:
            'Patriotism unites diverse citizens under shared civic values and solidarity, '
            'because when a nation faces crises, collective national pride motivates sacrifice '
            'and altruism. Furthermore, empirical evidence demonstrates that civic patriotism '
            'strengthens democratic participation. However, unchecked nationalism differs fundamentally, '
            'therefore constitutional safeguards remain vital.',
        topic: sampleTopic,
        userSide: DebateSide.support,
        turn: 1,
      );

      expect(structuredAnalysis.totalScore, inInclusiveRange(70, 100));
      expect(structuredAnalysis.relevanceScore, inInclusiveRange(15, 25));
      expect(structuredAnalysis.reasoningScore, inInclusiveRange(18, 30));
      expect(structuredAnalysis.structureScore, inInclusiveRange(15, 25));
      expect(structuredAnalysis.clarityScore, inInclusiveRange(14, 20));

      // 4. Clamping verification: extreme length never exceeds 100
      final extremeAnalysis = OfflineDebateService.instance.evaluateArgument(
        argument: ('Because therefore however furthermore evidence civic nation patriotism. ' * 50),
        topic: sampleTopic,
        userSide: DebateSide.support,
        turn: 2,
      );
      expect(extremeAnalysis.totalScore, lessThanOrEqualTo(100));
      expect(extremeAnalysis.relevanceScore, lessThanOrEqualTo(25));
      expect(extremeAnalysis.reasoningScore, lessThanOrEqualTo(30));
      expect(extremeAnalysis.structureScore, lessThanOrEqualTo(25));
      expect(extremeAnalysis.clarityScore, lessThanOrEqualTo(20));
    });

    test('evaluateArgument is strictly deterministic', () {
      final sampleTopic = DebateArenaService.getAllTopics()[1];
      const arg = 'Artificial intelligence accelerates productivity because automation handles repetitive tasks, therefore freeing humans for creative strategy.';
      final run1 = OfflineDebateService.instance.evaluateArgument(argument: arg, topic: sampleTopic, userSide: DebateSide.support, turn: 1);
      final run2 = OfflineDebateService.instance.evaluateArgument(argument: arg, topic: sampleTopic, userSide: DebateSide.support, turn: 1);

      expect(run1.totalScore, equals(run2.totalScore));
      expect(run1.relevanceScore, equals(run2.relevanceScore));
      expect(run1.reasoningScore, equals(run2.reasoningScore));
      expect(run1.structureScore, equals(run2.structureScore));
      expect(run1.clarityScore, equals(run2.clarityScore));
      expect(run1.feedbackSummary, equals(run2.feedbackSummary));
    });
  });

  group('Debate Arena Progress & Duplicate XP Prevention Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await ProgressService.instance.clearIdempotencyKeys();
    });

    test('recordDebateArenaCompletion awards XP once and rejects duplicate idempotencyKey', () async {
      const idempotencyKey = 'test_debate_completion_unique_key_001';

      // First completion award
      final xpEarnedFirst = await ProgressService.instance.recordDebateArenaCompletion(
        performanceScore: 85.0,
        durationSeconds: 120,
        idempotencyKey: idempotencyKey,
      );

      expect(xpEarnedFirst, greaterThan(0));

      // Duplicate completion with exact same idempotency key
      final xpEarnedDuplicate = await ProgressService.instance.recordDebateArenaCompletion(
        performanceScore: 85.0,
        durationSeconds: 120,
        idempotencyKey: idempotencyKey,
      );

      expect(xpEarnedDuplicate, equals(0), reason: 'Duplicate completions must return 0 XP to prevent double awards');
    });
  });

  group('Debate Arena Stance Selection Widget Tests', () {
    testWidgets('Tapping topic opens stance selection modal allowing stance change', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DebateArenaScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the first topic card
      await tester.tap(find.text('Is patriotism beneficial or harmful?'));
      await tester.pumpAndSettle();

      // Modal bottom sheet should appear with stance options
      expect(find.text('Choose your stance'), findsOneWidget);
      expect(find.text('Support'), findsOneWidget);
      expect(find.text('Oppose'), findsOneWidget);
      expect(find.textContaining('Enter arena'), findsOneWidget);

      // Tap Oppose
      await tester.tap(find.text('Oppose'));
      await tester.pumpAndSettle();

      // Sheet still shows the arena action
      expect(find.textContaining('Enter arena'), findsOneWidget);
    });
  });

  group('Debate Arena Theme Consistency Tests', () {
    testWidgets('DebateArenaScreen renders cleanly under Dark and Light themes', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // 1. Dark Theme
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const DebateArenaScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Debate Arena'), findsOneWidget);

      // 2. Light Theme
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DebateArenaScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Debate Arena'), findsOneWidget);
    });
  });
}

