/// Represents a single decision option within a critical-thinking scenario.
class ScenarioOption {
  final String id;
  final String title;
  final String description;
  final String consequence;
  final List<String> strengths;
  final List<String> weaknesses;

  const ScenarioOption({
    required this.id,
    required this.title,
    required this.description,
    required this.consequence,
    required this.strengths,
    required this.weaknesses,
  });
}

/// Represents a flagship critical-thinking Scenario Lab dilemma.
class ScenarioModel {
  final String id;
  final String title;
  final String role;
  final String category;
  final String background;
  final String objective;
  final String constraints;
  final List<ScenarioOption> options;
  final int pointsEarned;
  final String? imagePath;

  const ScenarioModel({
    required this.id,
    required this.title,
    required this.role,
    required this.category,
    required this.background,
    required this.objective,
    required this.constraints,
    required this.options,
    this.pointsEarned = 20,
    this.imagePath,
  });
}
