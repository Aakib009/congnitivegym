import 'package:cognitive_gym/screens/scenario_lab_screen.dart';
import 'package:cognitive_gym/services/scenario_lab_service.dart';
import 'package:cognitive_gym/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScenarioLabService Unit Tests', () {
    test('getAllScenarios returns 10 predefined scenarios', () {
      final scenarios = ScenarioLabService.getAllScenarios();
      expect(scenarios.length, equals(10));
    });

    test('Each scenario contains background, role, constraints, and valid options', () {
      final scenarios = ScenarioLabService.getAllScenarios();
      for (final s in scenarios) {
        expect(s.title, isNotEmpty);
        expect(s.role, isNotEmpty);
        expect(s.category, isNotEmpty);
        expect(s.background, isNotEmpty);
        expect(s.objective, isNotEmpty);
        expect(s.constraints, isNotEmpty);
        expect(s.options.length, greaterThanOrEqualTo(2));

        for (final opt in s.options) {
          expect(opt.title, isNotEmpty);
          expect(opt.description, isNotEmpty);
          expect(opt.consequence, isNotEmpty);
          expect(opt.strengths, isNotEmpty);
          expect(opt.weaknesses, isNotEmpty);
        }
      }
    });

    test('getRandomScenario returns a valid ScenarioModel', () {
      final random = ScenarioLabService.getRandomScenario();
      expect(random.id, isNotEmpty);
      expect(random.options, isNotEmpty);
    });
  });

  group('ScenarioLabScreen Widget Tests', () {
    testWidgets('Renders scenario title, role prompt, TTS speaker, and decision options',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ScenarioLabScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Scenario Lab'), findsOneWidget);
      expect(find.textContaining('You are the'), findsOneWidget);
      expect(find.byKey(const Key('tts_speaker_button')), findsOneWidget);
      expect(find.text('Confirm Decision'), findsOneWidget);
    });

    testWidgets('Selecting an option and confirming reveals dedicated Result view',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ScenarioLabScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find first option card (Option A)
      final optionA = find.textContaining('Option A').first;
      await tester.ensureVisible(optionA);
      await tester.tap(optionA);
      await tester.pumpAndSettle();

      // Tap Confirm Decision
      final confirmBtn = find.text('Confirm Decision');
      await tester.ensureVisible(confirmBtn);
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify dedicated Result view elements
      expect(find.text('DECISION OUTCOME'), findsOneWidget);
      expect(find.text('Decision Selected'), findsOneWidget);
      expect(find.text('Outcome'), findsOneWidget);
      expect(find.text('Reflection'), findsOneWidget);
      // Honest real rewards: deliberation is near-instant in the test, so the
      // engagement score is low but participation XP is still awarded.
      expect(find.textContaining('Deliberation Score:'), findsOneWidget);
      expect(find.textContaining('Decision Points'), findsOneWidget);
      expect(find.textContaining('• +20 XP'), findsOneWidget);
      expect(find.text('Next Scenario'), findsOneWidget);
    });
  });
}
