import 'package:cognitive_gym/screens/games_screen.dart';
import 'package:cognitive_gym/services/theme_service.dart';
import 'package:cognitive_gym/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  const gameTitles = [
    'Observation Challenge',
    'Scenario Lab',
    'Story Builder',
    'Sequence Master',
    'Debate Arena',
    'Spot the Difference',
  ];

  const viewports = <Size>[
    Size(1440, 900),
    Size(1280, 720),
    Size(1024, 768),
    Size(768, 1024),
    Size(390, 844),
  ];

  Future<void> pumpGamesScreen(
    WidgetTester tester,
    Size size,
    AppThemeMode mode,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getThemeData(mode),
        home: const GamesScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final size in viewports) {
    for (final mode in [AppThemeMode.light, AppThemeMode.dark]) {
      testWidgets(
        'games screen lays out without overflow at '
        '${size.width.toInt()}x${size.height.toInt()} in ${mode.name} theme',
        (tester) async {
          await pumpGamesScreen(tester, size, mode);

          expect(tester.takeException(), isNull);
          for (final title in gameTitles) {
            expect(find.text(title), findsOneWidget);
          }
        },
      );
    }
  }

  testWidgets('paired game cards share equal heights on desktop', (
    tester,
  ) async {
    await pumpGamesScreen(tester, const Size(1440, 900), AppThemeMode.light);

    Size cardSize(String gameTitle) {
      final card = find.ancestor(
        of: find.text(gameTitle),
        matching: find.byType(Container),
      );
      return tester.getSize(card.first);
    }

    final observation = cardSize('Observation Challenge');
    final scenario = cardSize('Scenario Lab');
    final story = cardSize('Story Builder');
    final debate = cardSize('Debate Arena');

    expect(observation.height, scenario.height);
    expect(story.height, debate.height);
    expect(observation.width, scenario.width);
  });

  testWidgets('cards stack in a single column on mobile and pair on tablet', (
    tester,
  ) async {
    await pumpGamesScreen(tester, const Size(390, 844), AppThemeMode.light);

    final mobileLeft = tester.getTopLeft(
      find.byKey(const ValueKey('game-card-OBSERVATION')),
    );
    final mobileRight = tester.getTopLeft(
      find.byKey(const ValueKey('game-card-DECISION')),
    );
    expect(mobileLeft.dx, mobileRight.dx);
    expect(mobileRight.dy, greaterThan(mobileLeft.dy));

    await pumpGamesScreen(tester, const Size(768, 1024), AppThemeMode.light);

    final tabletLeft = tester.getTopLeft(
      find.byKey(const ValueKey('game-card-OBSERVATION')),
    );
    final tabletRight = tester.getTopLeft(
      find.byKey(const ValueKey('game-card-DECISION')),
    );
    expect(tabletRight.dx, greaterThan(tabletLeft.dx));
    expect(tabletRight.dy, tabletLeft.dy);
  });
}
