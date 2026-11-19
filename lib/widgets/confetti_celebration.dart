import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

/// Full-screen overlay particle canvas animating floating confetti celebration.
class ConfettiCelebrationWidget extends StatefulWidget {
  final VoidCallback? onFinished;

  const ConfettiCelebrationWidget({
    super.key,
    this.onFinished,
  });

  @override
  State<ConfettiCelebrationWidget> createState() =>
      _ConfettiCelebrationWidgetState();
}

class _ConfettiCelebrationWidgetState extends State<ConfettiCelebrationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ConfettiParticle> _particles;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..forward().then((_) {
        if (mounted && widget.onFinished != null) {
          widget.onFinished!();
        }
      });

    _particles = List.generate(50, (_) => _generateParticle());
  }

  _ConfettiParticle _generateParticle() {
    return _ConfettiParticle(
      x: _random.nextDouble(),
      startY: -0.1 - _random.nextDouble() * 0.2,
      endY: 1.1 + _random.nextDouble() * 0.2,
      speed: 0.8 + _random.nextDouble() * 0.6,
      size: 6.0 + _random.nextDouble() * 8.0,
      rotationSpeed: (_random.nextDouble() - 0.5) * 10,
      color: [
        AppColors.solarYellow,
        AppColors.emeraldMoss,
        AppColors.leafGreen,
        AppColors.terracotta,
        AppColors.warmAmber,
        Colors.cyanAccent,
        Colors.pinkAccent,
      ][_random.nextInt(7)],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _ConfettiPainter(
              particles: _particles,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _ConfettiParticle {
  final double x;
  final double startY;
  final double endY;
  final double speed;
  final double size;
  final double rotationSpeed;
  final Color color;

  _ConfettiParticle({
    required this.x,
    required this.startY,
    required this.endY,
    required this.speed,
    required this.size,
    required this.rotationSpeed,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final currentProgress = (progress * p.speed).clamp(0.0, 1.0);
      final y = lerpDouble(p.startY * size.height, p.endY * size.height, currentProgress)!;
      final x = p.x * size.width + sin(currentProgress * pi * 4) * 20;

      final paint = Paint()
        ..color = p.color.withAlpha(((1.0 - currentProgress) * 255).toInt().clamp(0, 255))
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(currentProgress * p.rotationSpeed * pi);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  double? lerpDouble(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => true;
}
