import 'package:flutter/material.dart';
import '../services/sound_service.dart';
import '../utils/app_colors.dart';

/// Distinctive, production-quality tactical container card for Cognitive Gym.
///
/// Implements the anti-vibe-coding design system:
/// - Crisp, restrained 12px corners (avoids hyper-rounded pastel bubbles).
/// - Deliberate 1px border with high contrast.
/// - Flat opaque background elevation without harsh multi-stop gradients.
/// - Controlled, subtle depth rather than heavy drop shadows.
class GymCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final VoidCallback? onTap;
  final double borderRadius;
  final Widget? headerTag;

  const GymCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.onTap,
    this.borderRadius = 12.0,
    this.headerTag,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedBg = backgroundColor ??
        (isDark ? AppColors.cardDark : AppColors.cardLight);

    final resolvedBorderColor = borderColor ??
        (isDark ? AppColors.borderDark : AppColors.borderLightClean);

    Widget content = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: resolvedBorderColor,
          width: borderWidth,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: headerTag != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                headerTag!,
                const SizedBox(height: 12),
                child,
              ],
            )
          : child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            SoundService.instance.playSoftTap();
            onTap!();
          },
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      );
    }

    return content;
  }
}
