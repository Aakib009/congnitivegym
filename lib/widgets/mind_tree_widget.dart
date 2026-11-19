import 'dart:math';
import 'package:flutter/material.dart';
import '../models/mind_tree_level_config.dart';
import '../utils/app_colors.dart';

/// Displays the Mind Tree with 11 distinct visual levels (0-10).
///
/// The tree evolves visually as the user progresses through cognitive training.
/// Level 0 = Seed, Level 10 = Fully Grown Tree with Apples.
class MindTreeWidget extends StatefulWidget {
  final int level;
  final double progress;
  final bool animate;

  const MindTreeWidget({
    super.key,
    required this.level,
    this.progress = 0.0,
    this.animate = true,
  });

  @override
  State<MindTreeWidget> createState() => _MindTreeWidgetState();
}

class _MindTreeWidgetState extends State<MindTreeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _growAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _growAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(MindTreeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level && widget.animate) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = MindTreeLevelConfig.forLevel(widget.level);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _growAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      AppColors.darkSurface,
                      AppColors.darkCardSurface,
                      const Color(0xFF0F2C20),
                    ]
                  : [
                      const Color(0xFFEAF5EF),
                      const Color(0xFFD8EFE2),
                      const Color(0xFFCBEAD7),
                    ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(
              color: isDark
                  ? AppColors.emeraldMoss.withAlpha(120)
                  : AppColors.sageGreen.withAlpha(100),
              width: 1.5,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: AppColors.pineGreen.withAlpha(20),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLevelBadge(context, config, isDark),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _MindTreePainter(
                      config: config,
                      isDark: isDark,
                      animationValue: _growAnimation.value,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  config.title,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  config.description,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.mintMist.withAlpha(180)
                        : AppColors.barkBrown.withAlpha(160),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelBadge(BuildContext context, MindTreeLevelConfig config, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.emeraldMoss.withAlpha(100)
            : Colors.white.withAlpha(220),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.sageGreen.withAlpha(120),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.park_rounded,
            color: AppColors.leafGreen,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Level ${config.level} · ${config.title}',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.mintMist : AppColors.pineGreen,
            ),
          ),
        ],
      ),
    );
  }
}

/// CustomPainter that renders the Mind Tree based on level configuration.
///
/// Each level has distinct visual elements:
/// - Level 0: Seed
/// - Level 1: Germinating seed with tiny roots
/// - Level 2: Sprout with small trunk
/// - Level 3-4: Young tree with branches
/// - Level 5-6: Growing tree with foliage
/// - Level 7-8: Mature tree with full canopy
/// - Level 9: Fruitful tree
/// - Level 10: Fully grown tree with apples
class _MindTreePainter extends CustomPainter {
  final MindTreeLevelConfig config;
  final bool isDark;
  final double animationValue;

  _MindTreePainter({
    required this.config,
    required this.isDark,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final bottomY = size.height - 10;
    final anim = animationValue;

    // Draw elements based on level configuration
    _drawGround(canvas, cx, bottomY, size, anim);
    _drawRoots(canvas, cx, bottomY, size, anim);
    _drawSeed(canvas, cx, bottomY, size, anim);
    _drawTrunk(canvas, cx, bottomY, size, anim);
    _drawBranches(canvas, cx, bottomY, size, anim);
    _drawFoliage(canvas, cx, bottomY, size, anim);
    _drawFlowers(canvas, cx, bottomY, size, anim);
    _drawFruit(canvas, cx, bottomY, size, anim);
    _drawSparkles(canvas, cx, bottomY, size, anim);
  }

  void _drawGround(Canvas canvas, double cx, double bottomY, Size size, double anim) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: isDark
            ? [AppColors.pineGreen, AppColors.deepForest]
            : [AppColors.emeraldMoss, AppColors.pineGreen],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(cx - 100, bottomY - 15, 200, 30));

