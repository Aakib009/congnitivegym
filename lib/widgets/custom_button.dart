import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/sound_service.dart';
import '../utils/app_constants.dart';

enum CustomButtonStyle { primary, secondary, outline, gradient }

/// Tactical action button designed for Cognitive Gym.
///
/// Features crisp 8px beveled corners, high-contrast Rajdhani uppercase typography,
/// and clear interaction feedback without excessive blur glows.
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final CustomButtonStyle style;
  final bool isLoading;
  final double? width;

  const CustomButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.style = CustomButtonStyle.primary,
    this.isLoading = false,
    this.width,
  });

  void _handleTap() {
    SoundService.instance.playSoftTap();
    if (onPressed != null) {
      onPressed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = _getTextColor(colorScheme);

    Widget buttonContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.barlowCondensed(
              color: textColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );

    final isEnabled = onPressed != null && !isLoading;

    if (style == CustomButtonStyle.gradient || style == CustomButtonStyle.primary) {
      final bgColor = isEnabled ? colorScheme.primary : colorScheme.surfaceContainer;
      return SizedBox(
        width: width,
        child: AnimatedOpacity(
          duration: AppConstants.animFast,
          opacity: isEnabled ? 1.0 : 0.5,
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isEnabled
                    ? colorScheme.primary
                    : colorScheme.outline.withAlpha(80),
                width: 1.0,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isEnabled ? _handleTap : null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: buttonContent,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isEnabled ? _handleTap : null,
        style: _getButtonStyle(theme, colorScheme),
        child: buttonContent,
      ),
    );
  }

  Color _getTextColor(ColorScheme colorScheme) {
    switch (style) {
      case CustomButtonStyle.primary:
      case CustomButtonStyle.gradient:
        return colorScheme.onPrimary;
      case CustomButtonStyle.secondary:
        return colorScheme.onSecondary;
      case CustomButtonStyle.outline:
        return colorScheme.primary;
    }
  }

  ButtonStyle _getButtonStyle(ThemeData theme, ColorScheme colorScheme) {
    switch (style) {
      case CustomButtonStyle.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: colorScheme.outline, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        );
      case CustomButtonStyle.outline:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          elevation: 0,
          side: BorderSide(
            color: colorScheme.primary,
            width: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        );
      case CustomButtonStyle.primary:
      case CustomButtonStyle.gradient:
        return ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        );
    }
  }
}
