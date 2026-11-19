import 'dart:math';

import 'package:cognitive_gym/models/spot_the_difference.dart';
import 'package:cognitive_gym/services/spot_the_difference_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpotTheDifferenceService Catalog Tests', () {
    test('getAllChallenges returns at least 10 playable challenges', () {
      final challenges = SpotTheDifferenceService.getAllChallenges();
      expect(challenges.length, greaterThanOrEqualTo(10));
      expect(challenges.length, equals(10));
    });

    test('every challenge has unique ID and valid asset paths', () {
      final challenges = SpotTheDifferenceService.getAllChallenges();
      final ids = <String>{};

      for (final challenge in challenges) {
        expect(challenge.id, isNotEmpty);
        expect(ids.add(challenge.id), isTrue, reason: 'Duplicate challenge ID');
        expect(challenge.title, isNotEmpty);
        expect(challenge.themeTag, isNotEmpty);
        expect(challenge.description, isNotEmpty);
        expect(
          challenge.imageAssetA,
          startsWith('assets/images/spot_difference/'),
        );
        expect(
          challenge.imageAssetB,
          startsWith('assets/images/spot_difference/'),
        );
        expect(challenge.imageAssetA, endsWith('_a.png'));
        expect(challenge.imageAssetB, endsWith('_b.png'));
        expect(challenge.imageWidth, greaterThan(0));
        expect(challenge.imageHeight, greaterThan(0));
        expect(challenge.aspectRatio, closeTo(800 / 600, 0.01));
      }
    });

    test(
      'every challenge has multiple verified differences with valid normalized coordinates',
      () {
        final challenges = SpotTheDifferenceService.getAllChallenges();

        for (final challenge in challenges) {
          expect(challenge.differences.length, greaterThanOrEqualTo(3));
          expect(
            challenge.totalDifferences,
            equals(challenge.differences.length),
          );

          final diffIds = <String>{};
          for (final diff in challenge.differences) {
            expect(diff.id, isNotEmpty);
            expect(
              diffIds.add(diff.id),
              isTrue,
              reason: 'Duplicate difference ID in ${challenge.id}',
            );
            expect(diff.description, isNotEmpty);
            expect(diff.x, inExclusiveRange(0.0, 1.0));
            expect(diff.y, inExclusiveRange(0.0, 1.0));
            expect(diff.radius, inExclusiveRange(0.02, 0.20));

            // DifferenceTarget.containsNormalized checks
            expect(
              diff.containsNormalized(
                diff.x,
                diff.y,
                aspectRatio: challenge.aspectRatio,
              ),
              isTrue,
              reason: 'Direct center hit must be recognized',
            );
            expect(
              diff.containsNormalized(
                diff.x + 0.01,
                diff.y + 0.01,
                aspectRatio: challenge.aspectRatio,
              ),
              isTrue,
              reason: 'Close tap within radius must be recognized',
            );
            expect(
              diff.containsNormalized(
                (diff.x + 0.5) % 1.0,
                (diff.y + 0.5) % 1.0,
                aspectRatio: challenge.aspectRatio,
              ),
              isFalse,
              reason: 'Distant tap must not register as hit',
            );
          }
        }
      },
    );

    test(
      'findMatchingDifference detects target and respects discovered set',
      () {
        final challenge = SpotTheDifferenceService.getChallengeById(
          'challenge_01',
        );
        final firstDiff = challenge.differences.first;

        final discovered = <String>{};
        final hit1 = challenge.findMatchingDifference(
          normX: firstDiff.x,
          normY: firstDiff.y,
          discoveredIds: discovered,
        );

        expect(hit1, isNotNull);
        expect(hit1!.id, equals(firstDiff.id));

        // Mark as discovered and tap same location again
        discovered.add(firstDiff.id);
        final hit2 = challenge.findMatchingDifference(
          normX: firstDiff.x,
          normY: firstDiff.y,
          discoveredIds: discovered,
        );

        expect(
          hit2,
          isNull,
          reason: 'Already discovered difference cannot be re-detected',
        );
      },
    );

    test('getChallengeById returns matching challenge or fallback', () {
      final c1 = SpotTheDifferenceService.getChallengeById('challenge_01');
      expect(c1.id, equals('challenge_01'));
      expect(c1.title, equals('Cozy Mountain Cabin'));

      final fallback = SpotTheDifferenceService.getChallengeById(
        'non_existent',
      );
      expect(fallback.id, equals('challenge_01'));
    });

    test('getChallengesByDifficulty filters correctly', () {
      final easy = SpotTheDifferenceService.getChallengesByDifficulty(
        SpotDifferenceDifficulty.easy,
      );
      final medium = SpotTheDifferenceService.getChallengesByDifficulty(
        SpotDifferenceDifficulty.medium,
      );
      final hard = SpotTheDifferenceService.getChallengesByDifficulty(
        SpotDifferenceDifficulty.hard,
      );

      expect(easy, isNotEmpty);
      expect(medium, isNotEmpty);
      expect(hard, isNotEmpty);
      expect(
        easy.every((c) => c.difficulty == SpotDifferenceDifficulty.easy),
        isTrue,
      );
      expect(
        medium.every((c) => c.difficulty == SpotDifferenceDifficulty.medium),
        isTrue,
      );
      expect(
        hard.every((c) => c.difficulty == SpotDifferenceDifficulty.hard),
        isTrue,
      );
      expect(easy.length + medium.length + hard.length, equals(10));
    });

    test('getRandomChallenge excludes recent IDs when possible', () {
      final c1 = SpotTheDifferenceService.getRandomChallenge(
        random: Random(42),
      );
      expect(c1.id, isNotEmpty);

      final c2 = SpotTheDifferenceService.getRandomChallenge(
        excludeIds: {c1.id},
        random: Random(42),
      );
      expect(c2.id, isNot(equals(c1.id)));
    });
  });
}
