import 'dart:math';
import '../models/observation_challenge.dart';

/// Predefined repository of Observation Challenges using local image assets.
class ObservationChallengeService {
  ObservationChallengeService._();

  static final Random _random = Random();

  /// Curated list of 9 distinct observation challenges based on local images.
  static final List<ObservationChallenge> _challenges = [
    // 1. Cozy Morning Café
    const ObservationChallenge(
      id: 'obs_cafe',
      title: '☕ Cozy Morning Café',
      sceneType: 'cafe',
      imagePath: 'assets/images/observation/CafeProject.jpeg',
      description: 'Study the counter, tables, pastries, and café layout carefully.',
      displayDurationSeconds: 8,
      questions: [
        ObservationQuestion(
          id: 'q1_1',
          questionText: 'What color is the main espresso machine on the left counter?',
          options: ['Stainless Steel Silver', 'Blue', 'Black', 'Red'],
          correctOptionIndex: 1,
          explanation: 'The espresso machine on the left side of the counter is blue.',
        ),
        ObservationQuestion(
          id: 'q1_2',
          questionText: 'How many menu chalkboards are mounted on the wall above the espresso machine?',
          options: ['One', 'Two', 'Three', 'Four'],
          correctOptionIndex: 1,
          explanation: 'There are 2 wooden-framed menu chalkboards hanging side-by-side.',
        ),
        ObservationQuestion(
          id: 'q1_3',
          questionText: 'What item is displayed on the round wooden table near the window (top right)?',
          options: ['A coffee mug', 'A plate with a cookie', 'A flower vase', 'An open book'],
          correctOptionIndex: 1,
          explanation: 'The small square table near the window has a white plate with a single cookie on top.',
        ),
        ObservationQuestion(
          id: 'q1_4',
          questionText: 'What items are inside the glass pastry display case under the counter?',
          options: [
            'Only croissants',
            'Whole cake, croissants, and a tray of cookies',
            'Muffins and donuts',
            'Sandwiches and fruit'
          ],
          correctOptionIndex: 1,
          explanation: 'The display case shows a sliced cake on the top tier, croissants on the left shelf, and cookies on the right shelf.',
        ),
        ObservationQuestion(
          id: 'q1_5',
          questionText: 'What color are the chairs at the round table sitting on the pattern rug?',
          options: ['Blue and Green', 'Both Yellow', 'Red and Blue', 'Both Black'],
          correctOptionIndex: 0,
          explanation: 'The round table on the rug has one blue chair and one green chair.',
        ),
      ],
    ),

    // 2. Interactive Classroom
    const ObservationChallenge(
      id: 'obs_classroom',
      title: '🏫 Interactive Classroom',
      sceneType: 'classroom',
      imagePath: 'assets/images/observation/ClassRoomProject.jpeg',
      description: 'Memorize the classroom setup, student desks, wall posters, and teacher\'s area.',
      displayDurationSeconds: 8,
      questions: [
        ObservationQuestion(
          id: 'q2_1',
          questionText: 'Where is the red fire extinguisher located in the classroom?',
          options: [
            'Mounted on the left wall next to the whiteboard',
            'Next to the teacher desk',
            'Inside the locker',
            'Under a student desk'
          ],
          correctOptionIndex: 0,
          explanation: 'The red fire extinguisher is mounted on the left wall next to the whiteboard.',
        ),
        ObservationQuestion(
          id: 'q2_2',
          questionText: 'How many educational posters are hanging on the wall between the whiteboard and window?',
          options: ['1', '2', '3', '4'],
          correctOptionIndex: 2,
          explanation: 'There are 3 posters: Solar System, Geometric Shapes, and Water Cycle.',
        ),
        ObservationQuestion(
          id: 'q2_3',
          questionText: 'What color is the teacher\'s swivel office chair?',
          options: ['Black', 'Blue', 'Green', 'Brown'],
          correctOptionIndex: 1,
          explanation: 'The teacher\'s desk chair is blue.',
        ),
        ObservationQuestion(
          id: 'q2_4',
          questionText: 'What object is resting on the right-hand desk in the front row?',
          options: [
            'An open notebook with a blue pen',
            'A purple book',
            'A yellow pencil case',
            'A water bottle'
          ],
          correctOptionIndex: 0,
          explanation: 'The front-right student desk holds a green notebook with a blue pen on it.',
        ),
        ObservationQuestion(
          id: 'q2_5',
          questionText: 'How many total locker doors are in the metal storage cabinet on the far right?',
          options: ['4', '6', '8', '10'],
          correctOptionIndex: 1,
          explanation: 'The metal locker unit has 6 doors (3 green doors on the left column, 3 grey doors on the right column).',
        ),
      ],
    ),

    // 3. Vibrant Children's Park
    const ObservationChallenge(
      id: 'obs_kidspark',
      title: '🛝 Vibrant Children\'s Park',
      sceneType: 'kidspark',
      imagePath: 'assets/images/observation/KidsParkProject.jpeg',
      description: 'Observe the playground equipment, picnic area, fountain, and wildlife.',
      displayDurationSeconds: 8,
      questions: [
        ObservationQuestion(
          id: 'q3_1',
          questionText: 'What items are placed on the red-and-white checkered picnic blanket?',
          options: [
            'A woven basket, water bottle, cup, hat, and apple',
            'A birthday cake and candles',
            'A football and shoes',
            'Only a book'
          ],
          correctOptionIndex: 0,
          explanation: 'The picnic blanket holds a basket, bottle, coffee cup, hat, and an apple nearby.',
        ),
        ObservationQuestion(
          id: 'q3_2',
          questionText: 'How many total ducks are in the circular water fountain?',
          options: ['3', '4', '5', '6'],
          correctOptionIndex: 2,
          explanation: 'The fountain contains 5 ducks (4 yellow ducklings and 1 adult brown duck).',
        ),
        ObservationQuestion(
          id: 'q3_3',
          questionText: 'What colors are the two recycling trash bins placed along the path?',
          options: ['Red and Yellow', 'Green and Blue', 'Black and Grey', 'Orange and Green'],
          correctOptionIndex: 1,
          explanation: 'There are two recycling bins side by side: one green bin and one blue bin.',
        ),
        ObservationQuestion(
          id: 'q3_4',
          questionText: 'What playground equipment is located in the top-right corner?',
          options: [
            'A trampoline',
            'A spiral slide, swing set, and climbing frame',
            'A merry-go-round',
            'A sandbox and see-saw'
          ],
          correctOptionIndex: 1,
          explanation: 'The playground area features a yellow spiral slide, a 2-seat swing set, and a green climbing frame.',
        ),
        ObservationQuestion(
          id: 'q3_5',
          questionText: 'What object is resting on the wooden bench to the right of the fountain?',
          options: ['A blue hat', 'An open book', 'A picnic basket', 'A squirrel'],
          correctOptionIndex: 1,
          explanation: 'An open book is lying on the wooden bench next to the fountain.',
        ),
      ],
    ),

    // 4. Peaceful Study Library
    const ObservationChallenge(
      id: 'obs_library',
      title: '📚 Peaceful Study Library',
      sceneType: 'library',
      imagePath: 'assets/images/observation/LibraryProject.jpeg',
      description: 'Observe the wooden bookshelves, study table, ladder, and desktop accessories.',
      displayDurationSeconds: 8,
      questions: [
        ObservationQuestion(
          id: 'q4_1',
          questionText: 'What object is leaning against the large bookshelf on the left side?',
          options: ['A wooden rolling ladder', 'A guitar', 'An umbrella', 'A floor lamp'],
          correctOptionIndex: 0,
          explanation: 'A tall wooden rolling ladder leans against the left bookshelf.',
        ),
        ObservationQuestion(
          id: 'q4_2',
          questionText: 'What color is the neck desk lamp resting on the main counter beneath the window?',
          options: ['Yellow', 'Blue', 'Green', 'Red'],
          correctOptionIndex: 1,
          explanation: 'A blue flexible neck desk lamp sits on the counter in front of the window.',
        ),
        ObservationQuestion(
          id: 'q4_3',
          questionText: 'What items are placed on the round study table in the foreground?',
          options: [
            'A laptop and mouse',
            'Yellow notebook, magnifying glass, open blue notebook, and pens',
            'A bowl of soup',
            'A chessboard'
          ],
          correctOptionIndex: 1,
          explanation: 'The round table holds a yellow notebook, magnifying glass, blue notebook, and two pens.',
        ),
        ObservationQuestion(
          id: 'q4_4',
          questionText: 'What large indoor plant sits in a pot on the floor in the bottom-right corner?',
          options: ['A cactus', 'A Monstera plant', 'A small bonsai', 'A rose bush'],
          correctOptionIndex: 1,
          explanation: 'A large potted Monstera plant sits in the bottom right corner near the sink.',
        ),
        ObservationQuestion(
          id: 'q4_5',
          questionText: 'What time is displayed on the wall clock above the center window?',
          options: ['10:10', '12:00', '3:30', '6:15'],
          correctOptionIndex: 0,
          explanation: 'The wall clock hands point to 10:10.',
        ),
      ],
    ),

    // 5. Cozy Living Room
    const ObservationChallenge(
      id: 'obs_livingroom',
      title: '🛋️ Cozy Living Room',
      sceneType: 'livingroom',
      imagePath: 'assets/images/observation/LivingRoomProject.jpeg',
      description: 'Examine the sectional sofa, media console, coffee table items, and wall decorations.',
      displayDurationSeconds: 8,
      questions: [
        ObservationQuestion(
          id: 'q5_1',
          questionText: 'What shape is the main living room sofa?',
          options: ['Single recliner', 'L-shaped sectional', 'Straight 2-seater', 'Round beanbag'],
          correctOptionIndex: 1,
          explanation: 'The room features a large blue L-shaped sectional sofa.',
        ),
        ObservationQuestion(
          id: 'q5_2',
          questionText: 'What items are placed on top of the wooden coffee table?',
          options: [
            'Two remotes, a candle, a bowl of stones, and magazines',
            'A laptop and coffee mug',
            'A teapot and cups',
            'A board game'
          ],
          correctOptionIndex: 0,
          explanation: 'The coffee table holds 2 remotes, a white candle in a glass jar, a bowl of stones, and stacked magazines.',
        ),
        ObservationQuestion(
          id: 'q5_3',
          questionText: 'What color is the tall arced floor lamp standing behind the sofa?',
          options: ['Silver', 'Gold / Brass', 'Black', 'White'],
          correctOptionIndex: 1,
          explanation: 'A tall golden/brass arced floor lamp stands on the right behind the sofa.',
        ),
        ObservationQuestion(
          id: 'q5_4',
          questionText: 'What decorative objects sit on top of the media console to the left of the TV?',
          options: ['Two geometric wireframe ornaments', 'Two ceramic apples', 'A clock and trophy', 'A stack of books'],
          correctOptionIndex: 0,
          explanation: 'Two golden geometric wireframe ornaments sit beside the TV.',
        ),
        ObservationQuestion(
          id: 'q5_5',
          questionText: 'What item is mounted on the wall to the far left of the TV unit?',
          options: ['A fire extinguisher', 'A wall clock', 'A mirror', 'A coat rack'],
          correctOptionIndex: 0,
          explanation: 'A red fire extinguisher is mounted on the left wall next to the bookshelf and plant.',
        ),
      ],
    ),

    // 6. Scenic Botanical Garden
    const ObservationChallenge(
      id: 'obs_park',
      title: '🌿 Scenic Botanical Garden',
      sceneType: 'park',
      imagePath: 'assets/images/observation/ParkProject.jpeg',
      description: 'Memorize the greenhouse, stone fountain, bridges, statue, and flower beds.',
      displayDurationSeconds: 8,
      questions: [
        ObservationQuestion(
          id: 'q6_1',
          questionText: 'What glass structure is located in the top-left section of the garden?',
          options: ['A glass greenhouse', 'A wooden gazebo', 'A stone castle', 'A swimming pool'],
          correctOptionIndex: 0,
          explanation: 'A glass greenhouse filled with potted plants stands in the top left corner.',
        ),
        ObservationQuestion(
          id: 'q6_2',
          questionText: 'How many total bridges cross over the stream in this garden?',
          options: ['1', '2', '3', '4'],
          correctOptionIndex: 1,
          explanation: 'There are 2 bridges: a wooden arch footbridge on the left and a stone arch bridge on the top right.',
        ),
        ObservationQuestion(
          id: 'q6_3',
          questionText: 'What stands on a pedestal in the upper path near the stone bridge?',
          options: ['A classical stone statue', 'A bird bath', 'A sundial', 'A wooden lantern'],
          correctOptionIndex: 0,
          explanation: 'A classical stone female statue stands on a pedestal in the upper courtyard.',
        ),
        ObservationQuestion(
          id: 'q6_4',
          questionText: 'What animal statue sits on a rock near the bottom-left corner?',
          options: ['A rabbit', 'A frog', 'A cat', 'A turtle'],
          correctOptionIndex: 0,
          explanation: 'A stone rabbit statue sits on a rock next to a potted fern in the bottom-left area.',
        ),
        ObservationQuestion(
          id: 'q6_5',
          questionText: 'What type of plants are growing in the decorated green pots at the bottom center?',
          options: ['Cacti', 'Roses', 'Sunflowers', 'Ferns'],
          correctOptionIndex: 0,
          explanation: 'Cacti are planted in two decorated green ceramic pots in the bottom center plot.',
        ),
      ],
    ),

    // 7. Focused Study Room
    const ObservationChallenge(
      id: 'obs_studyroom',
      title: '🎧 Focused Study Room',
      sceneType: 'studyroom',
      imagePath: 'assets/images/observation/StudyRoomProject.jpeg',
      description: 'Observe the L-shaped desk setup, bookshelf items, audio gear, and personal belongings.',
      displayDurationSeconds: 8,
      questions: [
        ObservationQuestion(
          id: 'q7_1',
          questionText: 'What audio accessory is resting on the right side of the desk?',
          options: ['Over-ear headphones', 'A Bluetooth speaker', 'A microphone', 'Earbuds in a case'],
          correctOptionIndex: 0,
          explanation: 'A pair of dark grey over-ear headphones rests on the desk near the water bottle.',
        ),
        ObservationQuestion(
          id: 'q7_2',
          questionText: 'What decorative figurine sits on the middle shelf of the wall bookcase?',
          options: ['An owl', 'A cat', 'An eagle', 'A bear'],
          correctOptionIndex: 0,
          explanation: 'A carved wooden owl figurine sits on the middle shelf next to the globe.',
        ),
        ObservationQuestion(
          id: 'q7_3',
          questionText: 'What item is placed on the floor next to the green backpack and right plant?',
          options: ['A pair of blue sneakers', 'A skateboard', 'A soccer ball', 'A guitar case'],
          correctOptionIndex: 0,
          explanation: 'A pair of blue sneakers is placed neatly on the floor next to the green backpack and plant.',
        ),
        ObservationQuestion(
          id: 'q7_4',
          questionText: 'What type of graph is displayed on the open laptop screen?',
          options: ['A line chart graphic', 'A pie chart', 'A bar graph', 'A world map'],
          correctOptionIndex: 0,
          explanation: 'The laptop screen displays a line chart graph with upwards trends.',
        ),
        ObservationQuestion(
          id: 'q7_5',
          questionText: 'What type of clock is sitting on the desk next to the lamp?',
          options: ['A twin-bell vintage alarm clock', 'A digital LED clock', 'A wooden hourglass', 'A wall clock'],
          correctOptionIndex: 0,
          explanation: 'A small black twin-bell vintage alarm clock sits on the desk.',
        ),
      ],
    ),

    // 8. Executive Shared Office
    const ObservationChallenge(
      id: 'obs_workplace',
      title: '🖥️ Executive Shared Office',
      sceneType: 'workplace',
      imagePath: 'assets/images/observation/WorkPlaceProject.jpeg',
      description: 'Study the dual workstation desks, computer monitors, printer, and office accessories.',
      displayDurationSeconds: 8,
      questions: [
        ObservationQuestion(
          id: 'q8_1',
          questionText: 'How many computer workstation setups are on the main L-shaped desk?',
          options: ['One', 'Two', 'Three', 'Four'],
          correctOptionIndex: 1,
          explanation: 'The desk has 2 separate workstation setups (left computer station and right computer station).',
        ),
        ObservationQuestion(
          id: 'q8_2',
          questionText: 'What office device is situated in the corner desk junction between the two workstations?',
          options: ['A blue desktop printer', 'A shredder', 'A scanner', 'A coffee machine'],
          correctOptionIndex: 0,
          explanation: 'A blue desktop printer with white paper inserted sits in the corner connection.',
        ),
        ObservationQuestion(
          id: 'q8_3',
          questionText: 'What colors are the two swivel office chairs?',
          options: ['Blue and Green', 'Both Black', 'Red and Grey', 'Yellow and Blue'],
          correctOptionIndex: 0,
          explanation: 'The left workstation has a blue swivel chair, and the right workstation has a green swivel chair.',
        ),
        ObservationQuestion(
          id: 'q8_4',
          questionText: 'What item sits on top of the green 3-drawer filing cabinet in the bottom right corner?',
          options: ['A wooden tray with a pen holder and notepad', 'A stack of books', 'A desk lamp', 'A printer'],
          correctOptionIndex: 0,
          explanation: 'The top of the green cabinet has a tray containing a pencil holder and a small notepad.',
        ),
        ObservationQuestion(
          id: 'q8_5',
          questionText: 'What pattern design is featured on the floor rug underneath the desk chairs?',
          options: ['A yellow sun design on a blue background', 'Stripes', 'Checkered pattern', 'Floral motif'],
          correctOptionIndex: 0,
          explanation: 'The blue floor rug features a central yellow sun icon design.',
        ),
      ],
    ),

    // 9. Fresh Produce Grocery Market
    const ObservationChallenge(
      id: 'obs_grocery',
      title: '🛒 Fresh Produce Grocery Market',
      sceneType: 'grocery',
      imagePath: 'assets/images/observation/shoppingProject.jpeg',
      description: 'Observe the fruit and vegetable crates, checkout counter, display fridge, and shopping cart.',
      displayDurationSeconds: 8,
      questions: [
        ObservationQuestion(
          id: 'q9_1',
          questionText: 'What items are inside the wire shopping cart in the central aisle?',
          options: [
            'Three rectangular food boxes (blue, yellow, green)',
            'Fresh apples and oranges',
            'Bottles of juice',
            'Canned vegetables'
          ],
          correctOptionIndex: 0,
          explanation: 'The shopping cart contains 3 cereal/food boxes in blue, yellow, and green.',
        ),
        ObservationQuestion(
          id: 'q9_2',
          questionText: 'What items are visible inside the glass-door display refrigerator on the right?',
          options: [
            'Milk cartons, yogurt tubs, and cheese packages',
            'Fresh meat and fish',
            'Soda cans only',
            'Frozen pizzas'
          ],
          correctOptionIndex: 0,
          explanation: 'The display fridge holds milk cartons (blue & yellow), green yogurt tubs, and packaged dairy items.',
        ),
        ObservationQuestion(
          id: 'q9_3',
          questionText: 'What fruit is stacked in a large quantity on the slanted wooden stand near the window?',
          options: ['Yellow bananas', 'Red apples', 'Green grapes', 'Watermelons'],
          correctOptionIndex: 0,
          explanation: 'A large bunch of yellow bananas rests on the inclined wooden stand.',
        ),
        ObservationQuestion(
          id: 'q9_4',
          questionText: 'How many baked goods are inside the clear glass dome display on the counter?',
          options: ['Two (one croissant and one muffin)', 'Three donuts', 'One whole loaf of bread', 'Four cookies'],
          correctOptionIndex: 0,
          explanation: 'The dome display on the counter holds 1 croissant and 1 muffin.',
        ),
        ObservationQuestion(
          id: 'q9_5',
          questionText: 'What colored plastic shopping baskets are stacked on the floor to the left of the shopping cart?',
          options: ['Stacks of green and blue baskets', 'Red and yellow baskets', 'Black baskets', 'White baskets'],
          correctOptionIndex: 0,
          explanation: 'There are two stacks of shopping baskets on the floor: one stack of green baskets and one stack of blue baskets.',
        ),
      ],
    ),
  ];

  /// Returns all available observation challenges.
  static List<ObservationChallenge> getAllChallenges() {
    return List<ObservationChallenge>.from(_challenges);
  }

  /// Selects a random challenge from the repository.
  static ObservationChallenge getRandomChallenge() {
    final index = _random.nextInt(_challenges.length);
    return _challenges[index];
  }

  /// Fetches a challenge by ID or returns the first challenge if not found.
  static ObservationChallenge getChallengeById(String id) {
    return _challenges.firstWhere(
      (c) => c.id == id,
      orElse: () => _challenges.first,
    );
  }
}
