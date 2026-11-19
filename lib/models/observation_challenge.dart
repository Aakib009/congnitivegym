/// Single question model for an Observation Challenge.
class ObservationQuestion {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String? explanation;

  const ObservationQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    this.explanation,
  });

  String get correctAnswer => options[correctOptionIndex];
}

/// Represents an observation exercise challenge with a visual scene and questions.
class ObservationChallenge {
  final String id;
  final String title;
  final String sceneType;
  final String description;
  final String imagePath;
  final int displayDurationSeconds;
  final List<ObservationQuestion> questions;

  const ObservationChallenge({
    required this.id,
    required this.title,
    required this.sceneType,
    required this.description,
    required this.imagePath,
    this.displayDurationSeconds = 8,
    required this.questions,
  });
}
