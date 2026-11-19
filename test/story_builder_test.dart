import 'package:cognitive_gym/models/story_model.dart';
import 'package:cognitive_gym/screens/story_builder_screen.dart';
import 'package:cognitive_gym/services/progress_service.dart';
import 'package:cognitive_gym/services/story_storage_service.dart';
import 'package:cognitive_gym/services/word_generator_service.dart';
import 'package:cognitive_gym/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StoryModel Tests', () {
    test('countWords accurately calculates word count', () {
      expect(StoryModel.countWords(''), equals(0));
      expect(StoryModel.countWords('   '), equals(0));
      expect(StoryModel.countWords('Hello world'), equals(2));
      expect(
        StoryModel.countWords(
            'The quick brown fox jumps over the lazy dog near the river.'),
        equals(12),
      );
    });

    test('toJson and fromJson correctly serialize and deserialize model', () {
      final now = DateTime.now();
      final story = StoryModel(
        id: 'story_123',
        words: ['Lantern', 'Whisper', 'River'],
        content: 'A long story text with enough words for the challenge.',
        createdAt: now,
        wordCount: 10,
        pointsEarned: 15,
      );

      final jsonMap = story.toJson();
      final deserialized = StoryModel.fromJson(jsonMap);

      expect(deserialized.id, equals(story.id));
      expect(deserialized.words, equals(story.words));
      expect(deserialized.content, equals(story.content));
      expect(deserialized.wordCount, equals(story.wordCount));
      expect(deserialized.pointsEarned, equals(15));
    });

    test('getMissingWords and hasAllRequiredWords accurately validate required words', () {
      final requiredWords = ['River', 'Lantern', 'Summit'];

      // Case 1: Story with all required words matching case
      const storyAllMatch =
          'The river was wide. A lantern lit the path to the summit.';
      expect(StoryModel.getMissingWords(storyAllMatch, requiredWords), isEmpty);
      expect(StoryModel.hasAllRequiredWords(storyAllMatch, requiredWords), isTrue);

      // Case 2: Ignore case differences (RIVER, lantern, sUmMiT)
      const storyCaseMismatch =
          'The RIVER was wide. A lantern lit the path to the sUmMiT.';
      expect(StoryModel.getMissingWords(storyCaseMismatch, requiredWords), isEmpty);
      expect(StoryModel.hasAllRequiredWords(storyCaseMismatch, requiredWords), isTrue);

      // Case 3: Ignore punctuation differences (river., "lantern", (summit)!)
      const storyPunctuation =
          'I saw a river. He held a "lantern" near the (summit)!';
      expect(StoryModel.getMissingWords(storyPunctuation, requiredWords), isEmpty);
      expect(StoryModel.hasAllRequiredWords(storyPunctuation, requiredWords), isTrue);

      // Case 4: Missing some required words
      const storyMissingTwo = 'Only a river was present in the valley.';
      final missing = StoryModel.getMissingWords(storyMissingTwo, requiredWords);
      expect(missing, containsAll(['Lantern', 'Summit']));
      expect(missing.contains('River'), isFalse);
      expect(StoryModel.hasAllRequiredWords(storyMissingTwo, requiredWords), isFalse);

      // Case 5: Partial word does not match (e.g. driver != river)
      const storyPartialWord = 'The driver used a lantern at the summit.';
      final missingPartial = StoryModel.getMissingWords(storyPartialWord, requiredWords);
      expect(missingPartial, equals(['River']));
      expect(StoryModel.hasAllRequiredWords(storyPartialWord, requiredWords), isFalse);
    });
  });

  group('WordGeneratorService Tests', () {
    test('getRandomWords returns requested number of unique words', () {
      final words = WordGeneratorService.getRandomWords(count: 3);
      expect(words.length, equals(3));
      expect(words.toSet().length, equals(3));
      for (final w in words) {
        expect(w, isNotEmpty);
      }
    });
  });

  group('StoryStorageService Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('saveStory, getStories, and deleteStory work as expected', () async {
      final story = StoryModel(
        id: 'test_story_1',
        words: ['Moss', 'Summit', 'Compass'],
        content:
            'Deep in the forest, moss covered the ground leading up to the summit...',
        createdAt: DateTime.now(),
        wordCount: 12,
        pointsEarned: 15,
      );

      final saveResult = await StoryStorageService.saveStory(story);
      expect(saveResult, isTrue);

      final loadedStories = await StoryStorageService.getStories();
      expect(loadedStories.length, equals(1));
      expect(loadedStories.first.id, equals('test_story_1'));
      expect(loadedStories.first.words, contains('Moss'));

      final deleteResult = await StoryStorageService.deleteStory('test_story_1');
      expect(deleteResult, isTrue);

      final emptyList = await StoryStorageService.getStories();
      expect(emptyList, isEmpty);
    });
  });

  group('StoryBuilderScreen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Renders StoryBuilderScreen with initial state and word cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const StoryBuilderScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Story Builder'), findsOneWidget);
      expect(find.text('Write story'), findsOneWidget);
      expect(find.text('Creativity Challenge'), findsOneWidget);
      expect(
          find.text('Create a short story using all three words.'), findsOneWidget);
      expect(find.text('Complete challenge'), findsOneWidget);
    });

    testWidgets('Fails submission if required words are missing',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const StoryBuilderScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter story text with at least 40 words, but no required words
      final storyWithoutWords = List.generate(45, (i) => 'word$i').join(' ');
      await tester.enterText(find.byType(TextField), storyWithoutWords);
      await tester.pumpAndSettle();

      // Ensure button is scrolled into view and tap complete challenge
      await tester.ensureVisible(find.text('Complete challenge'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete challenge'));
      await tester.pumpAndSettle();

      // Should show warning SnackBar about missing words
      expect(
          find.text(
              "You haven't used all three required words yet. Try incorporating every given word into your story before submitting."),
          findsOneWidget);
      expect(find.text('Missing words:'), findsOneWidget);
      expect(find.text('Challenge complete'), findsNothing);
    });

    testWidgets('Succeeds submission when all required words are included',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const StoryBuilderScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter text containing all words from wordPool so any generated 3 words match, plus 45 dummy words
      final allWordsStory =
          '${WordGeneratorService.wordPool.join(' ')} ${List.generate(45, (i) => "extra$i").join(' ')}';

      await tester.enterText(find.byType(TextField), allWordsStory);
      await tester.pumpAndSettle();

      // Ensure button is scrolled into view and tap complete challenge
      await tester.ensureVisible(find.text('Complete challenge'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Complete challenge'));
      await tester.pumpAndSettle();

      // Should show completion dialog with real computed score and rewards
      expect(find.text('Challenge complete'), findsOneWidget);
      expect(find.text('Performance score: 100/100'), findsOneWidget);
      expect(find.textContaining('+15 creativity points'), findsOneWidget);
      expect(find.textContaining('+20 XP'), findsOneWidget);
    });

    testWidgets('Double-tap complete challenge prevents duplicate XP awards and duplicate story saves',
        (WidgetTester tester) async {
      await ProgressService.instance.resetProgress();
      final initialExercises =
          ProgressService.instance.userProfile.totalExercisesCompleted;
      final initialXp = ProgressService.instance.userProfile.totalXp;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const StoryBuilderScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final allWordsStory =
          '${WordGeneratorService.wordPool.join(' ')} ${List.generate(45, (i) => "extra$i").join(' ')}';

      await tester.enterText(find.byType(TextField), allWordsStory);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Complete challenge'));
      await tester.pumpAndSettle();

      // Rapid double tap
      await tester.tap(find.text('Complete challenge'));
      await tester.tap(find.text('Complete challenge'));
      await tester.pumpAndSettle();

      expect(find.text('Challenge complete'), findsOneWidget);

      final finalExercises =
          ProgressService.instance.userProfile.totalExercisesCompleted;
      final finalXp = ProgressService.instance.userProfile.totalXp;

      expect(finalExercises - initialExercises, equals(1));
      expect(finalXp - initialXp, equals(20));

      final savedStories = await StoryStorageService.getStories();
      expect(savedStories.length, equals(1));
    });
  });
}

