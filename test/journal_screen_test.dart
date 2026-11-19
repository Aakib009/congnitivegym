import 'package:cognitive_gym/models/journal_entry.dart';
import 'package:cognitive_gym/screens/journal_screen.dart';
import 'package:cognitive_gym/services/database_service.dart';
import 'package:cognitive_gym/services/journal_service.dart';
import 'package:cognitive_gym/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    DatabaseService.initializeFactory();
    await DatabaseService.resetForTesting(dbPath: inMemoryDatabasePath);
  });

  tearDownAll(() async {
    await DatabaseService.resetForTesting();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    JournalService.instance.seedEntriesForTesting([]);
  });

  group('JournalEntry Model Unit Tests', () {
    test('toMap and fromMap serialize and deserialize accurately', () {
      final now = DateTime(2026, 10, 23, 10, 30);
      final entry = JournalEntry(
        id: 'entry_001',
        userId: 'usr_test',
        moodEmoji: '⚡',
        moodLabel: 'Energetic',
        entryText: 'Crushed the focus observation workout today.',
        category: 'Post-Workout',
        createdAt: now,
      );

      final map = entry.toMap();
      final deserialized = JournalEntry.fromMap(map);

      expect(deserialized.id, equals('entry_001'));
      expect(deserialized.userId, equals('usr_test'));
      expect(deserialized.moodEmoji, equals('⚡'));
      expect(deserialized.moodLabel, equals('Energetic'));
      expect(deserialized.entryText, equals('Crushed the focus observation workout today.'));
      expect(deserialized.category, equals('Post-Workout'));
      expect(deserialized.createdAt.toIso8601String(), equals(now.toIso8601String()));
    });
  });

  group('JournalService SQLite Persistence Tests', () {
    test('addEntry, loadEntries, and deleteEntry operate against SQLite', () async {
      await DatabaseService.instance.clearAllJournalEntries();
      final service = JournalService.instance;
      service.resetForTesting();
      expect(service.entries, isEmpty);

      // Add first entry
      final entry1 = await service.addEntry(
        moodEmoji: '🌿',
        moodLabel: 'Calm',
        entryText: 'Morning meditation complete.',
        category: 'Pre-Workout',
      );
      expect(entry1, isNotNull);
      expect(service.entries.length, equals(1));

      // Add second entry
      final entry2 = await service.addEntry(
        moodEmoji: '🌀',
        moodLabel: 'Focused',
        entryText: 'Deep work session was productive.',
        category: 'Reflection',
      );
      expect(entry2, isNotNull);
      expect(service.entries.length, equals(2));

      // Re-load from SQLite to verify true persistence
      await service.loadEntries();
      expect(service.entries.length, equals(2));
      expect(service.entries.first.moodLabel, equals('Focused'));

      // Delete one entry
      final deleted = await service.deleteEntry(entry1!.id);
      expect(deleted, isTrue);
      expect(service.entries.length, equals(1));
      expect(service.entries.first.id, equals(entry2!.id));
    });
  });

  group('JournalScreen Widget Tests', () {
    testWidgets('Renders welcome header, 2x2 category grid, spacious writing area, and recent reflections container',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      JournalService.instance.seedEntriesForTesting([]);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const JournalScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Heading & Welcome Header
      expect(find.text('Cognitive Journal'), findsOneWidget);
      final appBarFinder = find.byType(AppBar);
      expect(appBarFinder, findsOneWidget);
      expect(
        find.descendant(of: appBarFinder, matching: find.byIcon(Icons.menu_book_rounded)),
        findsOneWidget,
      );
      final titleWidget = tester.widget<Text>(find.descendant(of: appBarFinder, matching: find.text('Cognitive Journal')));
      expect(titleWidget.style?.fontWeight, equals(FontWeight.bold));
      expect(titleWidget.style?.fontSize, equals(20));

      expect(find.text('Your Mindful Space'), findsOneWidget);
      expect(
        find.text('A moment for yourself. A space for your thoughts.'),
        findsOneWidget,
      );

      // 2. Check-in section
      expect(find.text('How is your mind feeling right now?'), findsOneWidget);
      expect(find.text('Calm'), findsOneWidget);
      expect(find.text('Energetic'), findsOneWidget);
      expect(find.text('Focused'), findsOneWidget);
      expect(find.text('Foggy'), findsOneWidget);
      expect(find.text('Resting'), findsOneWidget);

      // 3. 2x2 Category Grid
      expect(find.text('Reflection'), findsWidgets);
      expect(find.text('Pre-Workout'), findsOneWidget);
      expect(find.text('Post-Workout'), findsOneWidget);
      expect(find.text('Mindful Insight'), findsOneWidget);

      // 4. Writing area with reflective placeholder
      expect(find.byType(TextField), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(
        textField.decoration?.hintText,
        equals(
          'Take a moment to reflect. How was your day? What did you learn, experience, or feel today?',
        ),
      );
      expect(textField.minLines, greaterThanOrEqualTo(10));

      expect(find.text('Log entry'), findsOneWidget);

      // 5. Recent reflections container with header inside
      expect(find.text('Recent reflections'), findsOneWidget);
      expect(find.text('Your saved mindfulness entries'), findsOneWidget);
      expect(find.text('No reflections yet'), findsOneWidget);
    });

    testWidgets('Validates empty text input before saving',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      JournalService.instance.seedEntriesForTesting([]);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const JournalScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log entry'));
      await tester.pumpAndSettle();

      expect(find.text('Write a brief reflection before saving.'),
          findsOneWidget);
    });

    testWidgets('Interactively selects mood, category in 2x2 grid, and renders seeded entries in history container',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final existingEntry = JournalEntry(
        id: 'seeded_1',
        userId: 'usr_test',
        moodEmoji: '🌀',
        moodLabel: 'Focused',
        entryText: 'Finished observation challenge with high accuracy. Felt very alert.',
        category: 'Post-Workout',
        createdAt: DateTime.now(),
      );
      JournalService.instance.seedEntriesForTesting([existingEntry]);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const JournalScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Select 'Focused' mood
      await tester.tap(find.text('Focused').first);
      await tester.pumpAndSettle();

      // Select 'Post-Workout' category
      await tester.tap(find.text('Post-Workout').first);
      await tester.pumpAndSettle();

      // Select 'Mindful Insight' category
      await tester.tap(find.text('Mindful Insight'));
      await tester.pumpAndSettle();

      // Verify entry appears in the list inside Recent Reflections container
      expect(
        find.textContaining('Finished observation challenge with high accuracy'),
        findsOneWidget,
      );
      expect(find.text('Post-Workout'), findsWidgets);
      expect(find.text('1 entry'), findsOneWidget);
    });
  });
}
