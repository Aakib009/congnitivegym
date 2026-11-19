import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/animal_avatar.dart';
import '../services/sound_service.dart';
import '../utils/app_colors.dart';
import 'animal_avatar_painters.dart';

/// Unified interactive Avatar Selector for Cognitive Gym.
/// Combines selection and preview into a single prominent, horizontally scrollable carousel
/// flanked by directional chevron controls with clean boundary clipping,
/// animated theme rings, selection glow, checkmark badges, and animal names.
class AvatarSelector extends StatefulWidget {
  final String selectedAvatarId;
  final ValueChanged<String> onAvatarSelected;
  final double previewSize;
  final bool showHeader;

  const AvatarSelector({
    super.key,
    required this.selectedAvatarId,
    required this.onAvatarSelected,
    this.previewSize = 84.0,
    this.showHeader = true,
  });

  @override
  State<AvatarSelector> createState() => _AvatarSelectorState();
}

class _AvatarSelectorState extends State<AvatarSelector> {
  late final ScrollController _scrollController;
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateScrollButtons);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final normalizedId = AppAvatars.normalize(widget.selectedAvatarId);
      final index = AppAvatars.all.indexWhere((a) => a.id == normalizedId);
      if (index >= 0) {
        _scrollToIndex(index, animate: false);
      }
      _updateScrollButtons();
    });
  }

  @override
  void didUpdateWidget(AvatarSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedAvatarId != widget.selectedAvatarId) {
      final normalizedId = AppAvatars.normalize(widget.selectedAvatarId);
      final index = AppAvatars.all.indexWhere((a) => a.id == normalizedId);
      if (index >= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToIndex(index, animate: true);
          _updateScrollButtons();
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollButtons);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    if (!mounted ||
        !_scrollController.hasClients ||
        !_scrollController.position.hasContentDimensions) {
      return;
    }
    final offset = _scrollController.offset;
    final max = _scrollController.position.maxScrollExtent;
    final canLeft = offset > 1.0;
    final canRight = offset < (max - 1.0);
    if (canLeft != _canScrollLeft || canRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = canLeft;
        _canScrollRight = canRight;
      });
    }
  }

  void _scrollLeft() {
    if (!_canScrollLeft || !_scrollController.hasClients) return;
    SoundService.instance.playSoftTap();
    final step = widget.previewSize + 16.0;
    final target = (_scrollController.offset - step).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollRight() {
    if (!_canScrollRight || !_scrollController.hasClients) return;
    SoundService.instance.playSoftTap();
    final step = widget.previewSize + 16.0;
    final target = (_scrollController.offset + step).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollToIndex(int index, {bool animate = true}) {
    if (!mounted ||
        !_scrollController.hasClients ||
        !_scrollController.position.hasContentDimensions) {
      return;
    }
    final itemWidth = widget.previewSize + 16.0;
    final viewportWidth = _scrollController.position.viewportDimension;
    // 16.0 is horizontal padding in SingleChildScrollView
    final itemCenter = 16.0 + (index * itemWidth) + (itemWidth / 2);
    final targetOffset = (itemCenter - (viewportWidth / 2)).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    if (animate) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(targetOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final normalizedId = AppAvatars.normalize(widget.selectedAvatarId);
    final currentAvatar = AppAvatars.getById(normalizedId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.showHeader) ...[
          // Header Badge
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? currentAvatar.themeColor.withAlpha(40)
                    : currentAvatar.themeColor.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: currentAvatar.themeColor.withAlpha(80),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pets_rounded,
                    size: 12,
                    color: currentAvatar.themeColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'CHOOSE YOUR AVATAR',
                    style: GoogleFonts.barlowCondensed(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: currentAvatar.themeColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Directional Arrows and Clipped Viewport Container Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Chevron Arrow Control
            _buildArrowButton(
              isLeft: true,
              isDark: isDark,
              accentColor: currentAvatar.themeColor,
            ),
            const SizedBox(width: 6),

            // Clipped Viewport Container: Avatars are strictly kept within boundaries
            Expanded(
              child: Container(
                height: widget.previewSize + 60.0,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceContainerLow.withAlpha(70)
                      : AppColors.surfaceLightClean.withAlpha(140),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderSubtle.withAlpha(70)
                        : AppColors.borderLightClean,
                    width: 1.0,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                      PointerDeviceKind.stylus,
                    },
                  ),
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: AppAvatars.all.asMap().entries.map((entry) {
                        final index = entry.key;
                        final avatar = entry.value;
                        final isSelected = avatar.id == normalizedId;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _AvatarCarouselItem(
                            avatar: avatar,
                            isSelected: isSelected,
                            isDark: isDark,
                            size: widget.previewSize,
                            onTap: () {
                              SoundService.instance.playSoftTap();
                              widget.onAvatarSelected(avatar.id);
                              _scrollToIndex(index, animate: true);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Right Chevron Arrow Control
            _buildArrowButton(
              isLeft: false,
              isDark: isDark,
              accentColor: currentAvatar.themeColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildArrowButton({
    required bool isLeft,
    required bool isDark,
    required Color accentColor,
  }) {
    final isEnabled = isLeft ? _canScrollLeft : _canScrollRight;

    return Semantics(
      label: isLeft ? 'Scroll left' : 'Scroll right',
      button: true,
      enabled: isEnabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey(
            isLeft ? 'avatar_carousel_arrow_left' : 'avatar_carousel_arrow_right',
          ),
          onTap: isEnabled ? (isLeft ? _scrollLeft : _scrollRight) : null,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isEnabled ? 1.0 : 0.25,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? (isEnabled
                        ? AppColors.surfaceContainerHigh
                        : AppColors.surfaceContainerLow)
                    : (isEnabled
                        ? AppColors.cardLight
                        : AppColors.groundLight),
                border: Border.all(
                  color: isEnabled
                      ? (isDark
                          ? AppColors.borderSubtle
                          : AppColors.borderLightClean)
                      : (isDark
                          ? AppColors.borderSubtle.withAlpha(50)
                          : AppColors.borderLightClean.withAlpha(50)),
                  width: 1.2,
                ),
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: Colors.black.withAlpha(isDark ? 30 : 10),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Icon(
                  isLeft
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  size: 20,
                  color: isEnabled
                      ? (isDark
                          ? AppColors.textPrimary
                          : AppColors.textPrimaryLight)
                      : (isDark
                          ? AppColors.textMuted
                          : AppColors.textMutedLight),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// An individual prominent animal avatar item in the unified carousel.
class _AvatarCarouselItem extends StatelessWidget {
  final AnimalAvatarInfo avatar;
  final bool isSelected;
  final bool isDark;
  final double size;
  final VoidCallback onTap;

  const _AvatarCarouselItem({
    required this.avatar,
    required this.isSelected,
    required this.isDark,
    required this.size,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${avatar.name} avatar, ${isSelected ? "selected" : "not selected"}',
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size),
        splashColor: avatar.themeColor.withAlpha(40),
        highlightColor: Colors.transparent,
        child: AnimatedScale(
          scale: isSelected ? 1.08 : 0.93,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Prominent Avatar Circle
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutBack,
                    width: size,
                    height: size,
                    padding: const EdgeInsets.all(3.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? avatar.themeColor
                            : (isDark
                                ? AppColors.borderSubtle
                                : AppColors.borderLightClean),
                        width: isSelected ? 2.8 : 1.4,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: avatar.themeColor
                                    .withAlpha(isDark ? 95 : 65),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black
                                    .withAlpha(isDark ? 25 : 12),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Opacity(
                          opacity: isSelected ? 1.0 : 0.82,
                          child: CustomPaint(
                            size: Size(size, size),
                            painter: AnimalAvatarPainter.forId(avatar.id),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Active checkmark indicator on top-right of selected avatar
                  if (isSelected)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: AnimatedScale(
                        scale: isSelected ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutBack,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: avatar.themeColor,
                            border: Border.all(
                              color: isDark
                                  ? AppColors.surfaceCanvas
                                  : Colors.white,
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(50),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),

              // Animal Name Label underneath
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.barlowCondensed(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.4,
                  color: isSelected
                      ? avatar.themeColor
                      : (isDark
                          ? AppColors.textSecondary
                          : AppColors.textSecondaryLight),
                ),
                child: Text(avatar.name),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
