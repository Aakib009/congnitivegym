import 'dart:math';

import '../models/spot_the_difference.dart';

/// Centralized service providing the catalog of Spot the Difference image challenges.
abstract final class SpotTheDifferenceService {
  SpotTheDifferenceService._();

  static const List<SpotDifferenceChallenge> _challenges = [
    SpotDifferenceChallenge(
      id: 'challenge_01',
      title: 'Cozy Mountain Cabin',
      themeTag: 'Alpine Winter',
      difficulty: SpotDifferenceDifficulty.easy,
      description: 'Inspect this peaceful winter cabin under the night stars.',
      imageAssetA: 'assets/images/spot_difference/challenge_01_a.png',
      imageAssetB: 'assets/images/spot_difference/challenge_01_b.png',
      imageWidth: 800,
      imageHeight: 600,
      differences: [
        DifferenceTarget(
          id: 'c1_d1',
          description: 'Smoke puff rising from the stone chimney',
          x: 0.719,
          y: 0.200,
          radius: 0.08,
        ),
        DifferenceTarget(
          id: 'c1_d2',
          description: 'Upstairs dormer window warm light',
          x: 0.538,
          y: 0.430,
          radius: 0.07,
        ),
        DifferenceTarget(
          id: 'c1_d3',
          description: 'Snow cap on tall pine tree peak',
          x: 0.163,
          y: 0.450,
          radius: 0.08,
        ),
        DifferenceTarget(
          id: 'c1_d4',
          description: 'Hanging porch lantern beside doorway',
          x: 0.619,
          y: 0.675,
          radius: 0.06,
        ),
      ],
    ),
    SpotDifferenceChallenge(
      id: 'challenge_02',
      title: 'Orbital Space Station',
      themeTag: 'Deep Space Sci-Fi',
      difficulty: SpotDifferenceDifficulty.medium,
      description: 'Examine this research outpost in low Earth orbit.',
      imageAssetA: 'assets/images/spot_difference/challenge_02_a.png',
      imageAssetB: 'assets/images/spot_difference/challenge_02_b.png',
      imageWidth: 800,
      imageHeight: 600,
      differences: [
        DifferenceTarget(
          id: 'c2_d1',
          description: 'Communications satellite dish on spire',
          x: 0.500,
          y: 0.183,
          radius: 0.07,
        ),
        DifferenceTarget(
          id: 'c2_d2',
          description: 'Green telemetry status indicator on solar wing',
          x: 0.819,
          y: 0.433,
          radius: 0.06,
        ),
        DifferenceTarget(
          id: 'c2_d3',
          description: 'Distant purple spiral galaxy in upper right',
          x: 0.838,
          y: 0.150,
          radius: 0.06,
        ),
        DifferenceTarget(
          id: 'c2_d4',
          description: 'Scout shuttle craft docked on left airlock',
          x: 0.200,
          y: 0.483,
          radius: 0.08,
        ),
      ],
    ),
    SpotDifferenceChallenge(
      id: 'challenge_03',
      title: 'Enchanted Forest',
      themeTag: 'Fantasy Woodland',
      difficulty: SpotDifferenceDifficulty.medium,
      description: 'Discover magical anomalies hidden among ancient roots.',
      imageAssetA: 'assets/images/spot_difference/challenge_03_a.png',
      imageAssetB: 'assets/images/spot_difference/challenge_03_b.png',
      imageWidth: 800,
      imageHeight: 600,
      differences: [
        DifferenceTarget(
          id: 'c3_d1',
          description: 'Cluster of glowing purple mushrooms on riverbank',
          x: 0.225,
          y: 0.767,
          radius: 0.07,
        ),
        DifferenceTarget(
          id: 'c3_d2',
          description: 'Glowing cyan magical rune carved into ancient trunk',
          x: 0.500,
          y: 0.483,
          radius: 0.06,
        ),
        DifferenceTarget(
          id: 'c3_d3',
          description: 'Blue butterfly resting on mossy river stone',
          x: 0.781,
          y: 0.817,
          radius: 0.06,
        ),
        DifferenceTarget(
          id: 'c3_d4',
          description: 'Hanging golden willow lantern on branch',
          x: 0.363,
          y: 0.283,
          radius: 0.07,
        ),
      ],
    ),
    SpotDifferenceChallenge(
      id: 'challenge_04',
      title: 'Underwater Coral Reef',
      themeTag: 'Ocean Marine',
      difficulty: SpotDifferenceDifficulty.easy,
      description:
          'Spot subtle marine variations in this colorful coral haven.',
      imageAssetA: 'assets/images/spot_difference/challenge_04_a.png',
      imageAssetB: 'assets/images/spot_difference/challenge_04_b.png',
      imageWidth: 800,
      imageHeight: 600,
      differences: [
        DifferenceTarget(
          id: 'c4_d1',
          description: 'Orange sea star on the sandy ocean floor',
          x: 0.819,
          y: 0.858,
          radius: 0.07,
        ),
        DifferenceTarget(
          id: 'c4_d2',
          description: 'Golden shell geometric scutes on turtle carapace',
          x: 0.419,
          y: 0.350,
          radius: 0.08,
        ),
        DifferenceTarget(
          id: 'c4_d3',
          description: 'Stream of air bubbles ascending from coral reef',
          x: 0.681,
          y: 0.300,
          radius: 0.06,
        ),
        DifferenceTarget(
          id: 'c4_d4',
          description: 'Striped yellow tang swimming near left reef',
          x: 0.181,
          y: 0.417,
          radius: 0.07,
        ),
      ],
    ),
    SpotDifferenceChallenge(
      id: 'challenge_05',
      title: 'Zen Sanctuary Garden',
      themeTag: 'Japanese Harmony',
      difficulty: SpotDifferenceDifficulty.easy,
      description:
          'Look for peace and subtle shifts in this raked gravel sanctuary.',
      imageAssetA: 'assets/images/spot_difference/challenge_05_a.png',
      imageAssetB: 'assets/images/spot_difference/challenge_05_b.png',
      imageWidth: 800,
      imageHeight: 600,
      differences: [
        DifferenceTarget(
          id: 'c5_d1',
          description: 'Red and white koi fish swimming in garden pond',
          x: 0.750,
          y: 0.742,
          radius: 0.07,
        ),
        DifferenceTarget(
          id: 'c5_d2',
          description: 'Stone pagoda lantern top finial jewel',
          x: 0.300,
          y: 0.383,
          radius: 0.06,
        ),
        DifferenceTarget(
          id: 'c5_d3',
          description: 'Dense pink cherry blossom cluster on branch',
          x: 0.663,
          y: 0.242,
          radius: 0.08,
        ),
        DifferenceTarget(
          id: 'c5_d4',
          description: 'Concentric raked gravel rings around meditation rock',
          x: 0.463,
          y: 0.783,
          radius: 0.08,
        ),
      ],
    ),
    SpotDifferenceChallenge(
      id: 'challenge_06',
      title: 'Sunset City Rooftop',
      themeTag: 'Urban Evening',
      difficulty: SpotDifferenceDifficulty.medium,
      description:
          'Scan this twilight skyscraper terrace overlooking the city.',
      imageAssetA: 'assets/images/spot_difference/challenge_06_a.png',
      imageAssetB: 'assets/images/spot_difference/challenge_06_b.png',
      imageWidth: 800,
      imageHeight: 600,
      differences: [
        DifferenceTarget(
          id: 'c6_d1',
          description: 'Ginger tabby cat perched on brick parapet wall',
          x: 0.850,
          y: 0.583,
          radius: 0.07,
        ),
        DifferenceTarget(
          id: 'c6_d2',
          description: 'Brass telescope optical tube mounted on tripod',
          x: 0.263,
          y: 0.617,
          radius: 0.08,
        ),
        DifferenceTarget(
          id: 'c6_d3',
          description: 'Distant airship cruising across the sunset sky',
          x: 0.638,
          y: 0.183,
          radius: 0.07,
        ),
        DifferenceTarget(
          id: 'c6_d4',
          description: 'Illuminated warm fairy lights along the patio cord',
          x: 0.475,
          y: 0.350,
          radius: 0.06,
        ),
      ],
    ),
    SpotDifferenceChallenge(
      id: 'challenge_07',
      title: 'Artist Loft Studio',
      themeTag: 'Creative Atelier',
      difficulty: SpotDifferenceDifficulty.medium,
      description:
          'Scrutinize this sunlit creative workspace and painting easel.',
      imageAssetA: 'assets/images/spot_difference/challenge_07_a.png',
      imageAssetB: 'assets/images/spot_difference/challenge_07_b.png',
      imageWidth: 800,
      imageHeight: 600,
      differences: [
        DifferenceTarget(
          id: 'c7_d1',
          description: 'Studio wall clock hands orientation',
          x: 0.800,
          y: 0.200,
          radius: 0.06,
        ),
        DifferenceTarget(
          id: 'c7_d2',
          description: 'Crimson oil paint dollop on wooden palette',
          x: 0.344,
          y: 0.758,
          radius: 0.06,
        ),
        DifferenceTarget(
          id: 'c7_d3',
          description: 'Golden sun illustration on the easel landscape canvas',
          x: 0.519,
          y: 0.417,
          radius: 0.07,
        ),
        DifferenceTarget(
          id: 'c7_d4',
          description: 'Sunflower blossom head in window sill vase',
          x: 0.163,
          y: 0.358,
          radius: 0.07,
        ),
      ],
    ),
    SpotDifferenceChallenge(
      id: 'challenge_08',
      title: 'Morning Bakery Cafe',
      themeTag: 'Gourmet Patisserie',
      difficulty: SpotDifferenceDifficulty.hard,
      description:
          'Detect pastry and cafe details outside this artisan bakery.',
      imageAssetA: 'assets/images/spot_difference/challenge_08_a.png',
      imageAssetB: 'assets/images/spot_difference/challenge_08_b.png',
      imageWidth: 800,
      imageHeight: 600,
      differences: [
        DifferenceTarget(
          id: 'c8_d1',
          description: 'Ripe strawberry garnish atop the central display cake',
          x: 0.500,
          y: 0.458,
          radius: 0.06,
        ),
        DifferenceTarget(
          id: 'c8_d2',
          description: 'Steam curls rising from fresh espresso mug',
          x: 0.744,
          y: 0.567,
          radius: 0.06,
        ),
        DifferenceTarget(
          id: 'c8_d3',
          description: 'Striped fabric awning segment color pattern',
          x: 0.281,
          y: 0.150,
          radius: 0.08,
        ),
        DifferenceTarget(
          id: 'c8_d4',
          description: 'Potted lavender blossoms on the cobblestone walkway',
          x: 0.125,
          y: 0.783,
          radius: 0.07,
        ),
      ],
    ),
    SpotDifferenceChallenge(
      id: 'challenge_09',
      title: 'Ancient Library Nook',
      themeTag: 'Scholarly Archive',
      difficulty: SpotDifferenceDifficulty.hard,
      description: 'Investigate leather-bound volumes and brass artifacts.',
      imageAssetA: 'assets/images/spot_difference/challenge_09_a.png',
      imageAssetB: 'assets/images/spot_difference/challenge_09_b.png',
      imageWidth: 800,
      imageHeight: 600,
      differences: [
        DifferenceTarget(
          id: 'c9_d1',
          description: 'Green glass glowing banker lamp shade',
          x: 0.675,
          y: 0.583,
          radius: 0.07,
        ),
        DifferenceTarget(
          id: 'c9_d2',
          description: 'Crimson silk bookmark trailing from top shelf book',
          x: 0.319,
          y: 0.217,
          radius: 0.06,
        ),
        DifferenceTarget(
          id: 'c9_d3',
          description: 'Desk globe sphere mounted inside brass meridian',
          x: 0.819,
          y: 0.617,
          radius: 0.07,
        ),
        DifferenceTarget(
          id: 'c9_d4',
          description: 'Golden star medallion in gothic stained glass arch',
          x: 0.125,
          y: 0.300,
          radius: 0.07,
        ),
      ],
    ),
    SpotDifferenceChallenge(
      id: 'challenge_10',
      title: 'Futuristic Science Lab',
      themeTag: 'Advanced Research',
      difficulty: SpotDifferenceDifficulty.hard,
      description: 'Spot subtle biochemical equipment discrepancies.',
      imageAssetA: 'assets/images/spot_difference/challenge_10_a.png',
      imageAssetB: 'assets/images/spot_difference/challenge_10_b.png',
      imageWidth: 800,
      imageHeight: 600,
      differences: [
        DifferenceTarget(
          id: 'c10_d1',
          description: 'Cyan luminescent reagent inside distillation flask',
          x: 0.381,
          y: 0.617,
          radius: 0.07,
        ),
        DifferenceTarget(
          id: 'c10_d2',
          description: 'Active green sine waveform on digital monitor',
          x: 0.719,
          y: 0.367,
          radius: 0.06,
        ),
        DifferenceTarget(
          id: 'c10_d3',
          description: 'Fluorescent specimen glow on the microscope stage',
          x: 0.219,
          y: 0.683,
          radius: 0.07,
        ),
        DifferenceTarget(
          id: 'c10_d4',
          description: 'Bound atom sphere on ceiling molecular model',
          x: 0.519,
          y: 0.183,
          radius: 0.07,
        ),
      ],
    ),
  ];

