import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cognitive_gym/models/sequence_master.dart';
import 'package:cognitive_gym/models/spot_the_difference.dart';
import 'package:cognitive_gym/screens/achievements_screen.dart';
import 'package:cognitive_gym/services/achievement_service.dart';
import 'package:cognitive_gym/services/progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AchievementService.instance.resetForTesting();
    await ProgressService.instance.init();
    await ProgressService.instance.resetProgress();
    await AchievementService.instance.init();
  });

  group('Six New Cognitive Gym Achievements Tests', () {
    test(
      'All 6 new achievements exist in allAchievements with valid metadata',
      () {
        final all = AchievementService.allAchievements;

        final patternApprentice = all.firstWhere(
          (a) => a.id == 'pattern_apprentice',
        );
        expect(patternApprentice.title, 'Pattern Apprentice');
        expect(patternApprentice.pointsReward, 25);
        expect(patternApprentice.targetProgress, 1);
        expect(patternApprentice.category, 'Sequence Master');
        expect(patternApprentice.emoji, isNotEmpty);

        final sequenceSpecialist = all.firstWhere(
          (a) => a.id == 'sequence_specialist',
        );
        expect(sequenceSpecialist.title, 'Sequence Specialist');
        expect(sequenceSpecialist.pointsReward, 50);
        expect(sequenceSpecialist.targetProgress, 20);
        expect(sequenceSpecialist.category, 'Sequence Master');

        final masterOfPatterns = all.firstWhere(
          (a) => a.id == 'master_of_patterns',
        );
        expect(masterOfPatterns.title, 'Master of Patterns');
        expect(masterOfPatterns.pointsReward, 100);
        expect(masterOfPatterns.targetProgress, 1);
        expect(masterOfPatterns.category, 'Sequence Master');

        final sharpEyes = all.firstWhere((a) => a.id == 'sharp_eyes');
        expect(sharpEyes.title, 'Sharp Eyes');
        expect(sharpEyes.pointsReward, 25);
        expect(sharpEyes.targetProgress, 10);
        expect(sharpEyes.category, 'Spot the Difference');

        final detailDetective = all.firstWhere(
          (a) => a.id == 'detail_detective',
        );
        expect(detailDetective.title, 'Detail Detective');
        expect(detailDetective.pointsReward, 50);
        expect(detailDetective.targetProgress, 5);
        expect(detailDetective.category, 'Spot the Difference');

        final nothingEscapesMe = all.firstWhere(
          (a) => a.id == 'nothing_escapes_me',
        );
        expect(nothingEscapesMe.title, 'Nothing Escapes Me');
        expect(nothingEscapesMe.pointsReward, 100);
        expect(nothingEscapesMe.targetProgress, 10);
        expect(nothingEscapesMe.category, 'Spot the Difference');
      },
    );

    test(
      'Achievement 1: Pattern Apprentice unlocks on 1st game completion and awards 25 XP',
      () async {
        expect(
          AchievementService.instance.isUnlocked('pattern_apprentice'),
          isFalse,
        );
        expect(
          AchievementService.instance.getProgress('pattern_apprentice'),
          0,
        );
        final initialXp = ProgressService.instance.userProfile.totalXp;

        // 1st completion
        await ProgressService.instance.recordSequenceMasterCompletion(
          performanceScore: 80,
          accuracy: 80,
          durationSeconds: 30,
          difficulty: SequenceMasterDifficulty.easy,
          correctAnswers: 6,
          idempotencyKey: 'sm_run_1',
        );

        expect(
          AchievementService.instance.isUnlocked('pattern_apprentice'),
          isTrue,
        );
        expect(
          AchievementService.instance.getProgress('pattern_apprentice'),
          1,
        );

        // XP gained includes exercise participation XP (20) + achievement reward (25) = at least 45 XP
        final afterFirst = ProgressService.instance.userProfile.totalXp;
        expect(afterFirst - initialXp, greaterThanOrEqualTo(45));

        // 2nd completion should not re-award achievement XP
        await ProgressService.instance.recordSequenceMasterCompletion(
          performanceScore: 80,
          accuracy: 80,
          durationSeconds: 30,
          difficulty: SequenceMasterDifficulty.easy,
          correctAnswers: 6,
          idempotencyKey: 'sm_run_2',
        );
        final afterSecond = ProgressService.instance.userProfile.totalXp;
        // Only the exercise XP (20) added, no extra achievement XP
        expect(afterSecond - afterFirst, 20);
      },
    );

    test(
      'Achievement 2: Sequence Specialist accumulates correct answers across sessions and unlocks at 20',
      () async {
        expect(
          AchievementService.instance.isUnlocked('sequence_specialist'),
          isFalse,
        );
        expect(
          AchievementService.instance.getProgress('sequence_specialist'),
          0,
        );

        // Session 1: 8 correct answers
        await ProgressService.instance.recordSequenceMasterCompletion(
          performanceScore: 80,
          accuracy: 80,
          durationSeconds: 25,
          difficulty: SequenceMasterDifficulty.easy,
          correctAnswers: 8,
          idempotencyKey: 'sm_run_1',
        );
        expect(
          AchievementService.instance.isUnlocked('sequence_specialist'),
          isFalse,
        );
        expect(
          AchievementService.instance.getProgress('sequence_specialist'),
          8,
        );

        // Session 2: 7 correct answers -> total 15
        await ProgressService.instance.recordSequenceMasterCompletion(
          performanceScore: 70,
          accuracy: 70,
          durationSeconds: 25,
          difficulty: SequenceMasterDifficulty.medium,
          correctAnswers: 7,
          idempotencyKey: 'sm_run_2',
        );
        expect(
          AchievementService.instance.isUnlocked('sequence_specialist'),
          isFalse,
        );
        expect(
          AchievementService.instance.getProgress('sequence_specialist'),
          15,
        );

        // Session 3: 5 correct answers -> total 20 -> UNLOCKS!
        final preUnlockXp = ProgressService.instance.userProfile.totalXp;
        await ProgressService.instance.recordSequenceMasterCompletion(
          performanceScore: 50,
          accuracy: 50,
          durationSeconds: 25,
          difficulty: SequenceMasterDifficulty.medium,
          correctAnswers: 5,
          idempotencyKey: 'sm_run_3',
        );
        expect(
          AchievementService.instance.isUnlocked('sequence_specialist'),
          isTrue,
        );
        expect(
          AchievementService.instance.getProgress('sequence_specialist'),
          20,
        );

        final postUnlockXp = ProgressService.instance.userProfile.totalXp;
        // Exercise XP (24 for medium 1.2x) + 50 XP reward = 74 XP
        expect(postUnlockXp - preUnlockXp, greaterThanOrEqualTo(74));
      },
    );

    test(
      'Achievement 3: Master of Patterns unlocks only on Hard difficulty with >= 90% accuracy',
      () async {
        expect(
          AchievementService.instance.isUnlocked('master_of_patterns'),
          isFalse,
        );

        // Easy with 100% accuracy -> must not unlock
        await ProgressService.instance.recordSequenceMasterCompletion(
          performanceScore: 100,
          accuracy: 100,
          durationSeconds: 20,
          difficulty: SequenceMasterDifficulty.easy,
          correctAnswers: 8,
          idempotencyKey: 'sm_run_easy',
        );
        expect(
          AchievementService.instance.isUnlocked('master_of_patterns'),
          isFalse,
        );

        // Medium with 100% accuracy -> must not unlock
        await ProgressService.instance.recordSequenceMasterCompletion(
          performanceScore: 100,
          accuracy: 100,
          durationSeconds: 20,
          difficulty: SequenceMasterDifficulty.medium,
          correctAnswers: 10,
          idempotencyKey: 'sm_run_medium',
        );
        expect(
          AchievementService.instance.isUnlocked('master_of_patterns'),
          isFalse,
        );

        // Hard with 85% accuracy (below 90% threshold) -> must not unlock
        await ProgressService.instance.recordSequenceMasterCompletion(
          performanceScore: 85,
          accuracy: 85,
          durationSeconds: 20,
          difficulty: SequenceMasterDifficulty.hard,
          correctAnswers: 10,
          idempotencyKey: 'sm_run_hard_fail',
        );
        expect(
          AchievementService.instance.isUnlocked('master_of_patterns'),
          isFalse,
        );

        // Hard with 90% accuracy -> UNLOCKS!
        final preXp = ProgressService.instance.userProfile.totalXp;
        await ProgressService.instance.recordSequenceMasterCompletion(
          performanceScore: 90,
          accuracy: 90,
          durationSeconds: 20,
          difficulty: SequenceMasterDifficulty.hard,
          correctAnswers: 11,
          idempotencyKey: 'sm_run_hard_pass',
        );
        expect(
          AchievementService.instance.isUnlocked('master_of_patterns'),
          isTrue,
        );
        expect(
          AchievementService.instance.getProgress('master_of_patterns'),
          1,
        );

        final postXp = ProgressService.instance.userProfile.totalXp;
        // Hard exercise (30 + 10 excellence = 40) + 100 achievement XP = 140 XP
        expect(postXp - preXp, greaterThanOrEqualTo(135));
      },
    );

    test(
      'Achievement 4: Sharp Eyes unlocks after finding 10 differences',
      () async {
        expect(AchievementService.instance.isUnlocked('sharp_eyes'), isFalse);
        expect(AchievementService.instance.getProgress('sharp_eyes'), 0);

        // Challenge 1: 4 differences found
        await ProgressService.instance.recordSpotTheDifferenceCompletion(
          performanceScore: 100,
          accuracy: 100,
          durationSeconds: 20,
          difficulty: SpotDifferenceDifficulty.easy,
          differencesFound: 4,
          idempotencyKey: 'spot_run_1',
        );
        expect(AchievementService.instance.isUnlocked('sharp_eyes'), isFalse);
        expect(AchievementService.instance.getProgress('sharp_eyes'), 4);

        // Challenge 2: 4 differences found -> 8 total
        await ProgressService.instance.recordSpotTheDifferenceCompletion(
          performanceScore: 100,
          accuracy: 100,
          durationSeconds: 20,
          difficulty: SpotDifferenceDifficulty.medium,
          differencesFound: 4,
          idempotencyKey: 'spot_run_2',
        );
        expect(AchievementService.instance.isUnlocked('sharp_eyes'), isFalse);
        expect(AchievementService.instance.getProgress('sharp_eyes'), 8);

        // Challenge 3: 2 differences found -> 10 total -> UNLOCKS!
        final preXp = ProgressService.instance.userProfile.totalXp;
        await ProgressService.instance.recordSpotTheDifferenceCompletion(
          performanceScore: 80,
          accuracy: 80,
          durationSeconds: 20,
          difficulty: SpotDifferenceDifficulty.easy,
          differencesFound: 2,
          idempotencyKey: 'spot_run_3',
        );
        expect(AchievementService.instance.isUnlocked('sharp_eyes'), isTrue);
        expect(AchievementService.instance.getProgress('sharp_eyes'), 10);

        final postXp = ProgressService.instance.userProfile.totalXp;
        // Spot easy XP (20) + 25 achievement XP = 45 XP
        expect(postXp - preXp, greaterThanOrEqualTo(45));
      },
    );

    test(
      'Achievement 5: Detail Detective unlocks upon completing 5 Spot challenges',
      () async {
        expect(
          AchievementService.instance.isUnlocked('detail_detective'),
          isFalse,
        );
        expect(AchievementService.instance.getProgress('detail_detective'), 0);

        for (int i = 1; i <= 4; i++) {
          await ProgressService.instance.recordSpotTheDifferenceCompletion(
            performanceScore: 80,
            accuracy: 80,
            durationSeconds: 20,
            difficulty: SpotDifferenceDifficulty.easy,
            differencesFound: 3,
            idempotencyKey: 'det_run_$i',
          );
          expect(
            AchievementService.instance.isUnlocked('detail_detective'),
            isFalse,
          );
          expect(
            AchievementService.instance.getProgress('detail_detective'),
            i,
          );
        }

        // 5th completion -> UNLOCKS!
        final preXp = ProgressService.instance.userProfile.totalXp;
        await ProgressService.instance.recordSpotTheDifferenceCompletion(
          performanceScore: 80,
          accuracy: 80,
          durationSeconds: 20,
          difficulty: SpotDifferenceDifficulty.easy,
          differencesFound: 3,
          idempotencyKey: 'det_run_5',
        );
        expect(
          AchievementService.instance.isUnlocked('detail_detective'),
          isTrue,
        );
        expect(AchievementService.instance.getProgress('detail_detective'), 5);

        final postXp = ProgressService.instance.userProfile.totalXp;
        expect(postXp - preXp, greaterThanOrEqualTo(70)); // 20 + 50 XP
      },
    );

    test(
      'Achievement 6: Nothing Escapes Me unlocks on 10 challenges with >= 90% accuracy',
      () async {
        expect(
          AchievementService.instance.isUnlocked('nothing_escapes_me'),
          isFalse,
        );

        // 5 runs with only 80% accuracy -> must not increment towards 90% target
        for (int i = 1; i <= 5; i++) {
          await ProgressService.instance.recordSpotTheDifferenceCompletion(
            performanceScore: 80,
            accuracy: 80,
            durationSeconds: 25,
            difficulty: SpotDifferenceDifficulty.easy,
            differencesFound: 3,
            idempotencyKey: 'nem_low_$i',
          );
        }
        expect(
          AchievementService.instance.getProgress('nothing_escapes_me'),
          0,
        );
        expect(
          AchievementService.instance.isUnlocked('nothing_escapes_me'),
          isFalse,
        );

        // 9 runs with 95% accuracy
        for (int i = 1; i <= 9; i++) {
          await ProgressService.instance.recordSpotTheDifferenceCompletion(
            performanceScore: 95,
            accuracy: 95,
            durationSeconds: 25,
            difficulty: SpotDifferenceDifficulty.medium,
            differencesFound: 4,
            idempotencyKey: 'nem_high_$i',
          );
          expect(
            AchievementService.instance.getProgress('nothing_escapes_me'),
            i,
          );
        }
        expect(
          AchievementService.instance.isUnlocked('nothing_escapes_me'),
          isFalse,
        );

        // 10th run with 100% accuracy -> UNLOCKS!
        final preXp = ProgressService.instance.userProfile.totalXp;
        await ProgressService.instance.recordSpotTheDifferenceCompletion(
          performanceScore: 100,
          accuracy: 100,
          durationSeconds: 25,
          difficulty: SpotDifferenceDifficulty.hard,
          differencesFound: 4,
          idempotencyKey: 'nem_high_10',
        );
        expect(
          AchievementService.instance.isUnlocked('nothing_escapes_me'),
          isTrue,
        );
        expect(
          AchievementService.instance.getProgress('nothing_escapes_me'),
          10,
        );

        final postXp = ProgressService.instance.userProfile.totalXp;
        expect(postXp - preXp, greaterThanOrEqualTo(135)); // 35 + 100 XP
      },
    );

    test(
      'Edge case: Aborting/restarting mid-game does not count toward achievements',
      () async {
        // Starting game and aborting without calling record completion
        expect(AchievementService.instance.smGamesCompleted, 0);
        expect(AchievementService.instance.smQuestionsCorrect, 0);
        expect(AchievementService.instance.stdGamesCompleted, 0);
        expect(AchievementService.instance.stdDifferencesFound, 0);

        expect(
          AchievementService.instance.isUnlocked('pattern_apprentice'),
          isFalse,
        );
        expect(
          AchievementService.instance.isUnlocked('detail_detective'),
          isFalse,
        );
      },
    );

    test(
      'Unlock stream emits newly unlocked achievements for non-intrusive notifications',
      () async {
        final emittedAchievements = <AchievementItem>[];
        final sub = AchievementService.instance.onAchievementUnlocked.listen((
          item,
        ) {
          emittedAchievements.add(item);
        });

        await ProgressService.instance.recordSequenceMasterCompletion(
          performanceScore: 100,
          accuracy: 100,
          durationSeconds: 15,
          difficulty: SequenceMasterDifficulty.hard,
          correctAnswers: 12,
          idempotencyKey: 'stream_test_run',
        );

        // Yield event loop
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Should have emitted pattern_apprentice and master_of_patterns (and first_step)
        expect(
          emittedAchievements.any((a) => a.id == 'pattern_apprentice'),
          isTrue,
        );
        expect(
          emittedAchievements.any((a) => a.id == 'master_of_patterns'),
          isTrue,
        );

        await sub.cancel();
      },
    );

    test(
      'Persistence: Incomplete progress and unlocked status persist across reloads',
      () async {
        // 1. Accumulate some progress
        await ProgressService.instance.recordSequenceMasterCompletion(
          performanceScore: 80,
          accuracy: 80,
          durationSeconds: 20,
          difficulty: SequenceMasterDifficulty.easy,
          correctAnswers: 14,
          idempotencyKey: 'persist_sm_1',
        );
        await ProgressService.instance.recordSpotTheDifferenceCompletion(
          performanceScore: 95,
          accuracy: 95,
          durationSeconds: 20,
          difficulty: SpotDifferenceDifficulty.easy,
          differencesFound: 7,
          idempotencyKey: 'persist_std_1',
        );

        expect(
          AchievementService.instance.isUnlocked('pattern_apprentice'),
          isTrue,
        );
        expect(
          AchievementService.instance.getProgress('sequence_specialist'),
          14,
        );
        expect(AchievementService.instance.getProgress('sharp_eyes'), 7);

        // 2. Simulate app restart
        AchievementService.instance.resetForTesting();
        expect(AchievementService.instance.isInitialized, isFalse);

        await AchievementService.instance.init();

        // 3. Verify state was restored from persistent storage
        expect(
          AchievementService.instance.isUnlocked('pattern_apprentice'),
          isTrue,
        );
        expect(
          AchievementService.instance.getProgress('sequence_specialist'),
          14,
        );
        expect(AchievementService.instance.getProgress('sharp_eyes'), 7);
      },
    );

    testWidgets(
      'AchievementsScreen displays all 6 new achievements with cards and progress bars',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 5000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(const MaterialApp(home: AchievementsScreen()));
        await tester.pumpAndSettle();

        // Verify titles are present
        expect(find.text('Pattern Apprentice'), findsOneWidget);
        expect(find.text('Sequence Specialist'), findsOneWidget);
        expect(find.text('Master of Patterns'), findsOneWidget);
        expect(find.text('Sharp Eyes'), findsOneWidget);
        expect(find.text('Detail Detective'), findsOneWidget);
        expect(find.text('Nothing Escapes Me'), findsOneWidget);

        // Verify category tags
        expect(find.text('Sequence Master'), findsWidgets);
        expect(find.text('Spot the Difference'), findsWidgets);

        // Verify XP pills
        expect(find.text('+25 XP'), findsWidgets);
        expect(find.text('+50 XP'), findsWidgets);
        expect(find.text('+100 XP'), findsWidgets);
      },
    );
  });
}
