import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../utils/app_colors.dart';

/// Legacy card wrapper refactored to conform to the Cognitive Gym tactical design system.
///
/// Features crisp 12px corners, high-contrast 1px border, and controlled elevation.
class NatureCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Border? border;
  final VoidCallback? onTap;
  final double borderRadius;

  const NatureCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.gradient,
    this.backgroundColor,
    this.border,
    this.onTap,
    this.borderRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultBorder = Border.all(
      color: isDark ? AppColors.borderDark : AppColors.borderLightClean,
      width: 1.0,
    );

    final cardBg = backgroundColor ??
        (isDark ? AppColors.cardDark : AppColors.cardLight);

    Widget containerWidget = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: gradient == null ? cardBg : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? defaultBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            SoundService.instance.playCardClick();
            onTap!();
          },
          borderRadius: BorderRadius.circular(borderRadius),
          child: containerWidget,
        ),
      );
    }

    return containerWidget;
  }
}
