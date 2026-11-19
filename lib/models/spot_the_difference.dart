/// Difficulty level for the Spot the Difference cognitive exercise.
enum SpotDifferenceDifficulty {
  easy(
    label: 'Easy',
    description:
        'Generous 90-second focus window, high-contrast visual discrepancies.',
    timeLimitSeconds: 90,
    scoreBonus: 0.0,
    xpMultiplier: 1.0,
  ),
  medium(
    label: 'Medium',
    description:
        'Balanced 60-second timer testing focused attention and spatial memory.',
    timeLimitSeconds: 60,
    scoreBonus: 10.0,
    xpMultiplier: 1.2,
  ),
  hard(
    label: 'Hard',
    description:
        'Tactical 40-second sprint testing rapid visual discrimination.',
    timeLimitSeconds: 40,
    scoreBonus: 20.0,
    xpMultiplier: 1.5,
  );

  final String label;
  final String description;
  final int timeLimitSeconds;
  final double scoreBonus;
  final double xpMultiplier;

  const SpotDifferenceDifficulty({
    required this.label,
    required this.description,
    required this.timeLimitSeconds,
    required this.scoreBonus,
    required this.xpMultiplier,
  });
}

/// Represents a single verified difference location between two images.
class DifferenceTarget {
  final String id;
  final String description;

  /// Normalized X coordinate (0.0 to 1.0) relative to image width.
  final double x;

  /// Normalized Y coordinate (0.0 to 1.0) relative to image height.
  final double y;

  /// Normalized hitbox radius (relative to image width).
  final double radius;

  const DifferenceTarget({
    required this.id,
    required this.description,
    required this.x,
    required this.y,
    this.radius = 0.075,
  });

  /// Evaluates whether a normalized tap at ([tapX], [tapY]) falls within this target's
  /// hitbox, applying aspect ratio correction so the hitbox is an undistorted circular region.
  bool containsNormalized(
    double tapX,
    double tapY, {
    double aspectRatio = 800 / 600,
  }) {
    final dx = tapX - x;
    final dy = (tapY - y) / aspectRatio;
    final distSq = (dx * dx) + (dy * dy);
    return distSq <= (radius * radius);
  }

  factory DifferenceTarget.fromJson(Map<String, dynamic> json) {
    return DifferenceTarget(
      id: json['id'] as String,
      description: json['description'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      radius: (json['radius'] as num?)?.toDouble() ?? 0.075,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'description': description,
    'x': x,
    'y': y,
    'radius': radius,
  };
}

/// Complete challenge model containing an image pair and verified differences.
class SpotDifferenceChallenge {
  final String id;
  final String title;
  final String themeTag;
  final SpotDifferenceDifficulty difficulty;
  final String description;
  final String imageAssetA;
  final String imageAssetB;
  final int imageWidth;
  final int imageHeight;
  final List<DifferenceTarget> differences;

  const SpotDifferenceChallenge({
    required this.id,
    required this.title,
    required this.themeTag,
    required this.difficulty,
    required this.description,
    required this.imageAssetA,
    required this.imageAssetB,
    this.imageWidth = 800,
    this.imageHeight = 600,
    required this.differences,
  });

  double get aspectRatio => imageWidth / imageHeight;
  int get totalDifferences => differences.length;

  /// Finds the first matching undiscovered difference for a normalized tap coordinate.
  DifferenceTarget? findMatchingDifference({
    required double normX,
    required double normY,
    required Set<String> discoveredIds,
  }) {
    for (final diff in differences) {
      if (discoveredIds.contains(diff.id)) continue;
      if (diff.containsNormalized(normX, normY, aspectRatio: aspectRatio)) {
        return diff;
      }
    }
    return null;
  }
}
