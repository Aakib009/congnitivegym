import 'dart:math';

import 'package:cognitive_gym/models/sequence_master.dart';
import 'package:cognitive_gym/services/sequence_master_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void expectValidQuestion(
    SequenceMasterQuestion question,
    SequenceMasterDifficulty difficulty,
  ) {
    expect(question.id, isNotEmpty);
    expect(question.difficulty, difficulty);
    expect(question.sequence, isNotEmpty);
    expect(question.blankCount, difficulty.blankCount);
    expect(question.correctValues.length, difficulty.blankCount);
    expect(question.options.length, 4);
    expect(question.options.toSet().length, 4);
    expect(question.correctOptionIndex, inInclusiveRange(0, 3));
    expect(
      question.correctAnswer,
      question.options[question.correctOptionIndex],
    );
    expect(
      question.options.where((o) => o == question.correctAnswer).length,
      1,
    );
    expect(question.explanation, isNotEmpty);
    expect(question.isCorrect(question.correctOptionIndex), isTrue);
    for (var index = 0; index < question.options.length; index++) {
      if (index != question.correctOptionIndex) {
        expect(question.isCorrect(index), isFalse);
      }
    }
  }

  group('SequenceMasterService generation', () {
    for (final difficulty in SequenceMasterDifficulty.values) {
      test('generates the full valid ${difficulty.name} bank', () {
        final questions = SequenceMasterService.generateQuestions(
          difficulty: difficulty,
          count: 16,
          random: Random(17),
        );

        expect(questions.length, 16);
        expect(questions.map((q) => q.id).toSet().length, 16);
        expect(
          questions.map((q) => q.category).toSet(),
          containsAll(SequenceCategory.values),
        );
        for (final question in questions) {
          expectValidQuestion(question, difficulty);
        }
      });

      test(
        'uses the configured default question count for ${difficulty.name}',
        () {
          final questions = SequenceMasterService.generateQuestions(
            difficulty: difficulty,
            random: Random(3),
          );

          expect(questions.length, difficulty.questionCount);
          expect(questions.length, inInclusiveRange(8, 12));
          expect(
            questions.map((q) => q.category).toSet(),
            containsAll(SequenceCategory.values),
          );
        },
      );
    }

    test('easy and medium hide one value while hard hides two', () {
      final easy = SequenceMasterService.generateQuestions(
        difficulty: SequenceMasterDifficulty.easy,
        random: Random(1),
      );
      final medium = SequenceMasterService.generateQuestions(
        difficulty: SequenceMasterDifficulty.medium,
        random: Random(1),
      );
      final hard = SequenceMasterService.generateQuestions(
        difficulty: SequenceMasterDifficulty.hard,
        random: Random(1),
      );

      expect(easy.every((q) => q.blankCount == 1), isTrue);
      expect(medium.every((q) => q.blankCount == 1), isTrue);
      expect(hard.every((q) => q.blankCount == 2), isTrue);
      expect(hard.every((q) => q.isMultipleBlank), isTrue);
      expect(hard.every((q) => q.correctValues.length == 2), isTrue);
    });

    test('hard answer options are pairs of values', () {
      final questions = SequenceMasterService.generateQuestions(
        difficulty: SequenceMasterDifficulty.hard,
        random: Random(11),
      );

      for (final question in questions) {
        expect(question.correctAnswer, contains('·'));
        for (final option in question.options) {
          expect(option, contains('·'));
        }
      }
    });

    test('same seed produces identical questions', () {
      final first = SequenceMasterService.generateQuestions(
        difficulty: SequenceMasterDifficulty.hard,
        random: Random(2026),
      );
      final second = SequenceMasterService.generateQuestions(
        difficulty: SequenceMasterDifficulty.hard,
        random: Random(2026),
      );

      expect(first.length, second.length);
      for (var index = 0; index < first.length; index++) {
        expect(first[index].id, second[index].id);
        expect(first[index].sequence, second[index].sequence);
        expect(first[index].options, second[index].options);
        expect(
          first[index].correctOptionIndex,
          second[index].correctOptionIndex,
        );
      }
    });

    test('a session never repeats a question id', () {
      final questions = SequenceMasterService.generateQuestions(
        difficulty: SequenceMasterDifficulty.hard,
        random: Random(5),
      );

      expect(questions.map((q) => q.id).toSet().length, questions.length);
    });

    test('excluded ids are avoided when enough fresh questions exist', () {
      final allQuestions = SequenceMasterService.generateQuestions(
        difficulty: SequenceMasterDifficulty.medium,
        count: 16,
        random: Random(8),
      );
      final excluded = allQuestions.take(6).map((q) => q.id).toSet();

      final questions = SequenceMasterService.generateQuestions(
        difficulty: SequenceMasterDifficulty.medium,
        count: 8,
        random: Random(9),
        excludeIds: excluded,
      );

      expect(questions.length, 8);
      expect(questions.map((q) => q.id).toSet().length, 8);
      expect(questions.every((q) => !excluded.contains(q.id)), isTrue);
    });

    test('small sessions still cover every category', () {
      final questions = SequenceMasterService.generateQuestions(
        difficulty: SequenceMasterDifficulty.easy,
        count: 4,
        random: Random(22),
      );

      expect(questions.length, 4);
      expect(
        questions.map((q) => q.category).toSet(),
        equals(SequenceCategory.values.toSet()),
      );
    });

    test('rejects invalid counts', () {
      expect(
        () => SequenceMasterService.generateQuestions(
          difficulty: SequenceMasterDifficulty.easy,
          count: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => SequenceMasterService.generateQuestions(
          difficulty: SequenceMasterDifficulty.easy,
          count: 17,
        ),
        throwsArgumentError,
      );
    });

    test('blank position determines the displayed prompt', () {
      final easy = SequenceMasterService.generateQuestions(
        difficulty: SequenceMasterDifficulty.easy,
        count: 16,
        random: Random(4),
      );
      final hard = SequenceMasterService.generateQuestions(
        difficulty: SequenceMasterDifficulty.hard,
        random: Random(4),
      );

      expect(
        easy.any((q) => q.isNextElement && q.prompt == 'What comes next?'),
        isTrue,
      );
      expect(
        easy.any((q) => !q.isNextElement && q.prompt.contains('completes')),
        isTrue,
      );
      expect(hard.every((q) => q.prompt == 'Fill both missing values'), isTrue);
    });

    test('formatValues renders multi-value answers consistently', () {
      expect(SequenceMasterQuestion.formatValues(['E9', 'F11']), 'E9  ·  F11');
      expect(SequenceMasterQuestion.formatValues(['I']), 'I');
    });
  });
}
