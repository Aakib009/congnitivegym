import 'package:flutter/material.dart';
import '../models/animal_avatar.dart';
import '../utils/app_colors.dart';
import 'animal_avatar_painters.dart';

/// A custom circular avatar widget rendering animal avatars in Cognitive Gym.
/// Supports all 7 animal options while defaulting to raccoon.
class RaccoonAvatar extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;
  final String avatarId;

  const RaccoonAvatar({
    super.key,
    this.size = 48.0,
    this.onTap,
    this.avatarId = AppAvatars.defaultAvatarId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? AppColors.cardDarkRaised : AppColors.cardLight,
          border: Border.all(
            color: colorScheme.primary.withAlpha(180),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 40 : 15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: CustomPaint(
            size: Size(size, size),
            painter: AnimalAvatarPainter.forId(avatarId),
          ),
        ),
      ),
    );
  }
}
