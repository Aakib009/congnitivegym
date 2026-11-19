enum SequenceMasterDifficulty {
  easy(
    label: 'Easy',
    description:
        'Short one-blank patterns, 45 seconds per question, and gentle rules.',
    questionCount: 8,
    secondsPerQuestion: 45,
    blankCount: 1,
    scoreBonus: 0.0,
    xpMultiplier: 1.0,
  ),
  medium(
    label: 'Medium',
    description:
        'Longer sequences with alternating and multiplicative rules, 30 seconds per question.',
    questionCount: 10,
    secondsPerQuestion: 30,
    blankCount: 1,
    scoreBonus: 10.0,
    xpMultiplier: 1.2,
  ),
  hard(
    label: 'Hard',
    description:
        'Dense patterns with two hidden values and 20 seconds per question.',
    questionCount: 12,
    secondsPerQuestion: 20,
    blankCount: 2,
    scoreBonus: 20.0,
    xpMultiplier: 1.5,
  );

  final String label;
  final String description;
  final int questionCount;
  final int secondsPerQuestion;
  final int blankCount;
  final double scoreBonus;
  final double xpMultiplier;

  const SequenceMasterDifficulty({
    required this.label,
    required this.description,
    required this.questionCount,
    required this.secondsPerQuestion,
    required this.blankCount,
    required this.scoreBonus,
    required this.xpMultiplier,
  });
}

enum SequenceCategory {
  alphabet('Alphabet'),
  number('Number'),
  mixed('Mixed'),
  visual('Visual');

  final String label;

  const SequenceCategory(this.label);
}

class SequenceMasterQuestion {
  static const String blankToken = '?';

  final String id;
  final SequenceCategory category;
  final SequenceMasterDifficulty difficulty;

  final List<String> sequence;

  final List<String> correctValues;

  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  const SequenceMasterQuestion({
    required this.id,
    required this.category,
    required this.difficulty,
    required this.sequence,
    required this.correctValues,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });

  int get blankCount => sequence.where((token) => token == blankToken).length;

  bool get isMultipleBlank => blankCount > 1;

  bool get isNextElement =>
      blankCount == 1 && sequence.isNotEmpty && sequence.last == blankToken;

  String get prompt {
    if (isMultipleBlank) return 'Fill both missing values';
    if (isNextElement) return 'What comes next?';
    return 'Which value completes the sequence?';
  }

  String get correctAnswer => options[correctOptionIndex];

  bool isCorrect(int optionIndex) => optionIndex == correctOptionIndex;

  String get sequenceText => sequence.join('  ');

  static String formatValues(List<String> values) => values.join('  ·  ');
}
