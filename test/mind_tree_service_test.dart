import 'package:cognitive_gym/services/mind_tree_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MindTreeService Unit Tests', () {
    test('Calculates Stage 1 (Seed) for 0 - 149 points', () {
      final info0 = MindTreeService.instance.getStageInfo(0);
      expect(info0.level, 1);
      expect(info0.name, 'Seed');
      expect(info0.emoji, '🌱');
      expect(info0.requiredPoints, 0);
      expect(info0.nextStageRequiredPoints, 150);
      expect(info0.progressRatio, 0.0);
      expect(info0.isMaxLevel, false);

      final info75 = MindTreeService.instance.getStageInfo(75);
      expect(info75.level, 1);
      expect(info75.progressRatio, 0.5);
    });

    test('Calculates Stage 2 (Sprout) for 150 - 399 points', () {
      final info = MindTreeService.instance.getStageInfo(150);
      expect(info.level, 2);
      expect(info.name, 'Sprout');
      expect(info.emoji, '🌿');
      expect(info.requiredPoints, 150);
      expect(info.nextStageRequiredPoints, 400);
      expect(info.progressRatio, 0.0);
    });

    test('Calculates Stage 3 (Sapling) for 400 points', () {
      final info = MindTreeService.instance.getStageInfo(400);
      expect(info.level, 3);
      expect(info.name, 'Sapling');
      expect(info.emoji, '🍃');
    });

    test('Calculates Stage 4 (Young Tree) for 800 points', () {
      final info = MindTreeService.instance.getStageInfo(800);
      expect(info.level, 4);
      expect(info.name, 'Young Tree');
      expect(info.emoji, '🌳');
    });

    test('Calculates Stage 5 (Growing Oak) for 1500 points', () {
      final info = MindTreeService.instance.getStageInfo(1500);
      expect(info.level, 5);
      expect(info.name, 'Growing Oak');
      expect(info.emoji, '🌲');
    });

    test('Calculates Stage 6 (Strong Oak) for 2500 points', () {
      final info = MindTreeService.instance.getStageInfo(2500);
      expect(info.level, 6);
      expect(info.name, 'Strong Oak');
      expect(info.emoji, '🌴');
    });

    test('Calculates Stage 7 (Wisdom Tree) for 4000 points', () {
      final info = MindTreeService.instance.getStageInfo(4000);
      expect(info.level, 7);
      expect(info.name, 'Wisdom Tree');
      expect(info.emoji, '🌟');
    });

    test('Calculates Stage 8 (Ancient Tree) for 6000 points', () {
      final info = MindTreeService.instance.getStageInfo(6000);
      expect(info.level, 8);
      expect(info.name, 'Ancient Tree');
      expect(info.emoji, '🔥');
    });

    test('Calculates Stage 9 (World Tree) for 9000 points', () {
      final info = MindTreeService.instance.getStageInfo(9000);
      expect(info.level, 9);
      expect(info.name, 'World Tree');
      expect(info.emoji, '💎');
    });

    test('Calculates Stage 10 (Tree of Mastery) for 13000+ points', () {
      final info = MindTreeService.instance.getStageInfo(13000);
      expect(info.level, 10);
      expect(info.name, 'Tree of Mastery');
      expect(info.emoji, '👑');
      expect(info.isMaxLevel, true);
      expect(info.progressRatio, 1.0);
      expect(info.percentageCompleted, 100);

      final infoOverflow = MindTreeService.instance.getStageInfo(25000);
      expect(infoOverflow.level, 10);
      expect(infoOverflow.isMaxLevel, true);
    });

    test('didLevelUp correctly detects stage transitions', () {
      expect(MindTreeService.instance.didLevelUp(100, 149), false);
      expect(MindTreeService.instance.didLevelUp(149, 150), true);
      expect(MindTreeService.instance.didLevelUp(150, 399), false);
      expect(MindTreeService.instance.didLevelUp(399, 400), true);
      expect(MindTreeService.instance.didLevelUp(8999, 9000), true);
      expect(MindTreeService.instance.didLevelUp(12999, 13000), true);
    });
  });
}
