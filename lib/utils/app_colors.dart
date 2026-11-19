import 'package:flutter/material.dart';

/// Centralized, production-quality gaming-inspired design tokens for Cognitive Gym.
///
/// Foundation: Restrained tactical dark palette with high-contrast functional accents
/// and clean daylight theme support. Avoids generic SaaS templates and harsh multi-stop gradients.
abstract class AppColors {
  // ===========================================================================
  // TACTICAL TELEMETRY DESIGN SYSTEM SPECIFICATION TOKENS
  // ===========================================================================
  static const Color surfaceCanvas = Color(0xFF131313);       // Base canvas / surface-dim
  static const Color surfaceContainerLowest = Color(0xFF0E0E0E); // Deepest recessed tray
  static const Color surfaceContainerLow = Color(0xFF1C1B1B);    // Subtle inset background
  static const Color surfaceContainer = Color(0xFF201F1F);       // Standard card surface
  static const Color surfaceContainerHigh = Color(0xFF2A2A2A);   // Elevated card / hover state
  static const Color surfaceContainerHighest = Color(0xFF353534);// Brightest surface layer
  static const Color surfaceBright = Color(0xFF393939);          // Highlight surface
  
  static const Color onSurfaceText = Color(0xFFE5E2E1);          // High-visibility crisp text
  static const Color onSurfaceVariantText = Color(0xFFC0CAB1);   // Tactical muted green-gray
  static const Color outlineTactical = Color(0xFF8A947D);        // Tactical HUD border
  static const Color outlineVariantTactical = Color(0xFF414A36); // Subtle telemetry wireframe
  
  static const Color electricLime = Color(0xFFA7FF4F);          // Performance Lime primary
  static const Color tacticalLimeDim = Color(0xFF87DC2D);        // Dimmed lime for secondary cues
  static const Color tacticalGreen = Color(0xFF00C878);          // Logic / Matrix Green
  static const Color tacticalCyan = Color(0xFF4DB4F5);           // Observation / Vector Cyan
  static const Color tacticalYellow = Color(0xFFFFE000);         // Creativity / Math Yellow
  static const Color tacticalOrange = Color(0xFFFF7043);         // Decision / Alert Orange
  static const Color tacticalRed = Color(0xFFFFB4AB);            // Error / Alert Red
  static const Color tacticalMint = Color(0xFF3FE490);           // Secondary mint

  // ===========================================================================
  // DESIGN.MD SPECIFICATION TOKENS
  // ===========================================================================
  static const Color pageBackground = Color(0xFF171717);    // Main application background
  static const Color sidebarBackground = Color(0xFF151515); // Persistent desktop navigation
  static const Color surface = Color(0xFF252525);           // Game cards, quest cards, panels
  static const Color surfaceRaised = Color(0xFF303030);     // Inputs, progress tracks, secondary
  static const Color surfaceDeep = Color(0xFF101010);       // In-game play areas and inset regions
  static const Color borderSubtle = Color(0xFF3A3A3A);      // Separators and quiet outlines
  static const Color textPrimary = Color(0xFFF5F5F5);       // Primary labels and headings
  static const Color textSecondary = Color(0xFFA3A3A3);     // Descriptions and supporting metadata
  static const Color textMuted = Color(0xFF707070);         // Low-priority labels and inactive metadata
  static const Color brandLime = Color(0xFFA7FF4F);         // Brand emphasis, active nav, primary progress
  static const Color mathYellow = Color(0xFFFFE000);        // Math / Creativity accent
  static const Color memoryBlue = Color(0xFF4DB4F5);        // Memory / Observation accent
  static const Color puzzleGreen = Color(0xFF00C878);       // Puzzle / Debate accent
  static const Color logicPink = Color(0xFFEA438B);         // Logic category accent
  static const Color eventOrange = Color(0xFFFF7043);       // Event banners and Scenario Lab emphasis
  static const Color errorRed = Color(0xFFE34B4B);          // Errors only; never decorative

  // ===========================================================================
  // TACTICAL DARK FOUNDATION (PRIMARY BRAND EXPERIENCE)
  // ===========================================================================
  static const Color groundDark = pageBackground;           // #171717 Main application background
  static const Color surfaceDark = sidebarBackground;       // #151515 Shell & container background
  static const Color cardDark = surface;                    // #252525 Raised card & game panel
  static const Color cardDarkRaised = surfaceRaised;        // #303030 Active / hovered container
  static const Color borderDark = borderSubtle;             // #3A3A3A Subtle structural border
  static const Color borderDarkStrong = Color(0xFF4A4A4A);  // Focused / active outline
  static const Color textPrimaryDark = textPrimary;         // #F5F5F5 Crisp readable text
  static const Color textSecondaryDark = textSecondary;     // #A3A3A3 Muted metadata & labels
  static const Color textMutedDark = textMuted;             // #707070 De-emphasized footnotes & hints

