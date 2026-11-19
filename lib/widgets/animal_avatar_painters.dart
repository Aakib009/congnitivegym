import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/animal_avatar.dart';

/// Central dispatcher for rendering custom vector illustrations of all 7 animal avatars.
class AnimalAvatarPainter {
  AnimalAvatarPainter._();

  static CustomPainter forId(String avatarId) {
    final normalized = AppAvatars.normalize(avatarId);
    switch (normalized) {
      case AppAvatars.elephant:
        return const ElephantPainter();
      case AppAvatars.tiger:
        return const TigerPainter();
      case AppAvatars.lion:
        return const LionPainter();
      case AppAvatars.rabbit:
        return const RabbitPainter();
      case AppAvatars.bear:
        return const BearPainter();
      case AppAvatars.cat:
        return const CatPainter();
      case AppAvatars.raccoon:
      default:
        return const RaccoonPainter();
    }
  }
}

/// 1. RACCOON PAINTER (Matching existing app mascot style)
class RaccoonPainter extends CustomPainter {
  const RaccoonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final width = size.width;
    final height = size.height;

    // 1. Background Fill (Pastel Mint)
    final bgPaint = Paint()
      ..color = const Color(0xFFE2ECE9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, width / 2, bgPaint);

    // 2. Ears
    final outerEarPaint = Paint()
      ..color = const Color(0xFF5A6572)
      ..style = PaintingStyle.fill;
    final innerEarPaint = Paint()
      ..color = const Color(0xFFFFC0CB)
      ..style = PaintingStyle.fill;

    // Left Ear
    final leftEarPath = Path()
      ..moveTo(width * 0.22, height * 0.38)
      ..quadraticBezierTo(width * 0.12, height * 0.12, width * 0.36, height * 0.20)
      ..close();
    canvas.drawPath(leftEarPath, outerEarPaint);

    final leftInnerEar = Path()
      ..moveTo(width * 0.24, height * 0.34)
      ..quadraticBezierTo(width * 0.17, height * 0.18, width * 0.34, height * 0.23)
      ..close();
    canvas.drawPath(leftInnerEar, innerEarPaint);

    // Right Ear
    final rightEarPath = Path()
      ..moveTo(width * 0.78, height * 0.38)
      ..quadraticBezierTo(width * 0.88, height * 0.12, width * 0.64, height * 0.20)
      ..close();
    canvas.drawPath(rightEarPath, outerEarPaint);

    final rightInnerEar = Path()
      ..moveTo(width * 0.76, height * 0.34)
      ..quadraticBezierTo(width * 0.83, height * 0.18, width * 0.66, height * 0.23)
      ..close();
    canvas.drawPath(rightInnerEar, innerEarPaint);

