import 'package:flutter/material.dart';

enum CognitiveCategory {
  memory,
  focus,
  logic,
  agility,
}

extension CognitiveCategoryExtension on CognitiveCategory {
  String get displayName {
    switch (this) {
      case CognitiveCategory.memory:
        return 'Memory Sanctuary';
      case CognitiveCategory.focus:
        return 'Zen Focus';
      case CognitiveCategory.logic:
        return 'Logic Maze';
      case CognitiveCategory.agility:
        return 'Reflex Canopy';
    }
  }

  IconData get icon {
    switch (this) {
      case CognitiveCategory.memory:
        return Icons.psychology_outlined;
      case CognitiveCategory.focus:
        return Icons.center_focus_strong_outlined;
      case CognitiveCategory.logic:
        return Icons.extension_outlined;
      case CognitiveCategory.agility:
        return Icons.speed_outlined;
    }
  }
}

/// Represents a cognitive training exercise/game module.
class CognitiveExercise {
  final String id;
  final String title;
  final String description;
  final CognitiveCategory category;
  final int durationMinutes;
  final int xpReward;
  final String difficultyLevel;
  final bool isUnlocked;

  const CognitiveExercise({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.durationMinutes,
    required this.xpReward,
    required this.difficultyLevel,
    this.isUnlocked = true,
  });

  /// Factory mock list for UI baseline
  static List<CognitiveExercise> getMockExercises() {
    return const [
      CognitiveExercise(
        id: 'ex_05',
        title: 'Story Builder',
        description: 'Connect 3 random words into an original creative narrative.',
        category: CognitiveCategory.logic,
        durationMinutes: 5,
        xpReward: 15,
        difficultyLevel: 'Creative',
      ),
      CognitiveExercise(
        id: 'ex_01',
        title: 'Leaf Sequence Recall',
        description: 'Memorize falling leaf patterns to strengthen working memory.',
        category: CognitiveCategory.memory,
        durationMinutes: 3,
        xpReward: 150,
        difficultyLevel: 'Easy',
      ),
      CognitiveExercise(
        id: 'ex_02',
        title: 'Forest Stream Pulse',
        description: 'Maintain laser focus amidst dynamic ambient distractions.',
        category: CognitiveCategory.focus,
        durationMinutes: 5,
        xpReward: 250,
        difficultyLevel: 'Medium',
      ),
      CognitiveExercise(
        id: 'ex_03',
        title: 'Canopy Circuit',
        description: 'Solve spatial logic puzzles connecting canopy paths.',
        category: CognitiveCategory.logic,
        durationMinutes: 4,
        xpReward: 200,
        difficultyLevel: 'Medium',
      ),
      CognitiveExercise(
        id: 'ex_04',
        title: 'Wind Reflex Trail',
        description: 'Test visual reaction speed on shifting targets.',
        category: CognitiveCategory.agility,
        durationMinutes: 2,
        xpReward: 100,
        difficultyLevel: 'Hard',
      ),
    ];
  }
}
