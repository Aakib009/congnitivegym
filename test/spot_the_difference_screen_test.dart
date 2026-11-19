import 'package:cognitive_gym/models/spot_the_difference.dart';
import 'package:cognitive_gym/screens/spot_the_difference_screen.dart';
import 'package:cognitive_gym/services/database_service.dart';
import 'package:cognitive_gym/services/progress_service.dart';
import 'package:cognitive_gym/services/spot_the_difference_service.dart';
import 'package:cognitive_gym/services/theme_service.dart';
import 'package:cognitive_gym/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    DatabaseService.initializeFactory();
    await DatabaseService.resetForTesting(dbPath: inMemoryDatabasePath);
  });

  tearDownAll(() async {
    await DatabaseService.resetForTesting();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DatabaseService.instance.clearAllAnalyticsEvents();
    await ProgressService.instance.init();
    await ProgressService.instance.resetProgress();
  });

  const viewports = <Size>[
    Size(1440, 900),
    Size(1280, 720),
    Size(1024, 768),
    Size(768, 1024),
    Size(390, 844),
  ];

  Future<void> pumpScreen(
    WidgetTester tester, {
    Size size = const Size(1024, 768),
    AppThemeMode mode = AppThemeMode.light,
    SpotDifferenceDifficulty difficulty = SpotDifferenceDifficulty.easy,
    String? challengeId,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getThemeData(mode),
        home: SpotTheDifferenceScreen(
          initialDifficulty: difficulty,
          initialChallengeId: challengeId,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> startSession(WidgetTester tester) async {
    final start = find.byKey(const ValueKey('spot-start-button'));
    await tester.ensureVisible(start);
    await tester.pump();
    await tester.tap(start);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> tapDifferenceOnPanel(
    WidgetTester tester,
    DifferenceTarget diff, {
    bool onPanelB = false,
  }) async {
    final panelKey = onPanelB
        ? const ValueKey('spot-image-panel-b')
        : const ValueKey('spot-image-panel-a');
    final panelFinder = find.byKey(panelKey);
    final panelRect = tester.getRect(panelFinder);

    final containerW = panelRect.width;
    final containerH = panelRect.height;
    final containerAspect = containerW / containerH;
    const imageAspect = 800.0 / 600.0;

    double renderedW;
    double renderedH;
    double offsetX;
    double offsetY;

    if (containerAspect > imageAspect) {
      renderedH = containerH;
      renderedW = containerH * imageAspect;
      offsetX = (containerW - renderedW) / 2;
      offsetY = 0;
    } else {
      renderedW = containerW;
      renderedH = containerW / imageAspect;
      offsetX = 0;
      offsetY = (containerH - renderedH) / 2;
    }

    final tapX = panelRect.left + offsetX + (diff.x * renderedW);
    final tapY = panelRect.top + offsetY + (diff.y * renderedH);

    await tester.tapAt(Offset(tapX, tapY));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> tapMissOnPanel(WidgetTester tester) async {
    final panelFinder = find.byKey(const ValueKey('spot-image-panel-a'));
    final panelRect = tester.getRect(panelFinder);

    final containerW = panelRect.width;
    final containerH = panelRect.height;
    final containerAspect = containerW / containerH;
    const imageAspect = 800.0 / 600.0;

    double renderedW;
    double renderedH;
    double offsetX;
    double offsetY;

    if (containerAspect > imageAspect) {
      renderedH = containerH;
      renderedW = containerH * imageAspect;
      offsetX = (containerW - renderedW) / 2;
      offsetY = 0;
    } else {
      renderedW = containerW;
      renderedH = containerW / imageAspect;
      offsetX = 0;
      offsetY = (containerH - renderedH) / 2;
    }

    // Tap at normalized (0.05, 0.05) inside rendered image canvas
    final tapX = panelRect.left + offsetX + (0.05 * renderedW);
    final tapY = panelRect.top + offsetY + (0.05 * renderedH);

    await tester.tapAt(Offset(tapX, tapY));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('Spot the Difference Screen Flow Tests', () {
    testWidgets(
      'intro renders mission brief, challenge picker, and difficulty selector',
      (tester) async {
        await pumpScreen(tester);

        expect(find.text('Spot the Difference'), findsWidgets);
        expect(find.text('Mission Brief'), findsOneWidget);
        expect(find.text('Cozy Mountain Cabin'), findsOneWidget);
        expect(find.byKey(const ValueKey('spot-diff-easy')), findsOneWidget);
        expect(find.byKey(const ValueKey('spot-diff-medium')), findsOneWidget);
        expect(find.byKey(const ValueKey('spot-diff-hard')), findsOneWidget);
        expect(find.byKey(const ValueKey('spot-start-button')), findsOneWidget);
      },
    );

    testWidgets('changing difficulty updates selection highlight', (
      tester,
    ) async {
      await pumpScreen(tester);

      final hardCard = find.byKey(const ValueKey('spot-diff-hard'));
      await tester.ensureVisible(hardCard);
      await tester.pump();
      await tester.tap(hardCard);
      await tester.pumpAndSettle();

      await startSession(tester);
      expect(find.textContaining('Hard • Found 0 of 4'), findsOneWidget);
      expect(find.text('40s'), findsOneWidget); // 40s timer limit for Hard
    });

    testWidgets('playing view renders dual panels, timer, and counter', (
      tester,
    ) async {
      await pumpScreen(tester);
      await startSession(tester);

      expect(find.text('Cozy Mountain Cabin'), findsWidgets);
      expect(find.textContaining('Found 0 of 4'), findsOneWidget);
      expect(find.byKey(const ValueKey('spot-image-panel-a')), findsOneWidget);
      expect(find.byKey(const ValueKey('spot-image-panel-b')), findsOneWidget);
      expect(find.text('IMAGE A'), findsOneWidget);
      expect(find.text('IMAGE B'), findsOneWidget);
    });

    testWidgets(
      'tapping discrepancy reveals markers on both panels and does not double-count',
      (tester) async {
        await pumpScreen(tester);
        await startSession(tester);

        final challenge = SpotTheDifferenceService.getChallengeById(
          'challenge_01',
        );
        final diff1 = challenge.differences[0];

        // Tap first difference on Image A
        await tapDifferenceOnPanel(tester, diff1, onPanelB: false);
        expect(find.textContaining('Found 1 of 4'), findsOneWidget);

        // Verify discovered marker rendered on BOTH image panels
        expect(find.text('1'), findsNWidgets(2));

        // Tap same difference again on Image B - should NOT increment
        await tapDifferenceOnPanel(tester, diff1, onPanelB: true);
        expect(find.textContaining('Found 1 of 4'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping incorrect location registers mistake without discovering',
      (tester) async {
        await pumpScreen(tester);
        await startSession(tester);

        await tapMissOnPanel(tester);
        expect(find.textContaining('Found 0 of 4'), findsOneWidget);
        expect(find.textContaining('(1 mistakes)'), findsOneWidget);
      },
    );

    testWidgets(
      'discovering all differences transitions to results and awards rewards',
      (tester) async {
        await pumpScreen(tester);
        final initialXp = ProgressService.instance.userProfile.totalXp;
        final initialExercises =
            ProgressService.instance.userProfile.totalExercisesCompleted;

        await startSession(tester);
        final challenge = SpotTheDifferenceService.getChallengeById(
          'challenge_01',
        );

        for (var i = 0; i < challenge.differences.length; i++) {
          // Alternate tapping on panel A and panel B
          await tapDifferenceOnPanel(
            tester,
            challenge.differences[i],
            onPanelB: i % 2 == 1,
          );
        }

        await tester.pumpAndSettle();

        // Results view assertions
        expect(find.text('Observation Complete'), findsOneWidget);
        expect(find.text('4 / 4 Differences'), findsOneWidget);
        expect(find.textContaining('100% touch accuracy'), findsOneWidget);
        expect(find.text('+20 XP'), findsOneWidget);
        expect(
          find.text('+11 observation points'),
          findsOneWidget,
        ); // 15 * 0.7 = 10.5 -> 11

        // Verify progress updated
        expect(
          ProgressService.instance.userProfile.totalXp,
          equals(initialXp + 20),
        );
        expect(
          ProgressService.instance.userProfile.totalExercisesCompleted,
          equals(initialExercises + 1),
        );
        expect(
          ProgressService.instance.userProfile.observationPoints,
          equals(11),
        );

        // Verify difference breakdown cards
        for (final diff in challenge.differences) {
          expect(find.textContaining(diff.description), findsOneWidget);
        }

        // Replay button works
        final replay = find.byKey(const ValueKey('spot-replay-button'));
        await tester.ensureVisible(replay);
        await tester.pump();
        await tester.tap(replay);
        await tester.pumpAndSettle();

        expect(find.textContaining('Found 0 of 4'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('spot-image-panel-a')),
          findsOneWidget,
        );
      },
    );

    testWidgets('router navigation back to games screen works', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => context.push('/spot-the-difference'),
                  child: const Text('Open spot the difference'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/spot-the-difference',
            builder: (context, state) => const SpotTheDifferenceScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router, theme: AppTheme.lightTheme),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open spot the difference'));
      await tester.pumpAndSettle();

      await startSession(tester);
      final challenge = SpotTheDifferenceService.getChallengeById(
        'challenge_01',
      );
      for (final diff in challenge.differences) {
        await tapDifferenceOnPanel(tester, diff);
      }
      await tester.pumpAndSettle();

      final backButton = find.byKey(const ValueKey('spot-games-button'));
      await tester.ensureVisible(backButton);
      await tester.pump();
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('Open spot the difference'), findsOneWidget);
    });

    for (final size in viewports) {
      for (final mode in [AppThemeMode.light, AppThemeMode.dark]) {
        testWidgets(
          'screen lays out with zero overflow at ${size.width.toInt()}x${size.height.toInt()} in ${mode.name} theme',
          (tester) async {
            await pumpScreen(tester, size: size, mode: mode);
            expect(tester.takeException(), isNull);

            await startSession(tester);
            expect(tester.takeException(), isNull);
            expect(
              find.byKey(const ValueKey('spot-image-panel-a')),
              findsOneWidget,
            );
            expect(
              find.byKey(const ValueKey('spot-image-panel-b')),
              findsOneWidget,
            );
          },
        );
      }
    }
  });
}
