import 'dart:math';
import 'package:flutter/material.dart';
import '../models/rank_model.dart';

/// Flat, geometric, vector-rendered rank emblem for Cognitive Gym.
/// Replaces emojis with authentic competitive gaming insignia.
class RankEmblem extends StatelessWidget {
  final CognitiveRankTier tier;
  final double size;
  final bool showLabel;

  const RankEmblem({
    super.key,
    required this.tier,
    this.size = 40.0,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final rank = CognitiveRank.allRanks.firstWhere(
      (r) => r.tier == tier,
      orElse: () => CognitiveRank.allRanks.first,
    );

    final emblem = CustomPaint(
      size: Size(size, size),
      painter: _RankEmblemPainter(
        tier: tier,
        primaryColor: rank.primaryColor,
        secondaryColor: rank.secondaryColor,
      ),
    );

    if (!showLabel) return emblem;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        emblem,
        const SizedBox(height: 4),
        Text(
          rank.name.toUpperCase(),
          style: TextStyle(
            color: rank.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: (size * 0.22).clamp(9.0, 14.0),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _RankEmblemPainter extends CustomPainter {
  final CognitiveRankTier tier;
  final Color primaryColor;
  final Color secondaryColor;

  _RankEmblemPainter({
    required this.tier,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cy = h / 2;

    final fillPaint = Paint()
      ..color = primaryColor.withAlpha(45)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = (w * 0.055).clamp(1.5, 3.5)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.miter;

    final innerPaint = Paint()
      ..color = secondaryColor
      ..strokeWidth = (w * 0.04).clamp(1.0, 2.5)
      ..style = PaintingStyle.stroke;

    switch (tier) {
      case CognitiveRankTier.bronze:
        // Shield + Single Bold Chevron
        final shield = Path()
          ..moveTo(cx, h * 0.12)
          ..lineTo(w * 0.85, h * 0.28)
          ..lineTo(w * 0.80, h * 0.65)
          ..lineTo(cx, h * 0.90)
          ..lineTo(w * 0.20, h * 0.65)
          ..lineTo(w * 0.15, h * 0.28)
          ..close();
        canvas.drawPath(shield, fillPaint);
        canvas.drawPath(shield, strokePaint);

        final chevron = Path()
          ..moveTo(w * 0.32, h * 0.46)
          ..lineTo(cx, h * 0.60)
          ..lineTo(w * 0.68, h * 0.46);
        canvas.drawPath(chevron, strokePaint);
        break;

      case CognitiveRankTier.silver:
        // Angular Crest + Dual Chevrons
        final crest = Path()
          ..moveTo(cx, h * 0.10)
          ..lineTo(w * 0.88, h * 0.30)
          ..lineTo(w * 0.76, h * 0.88)
          ..lineTo(cx, h * 0.74)
          ..lineTo(w * 0.24, h * 0.88)
          ..lineTo(w * 0.12, h * 0.30)
          ..close();
        canvas.drawPath(crest, fillPaint);
        canvas.drawPath(crest, strokePaint);

        final chev1 = Path()
          ..moveTo(w * 0.30, h * 0.38)
          ..lineTo(cx, h * 0.50)
          ..lineTo(w * 0.70, h * 0.38);
        final chev2 = Path()
          ..moveTo(w * 0.32, h * 0.52)
          ..lineTo(cx, h * 0.64)
          ..lineTo(w * 0.68, h * 0.52);
        canvas.drawPath(chev1, strokePaint);
        canvas.drawPath(chev2, innerPaint);
        break;

      case CognitiveRankTier.gold:
        // 8-Pointed Star Medallion with Radiant Core
        final star = Path();
        for (int i = 0; i < 8; i++) {
          final angle = i * pi / 4 - pi / 2;
          final r = i.isEven ? w * 0.44 : w * 0.26;
          final px = cx + r * cos(angle);
          final py = cy + r * sin(angle);
          if (i == 0) {
            star.moveTo(px, py);
          } else {
            star.lineTo(px, py);
          }
        }
        star.close();
        canvas.drawPath(star, fillPaint);
        canvas.drawPath(star, strokePaint);

        // Core diamond
        final core = Path()
          ..moveTo(cx, cy - h * 0.15)
          ..lineTo(cx + w * 0.15, cy)
          ..lineTo(cx, cy + h * 0.15)
          ..lineTo(cx - w * 0.15, cy)
          ..close();
        canvas.drawPath(core, Paint()..color = primaryColor..style = PaintingStyle.fill);
        break;

      case CognitiveRankTier.platinum:
        // Faceted Vanguard Shield with Reinforced Spine
        final vanguard = Path()
          ..moveTo(cx, h * 0.08)
          ..lineTo(w * 0.90, h * 0.24)
          ..lineTo(w * 0.80, h * 0.72)
          ..lineTo(cx, h * 0.94)
          ..lineTo(w * 0.20, h * 0.72)
          ..lineTo(w * 0.10, h * 0.24)
          ..close();
        canvas.drawPath(vanguard, fillPaint);
        canvas.drawPath(vanguard, strokePaint);

        // Vertical central spine & cross facets
        canvas.drawLine(Offset(cx, h * 0.12), Offset(cx, h * 0.88), strokePaint);
        canvas.drawLine(Offset(w * 0.22, h * 0.44), Offset(w * 0.78, h * 0.44), innerPaint);
        break;

      case CognitiveRankTier.crystal:
        // Prismatic Hexagon with Refraction Facets
        final hex = Path();
        for (int i = 0; i < 6; i++) {
          final angle = i * pi / 3 - pi / 6;
          final px = cx + (w * 0.43) * cos(angle);
          final py = cy + (h * 0.43) * sin(angle);
          if (i == 0) {
            hex.moveTo(px, py);
          } else {
            hex.lineTo(px, py);
          }
        }
        hex.close();
        canvas.drawPath(hex, fillPaint);
        canvas.drawPath(hex, strokePaint);

        // Internal prism facets
        for (int i = 0; i < 6; i += 2) {
          final angle = i * pi / 3 - pi / 6;
          canvas.drawLine(
            Offset(cx, cy),
            Offset(cx + (w * 0.43) * cos(angle), cy + (h * 0.43) * sin(angle)),
            innerPaint,
          );
        }
        break;

      case CognitiveRankTier.diamond:
        // Radiant-Cut Diamond Crest with Twin Lateral Blades
        final diamond = Path()
          ..moveTo(cx, h * 0.08)
          ..lineTo(w * 0.86, h * 0.38)
          ..lineTo(cx, h * 0.92)
          ..lineTo(w * 0.14, h * 0.38)
          ..close();
        canvas.drawPath(diamond, fillPaint);
        canvas.drawPath(diamond, strokePaint);

        final facetLine1 = Path()
          ..moveTo(w * 0.28, h * 0.38)
          ..lineTo(cx, h * 0.20)
          ..lineTo(w * 0.72, h * 0.38);
        canvas.drawPath(facetLine1, innerPaint);
        canvas.drawLine(Offset(cx, h * 0.20), Offset(cx, h * 0.84), strokePaint);
        break;

      case CognitiveRankTier.master:
        // Crowned Solar Core Emblem
        final base = Path()
          ..moveTo(w * 0.20, h * 0.78)
          ..lineTo(w * 0.80, h * 0.78)
          ..lineTo(w * 0.88, h * 0.32)
          ..lineTo(w * 0.68, h * 0.48)
          ..lineTo(cx, h * 0.18)
          ..lineTo(w * 0.32, h * 0.48)
          ..lineTo(w * 0.12, h * 0.32)
          ..close();
        canvas.drawPath(base, fillPaint);
        canvas.drawPath(base, strokePaint);

        // Solar core circle
        canvas.drawCircle(Offset(cx, h * 0.58), w * 0.16, Paint()..color = primaryColor..style = PaintingStyle.fill);
        break;

      case CognitiveRankTier.grandmaster:
        // Dual Orbital Rings with Apex Crown
        canvas.drawCircle(Offset(cx, cy), w * 0.44, strokePaint);
        canvas.drawCircle(Offset(cx, cy), w * 0.32, innerPaint);

        // Transcendent apex crown
        final apex = Path()
          ..moveTo(w * 0.24, h * 0.66)
          ..lineTo(w * 0.76, h * 0.66)
          ..lineTo(w * 0.84, h * 0.32)
          ..lineTo(w * 0.64, h * 0.46)
          ..lineTo(cx, h * 0.14)
          ..lineTo(w * 0.36, h * 0.46)
          ..lineTo(w * 0.16, h * 0.32)
          ..close();
        canvas.drawPath(apex, fillPaint);
        canvas.drawPath(apex, strokePaint);

        // Central radiance gem
        canvas.drawCircle(Offset(cx, cy), w * 0.13, Paint()..color = primaryColor..style = PaintingStyle.fill);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _RankEmblemPainter oldDelegate) {
    return oldDelegate.tier != tier ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}
