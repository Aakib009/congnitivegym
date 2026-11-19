/// Configuration for each of the 11 Mind Tree visual levels (0-10).
///
/// Each level defines visual properties that the CustomPainter uses to render
/// the tree at that progression stage. This keeps rendering logic separate
/// from data definitions.
class MindTreeLevelConfig {
  final int level;
  final String title;
  final String description;
  final bool showSeed;
  final bool showRoots;
  final bool showTrunk;
  final bool showBranches;
  final bool showFoliage;
  final bool showFlowers;
  final bool showFruit;
  final double trunkHeight;
  final double trunkWidth;
  final int branchCount;
  final double foliageRadius;
  final int fruitCount;
  final double sparkleIntensity;

  const MindTreeLevelConfig({
    required this.level,
    required this.title,
    required this.description,
    this.showSeed = false,
    this.showRoots = false,
    this.showTrunk = false,
    this.showBranches = false,
    this.showFoliage = false,
    this.showFlowers = false,
    this.showFruit = false,
    this.trunkHeight = 0.0,
    this.trunkWidth = 0.0,
    this.branchCount = 0,
    this.foliageRadius = 0.0,
    this.fruitCount = 0,
    this.sparkleIntensity = 0.0,
  });

  /// All 11 Mind Tree levels (0 through 10).
  static const List<MindTreeLevelConfig> levels = [
    MindTreeLevelConfig(
      level: 0,
      title: 'Seed',
      description: 'A dormant seed planted in fertile ground, waiting for the first spark of cognitive energy.',
      showSeed: true,
      sparkleIntensity: 0.2,
    ),
    MindTreeLevelConfig(
      level: 1,
      title: 'Germinating',
      description: 'The seed awakens. A tiny crack appears as roots begin to seek nourishment.',
      showSeed: true,
      showRoots: true,
      trunkHeight: 0.05,
      trunkWidth: 0.02,
      sparkleIntensity: 0.3,
    ),
    MindTreeLevelConfig(
      level: 2,
      title: 'Sprout',
      description: 'A delicate green sprout emerges, reaching toward the light with newfound determination.',
      showRoots: true,
      showTrunk: true,
      showFoliage: true,
      trunkHeight: 0.15,
      trunkWidth: 0.03,
      foliageRadius: 0.06,
      sparkleIntensity: 0.4,
    ),
    MindTreeLevelConfig(
      level: 3,
      title: 'Young Sapling',
      description: 'The sapling gains strength. First branches stretch outward, leaves begin to unfurl.',
      showRoots: true,
      showTrunk: true,
      showBranches: true,
      showFoliage: true,
      trunkHeight: 0.25,
      trunkWidth: 0.04,
      branchCount: 2,
      foliageRadius: 0.10,
      sparkleIntensity: 0.5,
    ),
    MindTreeLevelConfig(
      level: 4,
      title: 'Small Tree',
      description: 'A sturdy young tree takes shape. Branches multiply and foliage becomes fuller.',
      showRoots: true,
      showTrunk: true,
      showBranches: true,
      showFoliage: true,
      trunkHeight: 0.35,
      trunkWidth: 0.05,
      branchCount: 3,
      foliageRadius: 0.15,
      sparkleIntensity: 0.6,
    ),
    MindTreeLevelConfig(
      level: 5,
      title: 'Growing Tree',
      description: 'The tree grows taller and stronger. Its canopy expands with vibrant green leaves.',
      showRoots: true,
      showTrunk: true,
      showBranches: true,
      showFoliage: true,
      showFlowers: true,
      trunkHeight: 0.42,
      trunkWidth: 0.06,
      branchCount: 4,
      foliageRadius: 0.20,
      sparkleIntensity: 0.7,
    ),
    MindTreeLevelConfig(
      level: 6,
      title: 'Mature Tree',
      description: 'A magnificent tree stands tall. Its canopy provides shade and shelter for all beneath.',
      showRoots: true,
      showTrunk: true,
      showBranches: true,
      showFoliage: true,
      showFlowers: true,
      trunkHeight: 0.48,
      trunkWidth: 0.07,
      branchCount: 5,
      foliageRadius: 0.25,
      sparkleIntensity: 0.8,
    ),
    MindTreeLevelConfig(
      level: 7,
      title: 'Full Tree',
      description: 'The tree reaches its full height. Every branch is strong, every leaf is lush.',
      showRoots: true,
      showTrunk: true,
      showBranches: true,
      showFoliage: true,
      showFlowers: true,
      trunkHeight: 0.52,
      trunkWidth: 0.08,
      branchCount: 6,
      foliageRadius: 0.30,
      sparkleIntensity: 0.85,
    ),
    MindTreeLevelConfig(
      level: 8,
      title: 'Flourishing',
      description: 'The tree flourishes with exceptional vitality. Flowers bloom in abundance.',
      showRoots: true,
      showTrunk: true,
      showBranches: true,
      showFoliage: true,
      showFlowers: true,
      trunkHeight: 0.55,
      trunkWidth: 0.09,
      branchCount: 7,
      foliageRadius: 0.34,
      sparkleIntensity: 0.9,
    ),
    MindTreeLevelConfig(
      level: 9,
      title: 'Fruitful',
      description: 'The tree bears its first fruit. Hard work and dedication begin to yield sweet rewards.',
      showRoots: true,
      showTrunk: true,
      showBranches: true,
      showFoliage: true,
      showFlowers: true,
      showFruit: true,
      trunkHeight: 0.57,
      trunkWidth: 0.09,
      branchCount: 8,
      foliageRadius: 0.36,
      fruitCount: 3,
      sparkleIntensity: 0.95,
    ),
    MindTreeLevelConfig(
      level: 10,
      title: 'Fully Grown',
      description: 'The Mind Tree reaches its ultimate form. A majestic, fruit-laden symbol of cognitive mastery.',
      showRoots: true,
      showTrunk: true,
      showBranches: true,
      showFoliage: true,
      showFlowers: true,
      showFruit: true,
      trunkHeight: 0.60,
      trunkWidth: 0.10,
      branchCount: 8,
      foliageRadius: 0.40,
      fruitCount: 5,
      sparkleIntensity: 1.0,
    ),
  ];

  /// Returns the config for the given [level], clamped to 0-10.
  static MindTreeLevelConfig forLevel(int level) {
    final clamped = level.clamp(0, 10);
    return levels[clamped];
  }

  /// Skill-to-tree-part mapping labels (for display, not rendering).
  static const Map<String, String> skillMappings = {
    'memory': 'Leaves',
    'observation': 'Branches',
    'critical_thinking': 'Trunk',
    'creativity': 'Flowers',
    'decision_making': 'Fruit',
  };
}