  /// Returns all 10 verified image pair challenges.
  static List<SpotDifferenceChallenge> getAllChallenges() =>
      List<SpotDifferenceChallenge>.unmodifiable(_challenges);

  /// Retrieves a specific challenge by ID.
  static SpotDifferenceChallenge getChallengeById(String id) {
    return _challenges.firstWhere(
      (c) => c.id == id,
      orElse: () => _challenges.first,
    );
  }

  /// Filters challenges by difficulty.
  static List<SpotDifferenceChallenge> getChallengesByDifficulty(
    SpotDifferenceDifficulty difficulty,
  ) {
    return _challenges.where((c) => c.difficulty == difficulty).toList();
  }

  /// Selects a random challenge, optionally filtering by difficulty and excluding recently seen challenges.
  static SpotDifferenceChallenge getRandomChallenge({
    SpotDifferenceDifficulty? difficulty,
    Set<String> excludeIds = const {},
    Random? random,
  }) {
    final rng = random ?? Random();
    var pool = _challenges;
    if (difficulty != null) {
      pool = pool.where((c) => c.difficulty == difficulty).toList();
    }
    final fresh = pool.where((c) => !excludeIds.contains(c.id)).toList();
    final effectivePool = fresh.isNotEmpty ? fresh : pool;
    return effectivePool[rng.nextInt(effectivePool.length)];
  }
}