    // 3. Head Base (Slate Grey)
    final headPaint = Paint()
      ..color = const Color(0xFF708090)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, center.dy + height * 0.05), width * 0.38, headPaint);

    // 4. White Face Highlight
    final whiteFacePaint = Paint()
      ..color = const Color(0xFFF7FAFC)
      ..style = PaintingStyle.fill;
    final whiteFacePath = Path()
      ..moveTo(width * 0.20, height * 0.58)
      ..quadraticBezierTo(width * 0.50, height * 0.30, width * 0.80, height * 0.58)
      ..quadraticBezierTo(width * 0.85, height * 0.82, width * 0.50, height * 0.88)
      ..quadraticBezierTo(width * 0.15, height * 0.82, width * 0.20, height * 0.58)
      ..close();
    canvas.drawPath(whiteFacePath, whiteFacePaint);

    // 5. Classic Raccoon Eye Mask (Dark Charcoal Band)
    final maskPaint = Paint()
      ..color = const Color(0xFF2C3539)
      ..style = PaintingStyle.fill;

    // Left Mask Wing
    final leftMaskPath = Path()
      ..moveTo(width * 0.50, height * 0.50)
      ..quadraticBezierTo(width * 0.32, height * 0.36, width * 0.18, height * 0.48)
      ..quadraticBezierTo(width * 0.20, height * 0.66, width * 0.48, height * 0.62)
      ..close();
    canvas.drawPath(leftMaskPath, maskPaint);

    // Right Mask Wing
    final rightMaskPath = Path()
      ..moveTo(width * 0.50, height * 0.50)
      ..quadraticBezierTo(width * 0.68, height * 0.36, width * 0.82, height * 0.48)
      ..quadraticBezierTo(width * 0.80, height * 0.66, width * 0.52, height * 0.62)
      ..close();
    canvas.drawPath(rightMaskPath, maskPaint);

    // 6. Eyes (Big shiny cartoon eyes)
    final eyeWhitePaint = Paint()..color = Colors.white;
    final eyePupilPaint = Paint()..color = const Color(0xFF111111);
    final eyeShinePaint = Paint()..color = Colors.white;

    // Left Eye
    canvas.drawCircle(Offset(width * 0.34, height * 0.52), width * 0.08, eyeWhitePaint);
    canvas.drawCircle(Offset(width * 0.34, height * 0.52), width * 0.06, eyePupilPaint);
    canvas.drawCircle(Offset(width * 0.32, height * 0.50), width * 0.02, eyeShinePaint);

    // Right Eye
    canvas.drawCircle(Offset(width * 0.66, height * 0.52), width * 0.08, eyeWhitePaint);
    canvas.drawCircle(Offset(width * 0.66, height * 0.52), width * 0.06, eyePupilPaint);
    canvas.drawCircle(Offset(width * 0.64, height * 0.50), width * 0.02, eyeShinePaint);

    // 7. Cute Muzzle & Button Nose
    final nosePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(width * 0.50, height * 0.65),
        width: width * 0.16,
        height: height * 0.11,
      ),
      nosePaint,
    );

    // Nose Highlight
    final noseShinePaint = Paint()..color = Colors.white.withAlpha(200);
    canvas.drawCircle(Offset(width * 0.47, height * 0.63), width * 0.02, noseShinePaint);

    // 8. Cute Mouth (W-smile)
    final mouthPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path()
      ..moveTo(width * 0.44, height * 0.72)
      ..quadraticBezierTo(width * 0.47, height * 0.76, width * 0.50, height * 0.73)
      ..quadraticBezierTo(width * 0.53, height * 0.76, width * 0.56, height * 0.72);
    canvas.drawPath(mouthPath, mouthPaint);

    // 9. Rosy Cheeks
    final cheekPaint = Paint()
      ..color = const Color(0xFFFFB6C1).withAlpha(160)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(width * 0.22, height * 0.60), width * 0.06, cheekPaint);
    canvas.drawCircle(Offset(width * 0.78, height * 0.60), width * 0.06, cheekPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 2. ELEPHANT PAINTER (Cute cartoon elephant with big ears and cheerful trunk)
class ElephantPainter extends CustomPainter {
  const ElephantPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final width = size.width;
    final height = size.height;

    // Background Fill (Soft pastel blue)
    final bgPaint = Paint()
      ..color = const Color(0xFFE0EDFB)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, width / 2, bgPaint);

    // Floppy Outer Ears (Soft Slate Blue-Grey)
    final outerEarPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;
    final innerEarPaint = Paint()
      ..color = const Color(0xFFFBCFE8) // Soft baby pink
      ..style = PaintingStyle.fill;

    // Left Floppy Ear
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(width * 0.16, height * 0.46),
        width: width * 0.32,
        height: height * 0.42,
      ),
      outerEarPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(width * 0.16, height * 0.46),
        width: width * 0.20,
        height: height * 0.30,
      ),
      innerEarPaint,
    );

    // Right Floppy Ear
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(width * 0.84, height * 0.46),
        width: width * 0.32,
        height: height * 0.42,
      ),
      outerEarPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(width * 0.84, height * 0.46),
        width: width * 0.20,
        height: height * 0.30,
      ),
      innerEarPaint,
    );

    // Elephant Head Base
    final headPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(center.dx, center.dy + height * 0.04),
      width * 0.38,
      headPaint,
    );

    // Cute Little Forehead Tufts / Highlights
    final hairPaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(width * 0.48, height * 0.14),
      Offset(width * 0.45, height * 0.10),
      hairPaint,
    );
    canvas.drawLine(
      Offset(width * 0.50, height * 0.14),
      Offset(width * 0.50, height * 0.08),
      hairPaint,
    );
    canvas.drawLine(
      Offset(width * 0.52, height * 0.14),
      Offset(width * 0.55, height * 0.10),
      hairPaint,
    );

    // Big Shiny Cartoon Eyes
    final eyeWhitePaint = Paint()..color = Colors.white;
    final eyePupilPaint = Paint()..color = const Color(0xFF0F172A);
    final eyeShinePaint = Paint()..color = Colors.white;

    // Left Eye
    canvas.drawCircle(Offset(width * 0.33, height * 0.48), width * 0.08, eyeWhitePaint);
    canvas.drawCircle(Offset(width * 0.33, height * 0.48), width * 0.06, eyePupilPaint);
    canvas.drawCircle(Offset(width * 0.31, height * 0.46), width * 0.02, eyeShinePaint);

    // Right Eye
    canvas.drawCircle(Offset(width * 0.67, height * 0.48), width * 0.08, eyeWhitePaint);
    canvas.drawCircle(Offset(width * 0.67, height * 0.48), width * 0.06, eyePupilPaint);
    canvas.drawCircle(Offset(width * 0.65, height * 0.46), width * 0.02, eyeShinePaint);

    // Cheerful Curved Elephant Trunk
    final trunkPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.fill;
    final trunkOutline = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final trunkPath = Path()
      ..moveTo(width * 0.43, height * 0.52)
      ..quadraticBezierTo(width * 0.40, height * 0.72, width * 0.52, height * 0.76)
      ..quadraticBezierTo(width * 0.64, height * 0.77, width * 0.62, height * 0.66)
      ..quadraticBezierTo(width * 0.58, height * 0.63, width * 0.55, height * 0.67)
      ..quadraticBezierTo(width * 0.51, height * 0.70, width * 0.47, height * 0.65)
      ..quadraticBezierTo(width * 0.49, height * 0.56, width * 0.57, height * 0.52)
      ..close();
    canvas.drawPath(trunkPath, trunkPaint);
    canvas.drawPath(trunkPath, trunkOutline);

    // Trunk wrinkles
    final wrinklePaint = Paint()
      ..color = const Color(0xFF475569)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(width * 0.45, height * 0.58),
      Offset(width * 0.54, height * 0.58),
      wrinklePaint,
    );
    canvas.drawLine(
      Offset(width * 0.44, height * 0.63),
      Offset(width * 0.52, height * 0.63),
      wrinklePaint,
    );

    // Cute Tiny White Tusks
    final tuskPaint = Paint()
      ..color = const Color(0xFFFFFBEB)
      ..style = PaintingStyle.fill;
    final leftTusk = Path()
      ..moveTo(width * 0.38, height * 0.65)
      ..quadraticBezierTo(width * 0.34, height * 0.67, width * 0.35, height * 0.73)
      ..quadraticBezierTo(width * 0.39, height * 0.70, width * 0.41, height * 0.67)
      ..close();
    canvas.drawPath(leftTusk, tuskPaint);

    final rightTusk = Path()
      ..moveTo(width * 0.60, height * 0.67)
      ..quadraticBezierTo(width * 0.62, height * 0.71, width * 0.66, height * 0.73)
      ..quadraticBezierTo(width * 0.66, height * 0.67, width * 0.62, height * 0.65)
      ..close();
    canvas.drawPath(rightTusk, tuskPaint);

    // Rosy Cheeks
    final cheekPaint = Paint()
      ..color = const Color(0xFFFFB6C1).withAlpha(160)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(width * 0.22, height * 0.56), width * 0.06, cheekPaint);
    canvas.drawCircle(Offset(width * 0.78, height * 0.56), width * 0.06, cheekPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 3. TIGER PAINTER (Energetic tiger with bold stripes and bright eyes)
class TigerPainter extends CustomPainter {
  const TigerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final width = size.width;
    final height = size.height;

    // Background Fill (Warm pastel cream)
    final bgPaint = Paint()
      ..color = const Color(0xFFFFF1E6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, width / 2, bgPaint);

    // Ears
    final outerEarPaint = Paint()
      ..color = const Color(0xFFE67E22)
      ..style = PaintingStyle.fill;
    final innerEarPaint = Paint()
      ..color = const Color(0xFFFFD1DC)
      ..style = PaintingStyle.fill;

    // Left Ear
    canvas.drawCircle(Offset(width * 0.26, height * 0.24), width * 0.14, outerEarPaint);
    canvas.drawCircle(Offset(width * 0.26, height * 0.24), width * 0.08, innerEarPaint);

    // Right Ear
    canvas.drawCircle(Offset(width * 0.74, height * 0.24), width * 0.14, outerEarPaint);
    canvas.drawCircle(Offset(width * 0.74, height * 0.24), width * 0.08, innerEarPaint);

    // Head Base (Warm Golden Orange)
    final headPaint = Paint()
      ..color = const Color(0xFFF39C12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, center.dy + height * 0.05), width * 0.38, headPaint);

    // Tiger Stripes (Charcoal Brown)
    final stripePaint = Paint()
      ..color = const Color(0xFF2C241E)
      ..style = PaintingStyle.fill;

    // Center Forehead Stripes
    final centerStripe = Path()
      ..moveTo(width * 0.47, height * 0.18)
      ..lineTo(width * 0.53, height * 0.18)
      ..lineTo(width * 0.50, height * 0.30)
      ..close();
    canvas.drawPath(centerStripe, stripePaint);

    // Left Forehead Stripe
    final leftTopStripe = Path()
      ..moveTo(width * 0.37, height * 0.22)
      ..lineTo(width * 0.42, height * 0.22)
      ..lineTo(width * 0.44, height * 0.30)
      ..close();
    canvas.drawPath(leftTopStripe, stripePaint);

    // Right Forehead Stripe
    final rightTopStripe = Path()
      ..moveTo(width * 0.63, height * 0.22)
      ..lineTo(width * 0.58, height * 0.22)
      ..lineTo(width * 0.56, height * 0.30)
      ..close();
    canvas.drawPath(rightTopStripe, stripePaint);

    // Cheek Stripes (Left)
    final leftCheekStripe1 = Path()
      ..moveTo(width * 0.14, height * 0.46)
      ..lineTo(width * 0.24, height * 0.49)
      ..lineTo(width * 0.15, height * 0.52)
      ..close();
    canvas.drawPath(leftCheekStripe1, stripePaint);

    final leftCheekStripe2 = Path()
      ..moveTo(width * 0.15, height * 0.56)
      ..lineTo(width * 0.25, height * 0.58)
      ..lineTo(width * 0.17, height * 0.62)
      ..close();
    canvas.drawPath(leftCheekStripe2, stripePaint);

    // Cheek Stripes (Right)
    final rightCheekStripe1 = Path()
      ..moveTo(width * 0.86, height * 0.46)
      ..lineTo(width * 0.76, height * 0.49)
      ..lineTo(width * 0.85, height * 0.52)
      ..close();
    canvas.drawPath(rightCheekStripe1, stripePaint);

    final rightCheekStripe2 = Path()
      ..moveTo(width * 0.85, height * 0.56)
      ..lineTo(width * 0.75, height * 0.58)
      ..lineTo(width * 0.83, height * 0.62)
      ..close();
    canvas.drawPath(rightCheekStripe2, stripePaint);

    // White Muzzle Area
    final muzzlePaint = Paint()
      ..color = const Color(0xFFFFFBF0)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, height * 0.68),
        width: width * 0.36,
        height: height * 0.24,
      ),
      muzzlePaint,
    );

    // Big Shiny Cartoon Eyes
    final eyeWhitePaint = Paint()..color = Colors.white;
    final eyePupilPaint = Paint()..color = const Color(0xFF1E1B18);
    final eyeShinePaint = Paint()..color = Colors.white;

    // Left Eye
    canvas.drawCircle(Offset(width * 0.34, height * 0.49), width * 0.08, eyeWhitePaint);
    canvas.drawCircle(Offset(width * 0.34, height * 0.49), width * 0.06, eyePupilPaint);
    canvas.drawCircle(Offset(width * 0.32, height * 0.47), width * 0.02, eyeShinePaint);

    // Right Eye
    canvas.drawCircle(Offset(width * 0.66, height * 0.49), width * 0.08, eyeWhitePaint);
    canvas.drawCircle(Offset(width * 0.66, height * 0.49), width * 0.06, eyePupilPaint);
    canvas.drawCircle(Offset(width * 0.64, height * 0.47), width * 0.02, eyeShinePaint);

    // Cute Dark Nose
    final nosePaint = Paint()
      ..color = const Color(0xFF2B2523)
      ..style = PaintingStyle.fill;
    final nosePath = Path()
      ..moveTo(width * 0.45, height * 0.63)
      ..lineTo(width * 0.55, height * 0.63)
      ..quadraticBezierTo(width * 0.50, height * 0.70, width * 0.45, height * 0.63)
      ..close();
    canvas.drawPath(nosePath, nosePaint);

    // Nose Highlight
    canvas.drawCircle(Offset(width * 0.48, height * 0.64), width * 0.015, eyeShinePaint);

    // W-smile Mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFF2C241E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path()
      ..moveTo(width * 0.44, height * 0.72)
      ..quadraticBezierTo(width * 0.47, height * 0.76, width * 0.50, height * 0.73)
      ..quadraticBezierTo(width * 0.53, height * 0.76, width * 0.56, height * 0.72);
    canvas.drawPath(mouthPath, mouthPaint);

    // Rosy Cheeks
    final cheekPaint = Paint()
      ..color = const Color(0xFFFF8A80).withAlpha(160)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(width * 0.22, height * 0.60), width * 0.06, cheekPaint);
    canvas.drawCircle(Offset(width * 0.78, height * 0.60), width * 0.06, cheekPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 4. LION PAINTER (Majestic yet cuddly lion with golden mane)
class LionPainter extends CustomPainter {
  const LionPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final width = size.width;
    final height = size.height;

    // Background Fill (Soft warm cream)
    final bgPaint = Paint()
      ..color = const Color(0xFFFFF7ED)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, width / 2, bgPaint);

    // Magnificent Golden Mane (Fluffy ring of overlapping soft lobes)
    final manePaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.fill;

    const int lobes = 10;
    for (int i = 0; i < lobes; i++) {
      final angle = (i * 2 * math.pi) / lobes;
      // Clean radial mane circles
      final rx = center.dx + (width * 0.33) * (0.9 * (i.isEven ? 1.05 : 0.95)) * math.cos(angle);
      final ry = (center.dy + height * 0.04) + (height * 0.33) * (0.9 * (i.isEven ? 1.05 : 0.95)) * math.sin(angle);
      canvas.drawCircle(Offset(rx, ry), width * 0.16, manePaint);
    }

    // Ears Nestled in Mane
    final outerEarPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.fill;
    final innerEarPaint = Paint()
      ..color = const Color(0xFFFFD1DC)
      ..style = PaintingStyle.fill;

    // Left Ear
    canvas.drawCircle(Offset(width * 0.25, height * 0.28), width * 0.11, outerEarPaint);
    canvas.drawCircle(Offset(width * 0.25, height * 0.28), width * 0.06, innerEarPaint);

    // Right Ear
    canvas.drawCircle(Offset(width * 0.75, height * 0.28), width * 0.11, outerEarPaint);
    canvas.drawCircle(Offset(width * 0.75, height * 0.28), width * 0.06, innerEarPaint);

    // Head Base (Warm Golden Tan)
    final headPaint = Paint()
      ..color = const Color(0xFFFBBF24)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, center.dy + height * 0.05), width * 0.32, headPaint);

    // Cream Muzzle
    final muzzlePaint = Paint()
      ..color = const Color(0xFFFFFBEB)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, height * 0.67),
        width: width * 0.34,
        height: height * 0.22,
      ),
      muzzlePaint,
    );

    // Big Shiny Cartoon Eyes
    final eyeWhitePaint = Paint()..color = Colors.white;
    final eyePupilPaint = Paint()..color = const Color(0xFF1E1B18);
    final eyeShinePaint = Paint()..color = Colors.white;

    // Left Eye
    canvas.drawCircle(Offset(width * 0.35, height * 0.50), width * 0.075, eyeWhitePaint);
    canvas.drawCircle(Offset(width * 0.35, height * 0.50), width * 0.055, eyePupilPaint);
    canvas.drawCircle(Offset(width * 0.33, height * 0.48), width * 0.02, eyeShinePaint);

    // Right Eye
    canvas.drawCircle(Offset(width * 0.65, height * 0.50), width * 0.075, eyeWhitePaint);
    canvas.drawCircle(Offset(width * 0.65, height * 0.50), width * 0.055, eyePupilPaint);
    canvas.drawCircle(Offset(width * 0.63, height * 0.48), width * 0.02, eyeShinePaint);

    // Rounded Lion Nose (Warm Dark Chocolate)
    final nosePaint = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.fill;
    final nosePath = Path()
      ..moveTo(width * 0.44, height * 0.62)
      ..lineTo(width * 0.56, height * 0.62)
      ..quadraticBezierTo(width * 0.50, height * 0.69, width * 0.44, height * 0.62)
      ..close();
    canvas.drawPath(nosePath, nosePaint);

    // Nose Highlight
    canvas.drawCircle(Offset(width * 0.48, height * 0.63), width * 0.015, eyeShinePaint);

    // W-smile Mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path()
      ..moveTo(width * 0.44, height * 0.72)
      ..quadraticBezierTo(width * 0.47, height * 0.76, width * 0.50, height * 0.73)
      ..quadraticBezierTo(width * 0.53, height * 0.76, width * 0.56, height * 0.72);
    canvas.drawPath(mouthPath, mouthPaint);

    // Whiskers dots
    final dotPaint = Paint()..color = const Color(0xFF78350F);
    canvas.drawCircle(Offset(width * 0.42, height * 0.69), 1.2, dotPaint);
    canvas.drawCircle(Offset(width * 0.40, height * 0.72), 1.2, dotPaint);
    canvas.drawCircle(Offset(width * 0.58, height * 0.69), 1.2, dotPaint);
    canvas.drawCircle(Offset(width * 0.60, height * 0.72), 1.2, dotPaint);

    // Rosy Cheeks
    final cheekPaint = Paint()
      ..color = const Color(0xFFFFB6C1).withAlpha(160)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(width * 0.24, height * 0.60), width * 0.05, cheekPaint);
    canvas.drawCircle(Offset(width * 0.76, height * 0.60), width * 0.05, cheekPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 5. RABBIT PAINTER (Adorable bunny with tall ears and sweet expression)
class RabbitPainter extends CustomPainter {
  const RabbitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final width = size.width;
    final height = size.height;

    // Background Fill (Soft pastel rose)
    final bgPaint = Paint()
      ..color = const Color(0xFFFCE7F3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, width / 2, bgPaint);

    // Long Bunny Ears
    final outerEarPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final innerEarPaint = Paint()
      ..color = const Color(0xFFFFB6C1)
      ..style = PaintingStyle.fill;

    // Left Tall Ear
    final leftEarPath = Path()
      ..moveTo(width * 0.28, height * 0.40)
      ..quadraticBezierTo(width * 0.20, height * 0.04, width * 0.38, height * 0.06)
      ..quadraticBezierTo(width * 0.46, height * 0.20, width * 0.42, height * 0.40)
      ..close();
    canvas.drawPath(leftEarPath, outerEarPaint);

    final leftInnerPath = Path()
      ..moveTo(width * 0.30, height * 0.36)
      ..quadraticBezierTo(width * 0.25, height * 0.10, width * 0.36, height * 0.11)
      ..quadraticBezierTo(width * 0.41, height * 0.22, width * 0.39, height * 0.36)
      ..close();
    canvas.drawPath(leftInnerPath, innerEarPaint);

    // Right Tall Ear (Slightly tilted)
    final rightEarPath = Path()
      ..moveTo(width * 0.58, height * 0.40)
      ..quadraticBezierTo(width * 0.54, height * 0.20, width * 0.62, height * 0.06)
      ..quadraticBezierTo(width * 0.80, height * 0.04, width * 0.72, height * 0.40)
      ..close();
    canvas.drawPath(rightEarPath, outerEarPaint);

    final rightInnerPath = Path()
      ..moveTo(width * 0.61, height * 0.36)
      ..quadraticBezierTo(width * 0.59, height * 0.22, width * 0.64, height * 0.11)
      ..quadraticBezierTo(width * 0.75, height * 0.10, width * 0.70, height * 0.36)
      ..close();
    canvas.drawPath(rightInnerPath, innerEarPaint);

    // Rabbit Head (Fluffy White)
    final headPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, center.dy + height * 0.10), width * 0.36, headPaint);

    // Big Shiny Expressive Eyes
    final eyeWhitePaint = Paint()..color = const Color(0xFFF1F5F9);
    final eyePupilPaint = Paint()..color = const Color(0xFF1E1B4B);
    final eyeShinePaint = Paint()..color = Colors.white;

    // Left Eye
    canvas.drawCircle(Offset(width * 0.33, height * 0.54), width * 0.08, eyeWhitePaint);
    canvas.drawCircle(Offset(width * 0.33, height * 0.54), width * 0.065, eyePupilPaint);
    canvas.drawCircle(Offset(width * 0.31, height * 0.52), width * 0.022, eyeShinePaint);
    canvas.drawCircle(Offset(width * 0.35, height * 0.56), width * 0.009, eyeShinePaint);

    // Right Eye
    canvas.drawCircle(Offset(width * 0.67, height * 0.54), width * 0.08, eyeWhitePaint);
    canvas.drawCircle(Offset(width * 0.67, height * 0.54), width * 0.065, eyePupilPaint);
    canvas.drawCircle(Offset(width * 0.65, height * 0.52), width * 0.022, eyeShinePaint);
    canvas.drawCircle(Offset(width * 0.69, height * 0.56), width * 0.009, eyeShinePaint);

    // Cute Tiny Pink Nose
    final nosePaint = Paint()
      ..color = const Color(0xFFF472B6)
      ..style = PaintingStyle.fill;
    final nosePath = Path()
      ..moveTo(width * 0.46, height * 0.64)
      ..lineTo(width * 0.54, height * 0.64)
      ..lineTo(width * 0.50, height * 0.69)
      ..close();
    canvas.drawPath(nosePath, nosePaint);

    // W-smile Mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path()
      ..moveTo(width * 0.44, height * 0.72)
      ..quadraticBezierTo(width * 0.47, height * 0.76, width * 0.50, height * 0.73)
      ..quadraticBezierTo(width * 0.53, height * 0.76, width * 0.56, height * 0.72);
    canvas.drawPath(mouthPath, mouthPaint);

    // Whiskers
    final whiskerPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(width * 0.22, height * 0.66), Offset(width * 0.12, height * 0.64), whiskerPaint);
    canvas.drawLine(Offset(width * 0.22, height * 0.70), Offset(width * 0.12, height * 0.72), whiskerPaint);
    canvas.drawLine(Offset(width * 0.78, height * 0.66), Offset(width * 0.88, height * 0.64), whiskerPaint);
    canvas.drawLine(Offset(width * 0.78, height * 0.70), Offset(width * 0.88, height * 0.72), whiskerPaint);

    // Big Rosy Cheeks
    final cheekPaint = Paint()
      ..color = const Color(0xFFFF8DA1).withAlpha(170)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(width * 0.22, height * 0.62), width * 0.065, cheekPaint);
    canvas.drawCircle(Offset(width * 0.78, height * 0.62), width * 0.065, cheekPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 6. BEAR PAINTER (Warm and friendly teddy bear)
class BearPainter extends CustomPainter {
  const BearPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final width = size.width;
    final height = size.height;

    // Background Fill (Soft warm earth pastel)
    final bgPaint = Paint()
      ..color = const Color(0xFFF3EBE6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, width / 2, bgPaint);

    // Cute Round Ears
    final outerEarPaint = Paint()
      ..color = const Color(0xFF795548)
      ..style = PaintingStyle.fill;
    final innerEarPaint = Paint()
      ..color = const Color(0xFFD7CCC8)
      ..style = PaintingStyle.fill;

    // Left Ear
    canvas.drawCircle(Offset(width * 0.24, height * 0.24), width * 0.14, outerEarPaint);
    canvas.drawCircle(Offset(width * 0.24, height * 0.24), width * 0.08, innerEarPaint);

    // Right Ear
    canvas.drawCircle(Offset(width * 0.76, height * 0.24), width * 0.14, outerEarPaint);
    canvas.drawCircle(Offset(width * 0.76, height * 0.24), width * 0.08, innerEarPaint);

    // Head Base (Warm Chestnut Brown)
    final headPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, center.dy + height * 0.06), width * 0.38, headPaint);

    // Soft Cream Muzzle
    final muzzlePaint = Paint()
      ..color = const Color(0xFFEFEBE9)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, height * 0.66),
        width: width * 0.40,
        height: height * 0.26,
      ),
      muzzlePaint,
    );

    // Big Shiny Cartoon Eyes
    final eyeWhitePaint = Paint()..color = Colors.white;
    final eyePupilPaint = Paint()..color = const Color(0xFF263238);
    final eyeShinePaint = Paint()..color = Colors.white;

    // Left Eye
    canvas.drawCircle(Offset(width * 0.35, height * 0.50), width * 0.08, eyeWhitePaint);
    canvas.drawCircle(Offset(width * 0.35, height * 0.50), width * 0.06, eyePupilPaint);
    canvas.drawCircle(Offset(width * 0.33, height * 0.48), width * 0.02, eyeShinePaint);

    // Right Eye
    canvas.drawCircle(Offset(width * 0.65, height * 0.50), width * 0.08, eyeWhitePaint);
    canvas.drawCircle(Offset(width * 0.65, height * 0.50), width * 0.06, eyePupilPaint);
    canvas.drawCircle(Offset(width * 0.63, height * 0.48), width * 0.02, eyeShinePaint);

    // Cute Charcoal Button Nose
    final nosePaint = Paint()
      ..color = const Color(0xFF263238)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(width * 0.50, height * 0.63),
        width: width * 0.16,
        height: height * 0.11,
      ),
      nosePaint,
    );

    // Nose Highlight
    canvas.drawCircle(Offset(width * 0.47, height * 0.61), width * 0.018, eyeShinePaint);

    // W-smile Mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path()
      ..moveTo(width * 0.44, height * 0.72)
      ..quadraticBezierTo(width * 0.47, height * 0.76, width * 0.50, height * 0.73)
      ..quadraticBezierTo(width * 0.53, height * 0.76, width * 0.56, height * 0.72);
    canvas.drawPath(mouthPath, mouthPaint);

    // Rosy Cheeks
    final cheekPaint = Paint()
      ..color = const Color(0xFFFFAB91).withAlpha(160)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(width * 0.22, height * 0.60), width * 0.06, cheekPaint);
    canvas.drawCircle(Offset(width * 0.78, height * 0.60), width * 0.06, cheekPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 7. CAT PAINTER (Playful cartoon cat with pointed ears and sweet whiskers)
class CatPainter extends CustomPainter {
  const CatPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final width = size.width;
    final height = size.height;

    // Background Fill (Soft pastel lilac)
    final bgPaint = Paint()
      ..color = const Color(0xFFF3E8FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, width / 2, bgPaint);

    // Pointed Triangular Ears
    final outerEarPaint = Paint()
      ..color = const Color(0xFFFB923C) // Warm Ginger Peach
      ..style = PaintingStyle.fill;
    final innerEarPaint = Paint()
      ..color = const Color(0xFFFFB6C1)
      ..style = PaintingStyle.fill;

    // Left Ear
    final leftEarPath = Path()
      ..moveTo(width * 0.22, height * 0.38)
      ..lineTo(width * 0.16, height * 0.12)
      ..lineTo(width * 0.40, height * 0.22)
      ..close();
    canvas.drawPath(leftEarPath, outerEarPaint);

    final leftInnerEar = Path()
      ..moveTo(width * 0.24, height * 0.34)
      ..lineTo(width * 0.20, height * 0.17)
      ..lineTo(width * 0.36, height * 0.23)
      ..close();
    canvas.drawPath(leftInnerEar, innerEarPaint);

    // Right Ear
    final rightEarPath = Path()
      ..moveTo(width * 0.78, height * 0.38)
      ..lineTo(width * 0.84, height * 0.12)
      ..lineTo(width * 0.60, height * 0.22)
      ..close();
    canvas.drawPath(rightEarPath, outerEarPaint);

    final rightInnerEar = Path()
      ..moveTo(width * 0.76, height * 0.34)
      ..lineTo(width * 0.80, height * 0.17)
      ..lineTo(width * 0.64, height * 0.23)
      ..close();
    canvas.drawPath(rightInnerEar, innerEarPaint);

    // Head Base (Warm Ginger)
    final headPaint = Paint()
      ..color = const Color(0xFFFB923C)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(center.dx, center.dy + height * 0.06), width * 0.38, headPaint);

    // Cute Tabby Stripes on Forehead
    final stripePaint = Paint()
      ..color = const Color(0xFFEA580C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(width * 0.50, height * 0.20), Offset(width * 0.50, height * 0.30), stripePaint);
    canvas.drawLine(Offset(width * 0.44, height * 0.22), Offset(width * 0.46, height * 0.32), stripePaint);
    canvas.drawLine(Offset(width * 0.56, height * 0.22), Offset(width * 0.54, height * 0.32), stripePaint);

    // Cream Muzzle
    final muzzlePaint = Paint()
      ..color = const Color(0xFFFFFBF0)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, height * 0.68),
        width: width * 0.36,
        height: height * 0.22,
      ),
      muzzlePaint,
    );

    // Big Shiny Cartoon Eyes
    final eyeWhitePaint = Paint()..color = Colors.white;
    final eyePupilPaint = Paint()..color = const Color(0xFF0F172A);
    final eyeShinePaint = Paint()..color = Colors.white;

    // Left Eye
    canvas.drawCircle(Offset(width * 0.34, height * 0.51), width * 0.08, eyeWhitePaint);
    canvas.drawCircle(Offset(width * 0.34, height * 0.51), width * 0.06, eyePupilPaint);
    canvas.drawCircle(Offset(width * 0.32, height * 0.49), width * 0.02, eyeShinePaint);

    // Right Eye
    canvas.drawCircle(Offset(width * 0.66, height * 0.51), width * 0.08, eyeWhitePaint);
    canvas.drawCircle(Offset(width * 0.66, height * 0.51), width * 0.06, eyePupilPaint);
    canvas.drawCircle(Offset(width * 0.64, height * 0.49), width * 0.02, eyeShinePaint);

    // Cute Pink Button Nose
    final nosePaint = Paint()
      ..color = const Color(0xFFF472B6)
      ..style = PaintingStyle.fill;
    final nosePath = Path()
      ..moveTo(width * 0.46, height * 0.64)
      ..lineTo(width * 0.54, height * 0.64)
      ..lineTo(width * 0.50, height * 0.69)
      ..close();
    canvas.drawPath(nosePath, nosePaint);

    // W-smile Mouth
    final mouthPaint = Paint()
      ..color = const Color(0xFF7C2D12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path()
      ..moveTo(width * 0.44, height * 0.72)
      ..quadraticBezierTo(width * 0.47, height * 0.76, width * 0.50, height * 0.73)
      ..quadraticBezierTo(width * 0.53, height * 0.76, width * 0.56, height * 0.72);
    canvas.drawPath(mouthPath, mouthPaint);

    // Whiskers
    final whiskerPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(width * 0.22, height * 0.66), Offset(width * 0.12, height * 0.64), whiskerPaint);
    canvas.drawLine(Offset(width * 0.22, height * 0.70), Offset(width * 0.12, height * 0.72), whiskerPaint);
    canvas.drawLine(Offset(width * 0.78, height * 0.66), Offset(width * 0.88, height * 0.64), whiskerPaint);
    canvas.drawLine(Offset(width * 0.78, height * 0.70), Offset(width * 0.88, height * 0.72), whiskerPaint);

    // Rosy Cheeks
    final cheekPaint = Paint()
      ..color = const Color(0xFFFF8DA1).withAlpha(160)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(width * 0.22, height * 0.60), width * 0.06, cheekPaint);
    canvas.drawCircle(Offset(width * 0.78, height * 0.60), width * 0.06, cheekPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
