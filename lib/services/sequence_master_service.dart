import 'dart:math';

import '../models/sequence_master.dart';

class SequenceMasterService {
  SequenceMasterService._();

  static List<SequenceMasterQuestion> generateQuestions({
    required SequenceMasterDifficulty difficulty,
    int? count,
    Random? random,
    Set<String> excludeIds = const {},
  }) {
    final seeds = _bank[difficulty]!;
    final targetCount = count ?? difficulty.questionCount;
    if (targetCount < 1 || targetCount > seeds.length) {
      throw ArgumentError.value(
        targetCount,
        'count',
        'must be between 1 and ${seeds.length}',
      );
    }

    final rng = random ?? Random();
    final entries = <_SeedEntry>[
      for (var index = 0; index < seeds.length; index++)
        _SeedEntry(
          id: '${difficulty.name}-${seeds[index].category.name}-$index',
          seed: seeds[index],
        ),
    ];

    final preferred = <_SeedEntry>[
      for (final entry in entries)
        if (!excludeIds.contains(entry.id)) entry,
    ]..shuffle(rng);
    final fallback = <_SeedEntry>[
      for (final entry in entries)
        if (excludeIds.contains(entry.id)) entry,
    ]..shuffle(rng);

    final byCategory = <SequenceCategory, List<_SeedEntry>>{
      for (final category in SequenceCategory.values)
        category: <_SeedEntry>[
          for (final entry in preferred)
            if (entry.seed.category == category) entry,
          for (final entry in fallback)
            if (entry.seed.category == category) entry,
        ],
    };
    final categoryOrder = List<SequenceCategory>.of(SequenceCategory.values)
      ..shuffle(rng);

    final selected = <_SeedEntry>[];
    var addedInPass = true;
    while (selected.length < targetCount && addedInPass) {
      addedInPass = false;
      for (final category in categoryOrder) {
        if (selected.length >= targetCount) break;
        final categorySeeds = byCategory[category]!;
        if (categorySeeds.isEmpty) continue;
        selected.add(categorySeeds.removeAt(0));
        addedInPass = true;
      }
    }

    if (selected.length != targetCount) {
      throw StateError(
        'Sequence Master bank cannot satisfy $targetCount questions.',
      );
    }

    selected.shuffle(rng);
    return List<SequenceMasterQuestion>.unmodifiable(
      selected.map(
        (entry) => _buildQuestion(
          difficulty: difficulty,
          id: entry.id,
          seed: entry.seed,
          random: rng,
        ),
      ),
    );
  }

  static SequenceMasterQuestion _buildQuestion({
    required SequenceMasterDifficulty difficulty,
    required String id,
    required _Seed seed,
    required Random random,
  }) {
    final blankCount = seed.sequence
        .where((token) => token == SequenceMasterQuestion.blankToken)
        .length;
    if (blankCount != difficulty.blankCount) {
      throw StateError('$id must contain ${difficulty.blankCount} blank(s).');
    }
    if (seed.correctValues.length != difficulty.blankCount) {
      throw StateError(
        '$id must provide ${difficulty.blankCount} correct value(s).',
      );
    }
    if (seed.distractors.length != 3) {
      throw StateError('$id must provide exactly three distractors.');
    }
    if (seed.distractors.any(
      (values) => values.length != difficulty.blankCount,
    )) {
      throw StateError('$id has a distractor with the wrong value count.');
    }

    final correctLabel = SequenceMasterQuestion.formatValues(
      seed.correctValues,
    );
    final optionLabels = <String>[correctLabel];
    for (final distractor in seed.distractors) {
      final label = SequenceMasterQuestion.formatValues(distractor);
      if (!optionLabels.contains(label)) optionLabels.add(label);
    }
    if (optionLabels.length != 4) {
      throw StateError('$id must produce four distinct answer options.');
    }
    optionLabels.shuffle(random);

    return SequenceMasterQuestion(
      id: id,
      category: seed.category,
      difficulty: difficulty,
      sequence: List<String>.unmodifiable(seed.sequence),
      correctValues: List<String>.unmodifiable(seed.correctValues),
      options: List<String>.unmodifiable(optionLabels),
      correctOptionIndex: optionLabels.indexOf(correctLabel),
      explanation: seed.explanation,
    );
  }

