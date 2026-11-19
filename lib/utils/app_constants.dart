/// App-wide constants including strings, layout metrics, and animation durations.
abstract class AppConstants {
  // General Info
  static const String appName = 'Cognitive Gym';
  static const String appTagline = 'Competitive Cognitive Training Arcade';
  static const String appVersion = '1.0.0';

  // ===========================================================================
  // DESIGN.MD SPACING SCALE
  // ===========================================================================
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space6 = 24.0;
  static const double space8 = 32.0;
  static const double space12 = 48.0;

  // ===========================================================================
  // DESIGN.MD RADIUS TOKENS
  // ===========================================================================
  static const double radiusSmall = 6.0;
  static const double radiusControl = 8.0;
  static const double radiusPanel = 12.0;
  static const double radiusPill = 999.0;

  // Layout Spacing & Radius (Legacy Aliases)
  static const double paddingSmall = space2;
  static const double paddingMedium = space4;
  static const double paddingLarge = space6;
  static const double paddingXLarge = space8;

  static const double borderRadiusSmall = radiusControl;
  static const double borderRadiusMedium = radiusPanel;
  static const double borderRadiusLarge = 20.0;
  static const double borderRadiusPill = radiusPill;

  // Animation Durations
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 600);

  // Asset Directories
  static const String imagesPath = 'assets/images/';
  static const String iconsPath = 'assets/icons/';

  // Screen Names / Titles
  static const String titleHome = 'Dashboard';
  static const String titleTraining = 'Gym Modules';
  static const String titleJournal = 'Cognitive Log';
  static const String titleAbout = 'Architecture & Info';
}
