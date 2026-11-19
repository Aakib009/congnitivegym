import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/theme_service.dart';
import 'app_colors.dart';

/// Defines the Material 3 gaming-inspired tactical design system for Cognitive Gym.
///
/// Features:
/// - Primary: Tactical Dark Console (#0B0E14) with Cognitive Cyan & Mastery Amber accents.
/// - Secondary: Clean Daylight Slate (#F4F6F9) with high-contrast text.
/// - Typography: Rajdhani for bold athletic headers/numeric data + Plus Jakarta Sans for reading comfort.
/// - Crisp, restrained 12px card borders (no exaggerated pills or excessive drop shadows).
class AppTheme {
  AppTheme._();

  /// Resolves ThemeData for a given AppThemeMode (dark or light).
  static ThemeData getThemeData(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.dark:
        return _buildDarkTacticalTheme();
      case AppThemeMode.light:
        return _buildLightTheme();
    }
  }

  /// Backward-compatible getters
  static ThemeData get lightTheme => getThemeData(AppThemeMode.light);
  static ThemeData get darkTheme => getThemeData(AppThemeMode.dark);

  /// 1. Tactical Dark Console Theme (Primary Competitive Experience)
  static ThemeData _buildDarkTacticalTheme() {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.brandLime,
      onPrimary: Color(0xFF131313),
      secondary: AppColors.mathYellow,
      onSecondary: Color(0xFF451A03),
      tertiary: AppColors.memoryBlue,
      onTertiary: Color(0xFF042F2E),
      error: AppColors.errorRed,
      onError: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.borderSubtle,
      outlineVariant: AppColors.borderDarkStrong,
      surfaceContainer: AppColors.surfaceRaised,
    );

    return _buildBaseTheme(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.pageBackground,
      cardColor: AppColors.surface,
      appBarTitleColor: AppColors.textPrimary,
    );
  }

  /// 2. Clean Daylight Slate Theme (Light Mode)
  static ThemeData _buildLightTheme() {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryLimeLight,
      onPrimary: Colors.white,
      secondary: AppColors.accentYellowLight,
      onSecondary: Colors.white,
      tertiary: AppColors.accentCyan,
      onTertiary: Colors.white,
      error: AppColors.accentCrimson,
      onError: Colors.white,
      surface: AppColors.surfaceLightClean,
      onSurface: AppColors.textPrimaryLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      outline: AppColors.borderLightClean,
      outlineVariant: AppColors.borderLightStrong,
      surfaceContainer: AppColors.cardLight,
    );

    return _buildBaseTheme(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.groundLight,
      cardColor: AppColors.cardLight,
      appBarTitleColor: AppColors.textPrimaryLight,
    );
  }

  /// Core Material 3 ThemeData Builder
  static ThemeData _buildBaseTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBackgroundColor,
    required Color cardColor,
    required Color appBarTitleColor,
  }) {
    final textTheme = _buildTextTheme(colorScheme.onSurface);
    final isDark = colorScheme.brightness == Brightness.dark;
    final dialogBackgroundColor =
        isDark ? AppColors.surface : AppColors.surfaceLightClean;
    final dialogBorderColor =
        isDark ? AppColors.borderSubtle : AppColors.borderLightClean;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      textTheme: textTheme,
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outline, width: 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.barlowCondensed(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.barlowCondensed(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.barlowCondensed(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dialogBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: dialogBorderColor),
        ),
        titleTextStyle: GoogleFonts.barlowCondensed(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: dialogBackgroundColor,
        modalBackgroundColor: dialogBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.rajdhani(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: appBarTitleColor,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: appBarTitleColor),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.brightness == Brightness.dark
            ? const Color(0xFF1B1B1B)
            : const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error, width: 1.0),
        ),
        labelStyle: GoogleFonts.barlowCondensed(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          color: colorScheme.onSurface.withAlpha(180),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: colorScheme.onSurface.withAlpha(100),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: colorScheme.outline,
            width: 1.0,
          ),
        ),
        color: cardColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.barlowCondensed(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primary.withAlpha(35),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.rajdhani(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
              letterSpacing: 0.2,
            );
          }
          return GoogleFonts.rajdhani(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withAlpha(160),
            letterSpacing: 0.2,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary, size: 22);
          }
          return IconThemeData(
            color: colorScheme.onSurface.withAlpha(160),
            size: 20,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainer,
        disabledColor: Colors.grey.shade800,
        selectedColor: colorScheme.primary,
        secondarySelectedColor: colorScheme.secondary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: GoogleFonts.rajdhani(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          letterSpacing: 0.2,
        ),
        secondaryLabelStyle: GoogleFonts.rajdhani(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimary,
          letterSpacing: 0.2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: colorScheme.outline, width: 1.0),
        ),
      ),
    );
  }

  /// Typographic pairing:
  /// - Barlow Condensed for athletic headers, numeric data, and rank tags.
  /// - Plus Jakarta Sans for body prose, editorial narrative, and input comfort.
  static TextTheme _buildTextTheme(Color baseTextColor) {
    return TextTheme(
      displayLarge: GoogleFonts.barlowCondensed(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: baseTextColor,
        height: 1.15,
      ),
      displayMedium: GoogleFonts.barlowCondensed(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: baseTextColor,
        height: 1.2,
      ),
      displaySmall: GoogleFonts.barlowCondensed(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: baseTextColor,
        height: 1.25,
      ),
      headlineMedium: GoogleFonts.barlowCondensed(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: baseTextColor,
        height: 1.25,
      ),
      headlineSmall: GoogleFonts.barlowCondensed(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: baseTextColor,
        height: 1.3,
      ),
      titleLarge: GoogleFonts.barlowCondensed(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: baseTextColor,
        height: 1.35,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: baseTextColor,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        color: baseTextColor,
        height: 1.55,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: baseTextColor.withAlpha(220),
        height: 1.5,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.normal,
        color: baseTextColor.withAlpha(170),
        height: 1.4,
      ),
      labelLarge: GoogleFonts.barlowCondensed(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: baseTextColor,
        letterSpacing: 0.2,
      ),
      labelSmall: GoogleFonts.barlowCondensed(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: baseTextColor,
        letterSpacing: 0.2,
      ),
    );
  }
}