  static const Map<SequenceMasterDifficulty, List<_Seed>> _bank = {
    SequenceMasterDifficulty.easy: [
      _Seed(
        category: SequenceCategory.alphabet,
        sequence: ['A', 'C', 'E', 'G', '?'],
        correctValues: ['I'],
        distractors: [
          ['H'],
          ['J'],
          ['F'],
        ],
        explanation: 'The letters advance by two: A, C, E, G, I.',
      ),
      _Seed(
        category: SequenceCategory.alphabet,
        sequence: ['B', 'D', 'F', 'H', '?'],
        correctValues: ['J'],
        distractors: [
          ['I'],
          ['K'],
          ['L'],
        ],
        explanation: 'The letters advance by two: B, D, F, H, J.',
      ),
      _Seed(
        category: SequenceCategory.alphabet,
        sequence: ['A', 'C', 'E', '?', 'I'],
        correctValues: ['G'],
        distractors: [
          ['F'],
          ['H'],
          ['D'],
        ],
        explanation: 'The missing letter is G; every letter skips one.',
      ),
      _Seed(
        category: SequenceCategory.alphabet,
        sequence: ['Z', 'X', 'V', 'T', '?'],
        correctValues: ['R'],
        distractors: [
          ['S'],
          ['Q'],
          ['U'],
        ],
        explanation: 'The letters move back two places: Z, X, V, T, R.',
      ),
      _Seed(
        category: SequenceCategory.number,
        sequence: ['2', '4', '6', '8', '?'],
        correctValues: ['10'],
        distractors: [
          ['8'],
          ['12'],
          ['9'],
        ],
        explanation: 'The numbers increase by two: 2, 4, 6, 8, 10.',
      ),
      _Seed(
        category: SequenceCategory.number,
        sequence: ['3', '6', '9', '12', '?'],
        correctValues: ['15'],
        distractors: [
          ['14'],
          ['18'],
          ['12'],
        ],
        explanation: 'The numbers increase by three: 3, 6, 9, 12, 15.',
      ),
      _Seed(
        category: SequenceCategory.number,
        sequence: ['5', '10', '15', '?', '25'],
        correctValues: ['20'],
        distractors: [
          ['18'],
          ['22'],
          ['25'],
        ],
        explanation: 'The numbers count up by five; 20 fits between 15 and 25.',
      ),
      _Seed(
        category: SequenceCategory.number,
        sequence: ['20', '18', '16', '?', '12'],
        correctValues: ['14'],
        distractors: [
          ['15'],
          ['13'],
          ['17'],
        ],
        explanation: 'The numbers decrease by two; 14 fits between 16 and 12.',
      ),
      _Seed(
        category: SequenceCategory.mixed,
        sequence: ['A1', 'B2', 'C3', '?'],
        correctValues: ['D4'],
        distractors: [
          ['C4'],
          ['D5'],
          ['E4'],
        ],
        explanation: 'Both the letter and the number advance by one.',
      ),
      _Seed(
        category: SequenceCategory.mixed,
        sequence: ['A1', 'A2', 'A3', '?'],
        correctValues: ['A4'],
        distractors: [
          ['B3'],
          ['A5'],
          ['B4'],
        ],
        explanation:
            'The letter stays fixed while the number increases by one.',
      ),
      _Seed(
        category: SequenceCategory.mixed,
        sequence: ['A5', 'B4', 'C3', '?'],
        correctValues: ['D2'],
        distractors: [
          ['D4'],
          ['C2'],
          ['E2'],
        ],
        explanation:
            'The letter advances by one while the number decreases by one.',
      ),
      _Seed(
        category: SequenceCategory.mixed,
        sequence: ['2A', '4B', '?', '8D'],
        correctValues: ['6C'],
        distractors: [
          ['6D'],
          ['7C'],
          ['8C'],
        ],
        explanation:
            'The number advances by two and the letter by one; 6C is missing.',
      ),
      _Seed(
        category: SequenceCategory.visual,
        sequence: ['●', '○', '●', '○', '?'],
        correctValues: ['●'],
        distractors: [
          ['○'],
          ['▲'],
          ['■'],
        ],
        explanation:
            'Filled and outline circles alternate; the next shape is filled.',
      ),
      _Seed(
        category: SequenceCategory.visual,
        sequence: ['▲', '▲', '△', '▲', '▲', '?'],
        correctValues: ['△'],
        distractors: [
          ['▲'],
          ['■'],
          ['○'],
        ],
        explanation:
            'Two filled triangles are followed by one outline triangle.',
      ),
      _Seed(
        category: SequenceCategory.visual,
        sequence: ['■', '□', '?', '□', '■'],
        correctValues: ['■'],
        distractors: [
          ['□'],
          ['▲'],
          ['★'],
        ],
        explanation:
            'The squares alternate filled and outline; the blank is filled.',
      ),
      _Seed(
        category: SequenceCategory.visual,
        sequence: ['★', '☆', '☆', '★', '☆', '?'],
        correctValues: ['☆'],
        distractors: [
          ['★'],
          ['●'],
          ['▲'],
        ],
        explanation:
            'The pattern repeats one filled star followed by two outline stars.',
      ),
    ],
    SequenceMasterDifficulty.medium: [
      _Seed(
        category: SequenceCategory.alphabet,
        sequence: ['A', 'C', 'F', 'J', '?'],
        correctValues: ['O'],
        distractors: [
          ['N'],
          ['P'],
          ['M'],
        ],
        explanation: 'The gaps grow by one each time: +2, +3, +4, +5.',
      ),
      _Seed(
        category: SequenceCategory.alphabet,
        sequence: ['Z', 'X', 'U', 'Q', '?'],
        correctValues: ['L'],
        distractors: [
          ['M'],
          ['K'],
          ['N'],
        ],
        explanation: 'The letters move back by 2, 3, 4, then 5 places.',
      ),
      _Seed(
        category: SequenceCategory.alphabet,
        sequence: ['M', 'P', 'S', 'V', '?'],
        correctValues: ['Y'],
        distractors: [
          ['X'],
          ['Z'],
          ['W'],
        ],
        explanation: 'The letters advance by three each time.',
      ),
      _Seed(
        category: SequenceCategory.alphabet,
        sequence: ['A', 'D', 'H', '?', 'S'],
        correctValues: ['M'],
        distractors: [
          ['N'],
          ['L'],
          ['K'],
        ],
        explanation: 'The gaps are +3, +4, +5, +6, so the missing letter is M.',
      ),
      _Seed(
        category: SequenceCategory.number,
        sequence: ['2', '6', '12', '20', '?'],
        correctValues: ['30'],
        distractors: [
          ['28'],
          ['32'],
          ['24'],
        ],
        explanation: 'The differences are 4, 6, 8, then 10.',
      ),
      _Seed(
        category: SequenceCategory.number,
        sequence: ['1', '4', '9', '16', '?'],
        correctValues: ['25'],
        distractors: [
          ['24'],
          ['36'],
          ['20'],
        ],
        explanation: 'These are perfect squares: 1, 4, 9, 16, 25.',
      ),
      _Seed(
        category: SequenceCategory.number,
        sequence: ['3', '9', '27', '81', '?'],
        correctValues: ['243'],
        distractors: [
          ['162'],
          ['216'],
          ['324'],
        ],
        explanation: 'Each number is multiplied by three.',
      ),
      _Seed(
        category: SequenceCategory.number,
        sequence: ['100', '50', '25', '?', '6.25'],
        correctValues: ['12.5'],
        distractors: [
          ['10'],
          ['15'],
          ['12'],
        ],
        explanation: 'Each number is halved; half of 25 is 12.5.',
      ),
      _Seed(
        category: SequenceCategory.mixed,
        sequence: ['A1', 'B3', 'C5', 'D7', '?'],
        correctValues: ['E9'],
        distractors: [
          ['E8'],
          ['F9'],
          ['D9'],
        ],
        explanation: 'The letter advances by one and the number by two.',
      ),
      _Seed(
        category: SequenceCategory.mixed,
        sequence: ['A1', 'B4', 'C9', 'D16', '?'],
        correctValues: ['E25'],
        distractors: [
          ['E20'],
          ['F25'],
          ['E36'],
        ],
        explanation:
            'The letter advances while the number follows the squares.',
      ),
      _Seed(
        category: SequenceCategory.mixed,
        sequence: ['Z1', 'X3', 'V5', '?', 'R9'],
        correctValues: ['T7'],
        distractors: [
          ['T9'],
          ['U7'],
          ['S7'],
        ],
        explanation:
            'The letter moves back two while the number advances by two.',
      ),
      _Seed(
        category: SequenceCategory.mixed,
        sequence: ['A2', 'C4', '?', 'G8'],
        correctValues: ['E6'],
        distractors: [
          ['E8'],
          ['D6'],
          ['F6'],
        ],
        explanation:
            'Both the letter and the number advance by two; E6 is missing.',
      ),
      _Seed(
        category: SequenceCategory.visual,
        sequence: ['●', '▲', '○', '▲', '●', '▲', '?'],
        correctValues: ['○'],
        distractors: [
          ['●'],
          ['▲'],
          ['■'],
        ],
        explanation:
            'The four-shape cycle is circle, triangle, outline circle, triangle.',
      ),
      _Seed(
        category: SequenceCategory.visual,
        sequence: ['■', '□', '★', '□', '■', '□', '?'],
        correctValues: ['★'],
        distractors: [
          ['■'],
          ['□'],
          ['☆'],
        ],
        explanation:
            'The cycle is filled square, outline square, star, outline square.',
      ),
      _Seed(
        category: SequenceCategory.visual,
        sequence: ['○', '○', '▲', '▲', '■', '■', '?'],
        correctValues: ['□'],
        distractors: [
          ['○'],
          ['▲'],
          ['★'],
        ],
        explanation: 'Shapes appear in pairs; outline squares come next.',
      ),
      _Seed(
        category: SequenceCategory.visual,
        sequence: ['●', '▲', '○', '■', '●', '?'],
        correctValues: ['▲'],
        distractors: [
          ['●'],
          ['■'],
          ['○'],
        ],
        explanation:
            'The four-shape cycle repeats: circle, triangle, outline circle, square.',
      ),
    ],
    SequenceMasterDifficulty.hard: [
      _Seed(
        category: SequenceCategory.alphabet,
        sequence: ['A', 'C', 'F', 'J', '?', '?'],
        correctValues: ['O', 'U'],
        distractors: [
          ['O', 'T'],
          ['N', 'U'],
          ['P', 'V'],
        ],
        explanation: 'The gaps grow by one: +2, +3, +4, +5, +6.',
      ),
      _Seed(
        category: SequenceCategory.alphabet,
        sequence: ['Z', 'W', 'T', 'Q', '?', '?'],
        correctValues: ['N', 'K'],
        distractors: [
          ['N', 'J'],
          ['M', 'K'],
          ['O', 'L'],
        ],
        explanation: 'The letters move back by three each time.',
      ),
      _Seed(
        category: SequenceCategory.alphabet,
        sequence: ['A', 'B', 'D', 'E', 'G', 'H', '?', '?'],
        correctValues: ['J', 'K'],
        distractors: [
          ['J', 'L'],
          ['I', 'K'],
          ['K', 'M'],
        ],
        explanation: 'The steps alternate +1, +2; after H come J and K.',
      ),
      _Seed(
        category: SequenceCategory.alphabet,
        sequence: ['A', 'C', 'B', 'D', '?', '?'],
        correctValues: ['C', 'E'],
        distractors: [
          ['C', 'F'],
          ['D', 'E'],
          ['B', 'E'],
        ],
        explanation: 'The pairs are AC, BD, then CE.',
      ),
      _Seed(
        category: SequenceCategory.number,
        sequence: ['2', '6', '12', '20', '?', '?'],
        correctValues: ['30', '42'],
        distractors: [
          ['30', '40'],
          ['28', '42'],
          ['32', '44'],
        ],
        explanation: 'The differences are 4, 6, 8, 10, 12.',
      ),
      _Seed(
        category: SequenceCategory.number,
        sequence: ['1', '3', '7', '15', '?', '?'],
        correctValues: ['31', '63'],
        distractors: [
          ['30', '62'],
          ['31', '61'],
          ['32', '64'],
        ],
        explanation: 'Each number is doubled and increased by one.',
      ),
      _Seed(
        category: SequenceCategory.number,
        sequence: ['1', '4', '9', '16', '?', '?'],
        correctValues: ['25', '36'],
        distractors: [
          ['25', '35'],
          ['24', '36'],
          ['26', '37'],
        ],
        explanation: 'The sequence continues the perfect squares: 25, 36.',
      ),
      _Seed(
        category: SequenceCategory.number,
        sequence: ['3', '4', '7', '11', '18', '?', '?'],
        correctValues: ['29', '47'],
        distractors: [
          ['29', '46'],
          ['28', '47'],
          ['30', '48'],
        ],
        explanation: 'Adding the previous two terms gives 29, then 47.',
      ),
      _Seed(
        category: SequenceCategory.mixed,
        sequence: ['A1', 'B3', 'C5', 'D7', '?', '?'],
        correctValues: ['E9', 'F11'],
        distractors: [
          ['E9', 'F10'],
          ['E8', 'F11'],
          ['F9', 'G11'],
        ],
        explanation: 'The letter advances by one and the number by two.',
      ),
      _Seed(
        category: SequenceCategory.mixed,
        sequence: ['A1', 'B4', 'C9', 'D16', '?', '?'],
        correctValues: ['E25', 'F36'],
        distractors: [
          ['E25', 'F35'],
          ['E24', 'F36'],
          ['E26', 'F37'],
        ],
        explanation: 'The numbers continue the squares: 25, then 36.',
      ),
      _Seed(
        category: SequenceCategory.mixed,
        sequence: ['Z1', 'X3', 'V5', 'T7', '?', '?'],
        correctValues: ['R9', 'P11'],
        distractors: [
          ['R9', 'P10'],
          ['S9', 'P11'],
          ['R8', 'Q11'],
        ],
        explanation:
            'The letter moves back two while the number advances by two.',
      ),
      _Seed(
        category: SequenceCategory.mixed,
        sequence: ['A2', 'C4', 'E6', 'G8', '?', '?'],
        correctValues: ['I10', 'K12'],
        distractors: [
          ['I10', 'J12'],
          ['I9', 'K12'],
          ['H10', 'K12'],
        ],
        explanation: 'Both the letter and the number advance by two.',
      ),
      _Seed(
        category: SequenceCategory.visual,
        sequence: ['●', '▲', '○', '■', '●', '▲', '?', '?'],
        correctValues: ['○', '■'],
        distractors: [
          ['○', '□'],
          ['●', '■'],
          ['○', '▲'],
        ],
        explanation:
            'The four-shape cycle repeats: circle, triangle, outline circle, square.',
      ),
      _Seed(
        category: SequenceCategory.visual,
        sequence: ['●', '●', '○', '▲', '■', '●', '●', '?', '?'],
        correctValues: ['○', '▲'],
        distractors: [
          ['○', '■'],
          ['●', '▲'],
          ['○', '△'],
        ],
        explanation:
            'The pattern repeats two circles, outline circle, triangle, square.',
      ),
      _Seed(
        category: SequenceCategory.visual,
        sequence: ['○', '○', '▲', '▲', '■', '■', '?', '?'],
        correctValues: ['□', '□'],
        distractors: [
          ['□', '○'],
          ['○', '□'],
          ['▲', '□'],
        ],
        explanation:
            'Shapes appear in pairs; the next pair is outline squares.',
      ),
      _Seed(
        category: SequenceCategory.visual,
        sequence: ['●', '▲', '■', '●', '▲', '■', '?', '?'],
        correctValues: ['●', '▲'],
        distractors: [
          ['●', '■'],
          ['▲', '■'],
          ['■', '●'],
        ],
        explanation: 'The three-shape cycle repeats: circle, triangle, square.',
      ),
    ],
  };
}

class _Seed {
  final SequenceCategory category;
  final List<String> sequence;
  final List<String> correctValues;
  final List<List<String>> distractors;
  final String explanation;

  const _Seed({
    required this.category,
    required this.sequence,
    required this.correctValues,
    required this.distractors,
    required this.explanation,
  });
}

class _SeedEntry {
  final String id;
  final _Seed seed;

  const _SeedEntry({required this.id, required this.seed});
}
