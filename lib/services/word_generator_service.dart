import 'dart:math';

/// Service providing randomized word selection for Story Builder challenges.
class WordGeneratorService {
  WordGeneratorService._();

  static final Random _random = Random();

  /// Curated pool of 70+ evocative, nature-inspired, abstract, and object words.
  static const List<String> wordPool = [
    'Whisper',
    'Lantern',
    'Moss',
    'Compass',
    'Echo',
    'Starlight',
    'River',
    'Shadow',
    'Feather',
    'Crystal',
    'Ember',
    'Horizon',
    'Breeze',
    'Thistle',
    'Harmony',
    'Solitude',
    'Summit',
    'Orchard',
    'Tapestry',
    'Labyrinth',
    'Dewdrop',
    'Pinecone',
    'Mirage',
    'Velocity',
    'Symphony',
    'Tide',
    'Eclipse',
    'Pebble',
    'Velvet',
    'Spectrum',
    'Anchor',
    'Cascade',
    'Blossom',
    'Driftwood',
    'Monolith',
    'Nebula',
    'Fossil',
    'Origami',
    'Resonance',
    'Twilight',
    'Banyan',
    'Zephyr',
    'Aurora',
    'Cathedral',
    'Cello',
    'Glacier',
    'Hourglass',
    'Ivory',
    'Jubilee',
    'Kaleidoscope',
    'Lighthouse',
    'Meadow',
    'Nectar',
    'Oasis',
    'Pendulum',
    'Quiver',
    'Radiance',
    'Sanctuary',
    'Telescope',
    'Umbrella',
    'Vortex',
    'Willow',
    'Zenith',
    'Amber',
    'Bramble',
    'Chime',
    'Dune',
    'Flint',
    'Grotto',
    'Hollow',
  ];

  /// Generates a list of [count] unique, randomly selected words from [wordPool].
  static List<String> getRandomWords({int count = 3}) {
    if (count >= wordPool.length) {
      return List<String>.from(wordPool);
    }

    final List<String> available = List<String>.from(wordPool);
    final List<String> selected = [];

    for (int i = 0; i < count; i++) {
      final randomIndex = _random.nextInt(available.length);
      selected.add(available.removeAt(randomIndex));
    }

    return selected;
  }
}