  // ===========================================================================
  // CLEAN DAYLIGHT FOUNDATION (LIGHT THEME)
  // ===========================================================================
  static const Color groundLight = Color(0xFFF4F6F9);       // Refined slate canvas
  static const Color surfaceLightClean = Color(0xFFFFFFFF);  // Clean white surface
  static const Color cardLight = Color(0xFFE8EDF4);          // Structured tactical light card
  static const Color borderLightClean = Color(0xFFD0D7E2);   // Clean 1px dividing border
  static const Color borderLightStrong = Color(0xFF94A3B8);  // Active light border
  static const Color textPrimaryLight = Color(0xFF0F172A);   // High-contrast slate charcoal
  static const Color textSecondaryLight = Color(0xFF475569); // Balanced secondary information
  static const Color textMutedLight = Color(0xFF64748B);     // Muted light metadata

  // ===========================================================================
  // PURPOSEFUL GAMING ACCENTS (MATIKS-INSPIRED)
  // ===========================================================================
  static const Color primaryLimeDark = brandLime;          // #A7FF4F Vibrant gaming lime (Dark primary)
  static const Color primaryLimeLight = Color(0xFF15803D);  // Deep accessible lime green (Light primary, >4.5:1 contrast)
  static const Color accentYellow = mathYellow;             // #FFE000 Meaningful gaming yellow highlight
  static const Color accentYellowLight = Color(0xFFB45309); // Deep yellow/amber highlight for light mode
  static const Color accentAmber = Color(0xFFF59E0B);       // XP, mastery, prestige rewards
  static const Color accentCyan = memoryBlue;               // #4DB4F5 Memory & agility metrics
  static const Color accentIndigo = Color(0xFF6366F1);      // Secondary tactical CTA triggers
  static const Color accentEmerald = puzzleGreen;           // #00C878 Verified completions, streaks, success
  static const Color accentCrimson = errorRed;              // #E34B4B Dilemmas, urgent timers, debate counter-stance

  // ===========================================================================
  // 8 COMPETITIVE RANK BADGE COLORS
  // ===========================================================================
  static const Color rankBronze = Color(0xFFCD7F32);
  static const Color rankSilver = Color(0xFF94A3B8);
  static const Color rankGold = Color(0xFFF59E0B);
  static const Color rankPlatinum = Color(0xFF38BDF8);
  static const Color rankCrystal = Color(0xFFA855F7);
  static const Color rankDiamond = Color(0xFF06B6D4);
  static const Color rankMaster = Color(0xFFEC4899);
  static const Color rankGrandmaster = Color(0xFFEAB308);

  // ===========================================================================
  // LEGACY ALIASES (PRESERVED FOR BACKWARD COMPATIBILITY)
  // ===========================================================================
  static const Color darkBackground = groundDark;
  static const Color darkSurface = surfaceDark;
  static const Color darkCardSurface = cardDark;
  static const Color darkCardBorder = borderDark;

  static const Color lightBackground = groundLight;
  static const Color lightBackgroundClean = groundLight;
  static const Color lightSurface = surfaceLightClean;
  static const Color lightSurfaceClean = surfaceLightClean;
  static const Color lightCardSurface = cardLight;
  static const Color lightCardSurfaceClean = cardLight;
  static const Color lightBorderClean = borderLightClean;
  static const Color lightPrimary = accentIndigo;

  // Status & Utility Colors
  static const Color successGreen = accentEmerald;
  static const Color warningOrange = accentCrimson;
  static const Color infoBlue = accentCyan;
  static const Color solarYellow = accentAmber;
  static const Color warmAmber = accentAmber;

  // Botanical / Nature Legacy Aliases
  static const Color deepForest = Color(0xFF0F172A);
  static const Color pineGreen = Color(0xFF1E293B);
  static const Color emeraldMoss = Color(0xFF0F766E);
  static const Color leafGreen = accentEmerald;
  static const Color sageGreen = Color(0xFF34D399);
  static const Color mintMist = Color(0xFFA7F3D0);
  static const Color softDew = Color(0xFFE2E8F0);
  static const Color barkBrown = Color(0xFF1E293B);
  static const Color earthyBrown = Color(0xFF334155);
  static const Color terracotta = Color(0xFF94A3B8);
  static const Color goldenSand = Color(0xFFFDE68A);

}