    final hillPath = Path()
      ..moveTo(cx - 110, bottomY + 15)
      ..quadraticBezierTo(cx, bottomY - 20 * anim, cx + 110, bottomY + 15)
      ..close();
    canvas.drawPath(hillPath, paint);
  }

  void _drawRoots(Canvas canvas, double cx, double bottomY, Size size, double anim) {
    if (!config.showRoots) return;

    final rootPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final rootLength = 25.0 * anim;

    // Left root
    canvas.drawLine(
      Offset(cx - 8, bottomY),
      Offset(cx - rootLength, bottomY + rootLength * 0.6),
      rootPaint,
    );

    // Right root
    canvas.drawLine(
      Offset(cx + 8, bottomY),
      Offset(cx + rootLength, bottomY + rootLength * 0.6),
      rootPaint,
    );

    // Center root
    canvas.drawLine(
      Offset(cx, bottomY),
      Offset(cx, bottomY + rootLength * 0.8),
      rootPaint,
    );
  }

  void _drawSeed(Canvas canvas, double cx, double bottomY, Size size, double anim) {
    if (!config.showSeed) return;

    final seedPaint = Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.fill;

    final seedSize = 6.0 * anim;
    final seedY = bottomY - 15 * anim;

    // Seed body
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, seedY), width: seedSize * 1.5, height: seedSize),
      seedPaint,
    );

    // Seed highlight
    final highlightPaint = Paint()
      ..color = AppColors.warmAmber.withAlpha(100)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 1, seedY - 1), width: seedSize * 0.6, height: seedSize * 0.4),
      highlightPaint,
    );
  }

  void _drawTrunk(Canvas canvas, double cx, double bottomY, Size size, double anim) {
    if (!config.showTrunk) return;

    final trunkPaint = Paint()
      ..color = const Color(0xFF4A3525)
      ..style = PaintingStyle.fill;

    final trunkH = size.height * config.trunkHeight * anim;
    final trunkW = size.width * config.trunkWidth * anim;

    final trunkPath = Path()
      ..moveTo(cx - trunkW, bottomY - 5)
      ..quadraticBezierTo(
        cx - trunkW * 0.8,
        bottomY - trunkH * 0.5,
        cx - trunkW * 0.6,
        bottomY - trunkH,
      )
      ..lineTo(cx + trunkW * 0.6, bottomY - trunkH)
      ..quadraticBezierTo(
        cx + trunkW * 0.8,
        bottomY - trunkH * 0.5,
        cx + trunkW,
        bottomY - 5,
      )
      ..close();
    canvas.drawPath(trunkPath, trunkPaint);

    // Bark texture lines
    final barkPaint = Paint()
      ..color = const Color(0xFF7A5C43)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(cx - 1, bottomY - 5),
      Offset(cx - 2, bottomY - trunkH * 0.7),
      barkPaint,
    );
    canvas.drawLine(
      Offset(cx + 2, bottomY - 5),
      Offset(cx + 1, bottomY - trunkH * 0.6),
      barkPaint,
    );
  }

  void _drawBranches(Canvas canvas, double cx, double bottomY, Size size, double anim) {
    if (!config.showBranches || config.branchCount == 0) return;

    final branchPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final trunkH = size.height * config.trunkHeight * anim;
    final trunkW = size.width * config.trunkWidth;
    final branchStartY = bottomY - trunkH * 0.6;
    final branchLength = 35.0 * anim;

    final angles = [-0.6, 0.6, -0.4, 0.4, -0.3, 0.3, -0.2, 0.2];
    final yOffset = [-0.05, -0.05, -0.15, -0.15, -0.25, -0.25, -0.35, -0.35];

    for (int i = 0; i < config.branchCount && i < 8; i++) {
      final startX = cx + (i.isEven ? -trunkW * 0.5 : trunkW * 0.5);
      final startY = branchStartY + size.height * yOffset[i];
      final endX = startX + cos(angles[i]) * branchLength;
      final endY = startY + sin(angles[i]) * branchLength * 0.5;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), branchPaint);
    }
  }

  void _drawFoliage(Canvas canvas, double cx, double bottomY, Size size, double anim) {
    if (!config.showFoliage) return;

    final foliagePaint = Paint()..style = PaintingStyle.fill;
    final radius = size.width * config.foliageRadius * anim;
    final trunkH = size.height * config.trunkHeight * anim;

    final foliageY = bottomY - trunkH - radius * 0.3;

    // Base foliage layers
    final layers = [
      (offset: Offset(cx - radius * 0.4, foliageY + radius * 0.2), color: AppColors.pineGreen, r: radius * 0.7),
      (offset: Offset(cx + radius * 0.4, foliageY + radius * 0.15), color: AppColors.pineGreen, r: radius * 0.75),
      (offset: Offset(cx, foliageY - radius * 0.1), color: AppColors.emeraldMoss, r: radius),
      (offset: Offset(cx - radius * 0.2, foliageY - radius * 0.3), color: AppColors.leafGreen, r: radius * 0.8),
      (offset: Offset(cx + radius * 0.15, foliageY - radius * 0.4), color: AppColors.leafGreen, r: radius * 0.7),
      (offset: Offset(cx, foliageY - radius * 0.5), color: AppColors.sageGreen, r: radius * 0.5),
    ];

    for (final layer in layers) {
      foliagePaint.color = layer.color;
      canvas.drawCircle(layer.offset, layer.r, foliagePaint);
    }
  }

  void _drawFlowers(Canvas canvas, double cx, double bottomY, Size size, double anim) {
    if (!config.showFlowers) return;

    final flowerPaint = Paint()..style = PaintingStyle.fill;
    final radius = size.width * config.foliageRadius * anim;
    final trunkH = size.height * config.trunkHeight * anim;
    final foliageY = bottomY - trunkH - radius * 0.3;

    final flowerPositions = [
      Offset(cx - radius * 0.3, foliageY - radius * 0.2),
      Offset(cx + radius * 0.35, foliageY - radius * 0.15),
      Offset(cx - radius * 0.1, foliageY - radius * 0.5),
      Offset(cx + radius * 0.2, foliageY - radius * 0.45),
    ];

    for (final pos in flowerPositions) {
      // Petals
      flowerPaint.color = AppColors.solarYellow.withAlpha(200);
      for (int i = 0; i < 5; i++) {
        final angle = i * pi * 2 / 5;
        final petalX = pos.dx + cos(angle) * 4 * anim;
        final petalY = pos.dy + sin(angle) * 4 * anim;
        canvas.drawCircle(Offset(petalX, petalY), 3 * anim, flowerPaint);
      }
      // Center
      flowerPaint.color = AppColors.warmAmber;
      canvas.drawCircle(pos, 2.5 * anim, flowerPaint);
    }
  }

  void _drawFruit(Canvas canvas, double cx, double bottomY, Size size, double anim) {
    if (!config.showFruit || config.fruitCount == 0) return;

    final fruitPaint = Paint()..style = PaintingStyle.fill;
    final radius = size.width * config.foliageRadius * anim;
    final trunkH = size.height * config.trunkHeight * anim;
    final foliageY = bottomY - trunkH - radius * 0.3;

    final fruitPositions = [
      Offset(cx - radius * 0.25, foliageY + radius * 0.1),
      Offset(cx + radius * 0.3, foliageY),
      Offset(cx - radius * 0.1, foliageY - radius * 0.3),
      Offset(cx + radius * 0.15, foliageY - radius * 0.25),
      Offset(cx, foliageY + radius * 0.15),
    ];

    for (int i = 0; i < config.fruitCount && i < fruitPositions.length; i++) {
      final pos = fruitPositions[i];
      // Apple body
      fruitPaint.color = const Color(0xFFE53935);
      canvas.drawCircle(pos, 5 * anim, fruitPaint);
      // Apple highlight
      fruitPaint.color = const Color(0xFFEF5350).withAlpha(180);
      canvas.drawCircle(Offset(pos.dx - 1, pos.dy - 1), 2.5 * anim, fruitPaint);
      // Stem
      final stemPaint = Paint()
        ..color = const Color(0xFF4A3525)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawLine(pos, Offset(pos.dx + 1, pos.dy - 5 * anim), stemPaint);
    }
  }

  void _drawSparkles(Canvas canvas, double cx, double bottomY, Size size, double anim) {
    if (config.sparkleIntensity <= 0) return;

    final sparklePaint = Paint()..style = PaintingStyle.fill;
    final radius = size.width * config.foliageRadius * anim;
    final trunkH = size.height * config.trunkHeight * anim;
    final foliageY = bottomY - trunkH - radius * 0.3;

    final sparkleCount = (6 * config.sparkleIntensity).round();
    final random = Random(42); // Fixed seed for consistent sparkles

    for (int i = 0; i < sparkleCount; i++) {
      final sparkleX = cx + (random.nextDouble() - 0.5) * radius * 2;
      final sparkleY = foliageY + (random.nextDouble() - 0.5) * radius;
      final sparkleSize = (1.5 + random.nextDouble() * 2) * anim;

      sparklePaint.color = i.isEven
          ? AppColors.solarYellow.withAlpha((180 * config.sparkleIntensity).round())
          : AppColors.mintMist.withAlpha((200 * config.sparkleIntensity).round());
      canvas.drawCircle(Offset(sparkleX, sparkleY), sparkleSize, sparklePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MindTreePainter oldDelegate) =>
      oldDelegate.config != config ||
      oldDelegate.isDark != isDark ||
      oldDelegate.animationValue != animationValue;
}
