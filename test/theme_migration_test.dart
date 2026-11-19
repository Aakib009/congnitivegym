import 'package:cognitive_gym/services/theme_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeService Migration & Persistence Tests', () {
    test('Defaults to Light theme when no preference is saved', () async {
      SharedPreferences.setMockInitialValues({});
      await ThemeService.instance.init();

      expect(ThemeService.instance.currentTheme, AppThemeMode.light);
    });

    test('Safely migrates legacy "forest" preference to Dark without touching unrelated data', () async {
      SharedPreferences.setMockInitialValues({
        'selected_app_theme': 'forest',
        'unrelated_user_setting': 'keep_me_intact',
        'user_xp_cache': 1250,
      });

      await ThemeService.instance.init();

      expect(ThemeService.instance.currentTheme, AppThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_app_theme'), 'dark');
      // Verify unrelated settings are completely preserved
      expect(prefs.getString('unrelated_user_setting'), 'keep_me_intact');
      expect(prefs.getInt('user_xp_cache'), 1250);
    });

    test('Safely migrates legacy "violet" preference to Dark', () async {
      SharedPreferences.setMockInitialValues({
        'selected_app_theme': 'violet',
        'sound_enabled': true,
      });

      await ThemeService.instance.init();

      expect(ThemeService.instance.currentTheme, AppThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_app_theme'), 'dark');
      expect(prefs.getBool('sound_enabled'), true);
    });

    test('Correctly loads saved "light" preference', () async {
      SharedPreferences.setMockInitialValues({
        'selected_app_theme': 'light',
      });

      await ThemeService.instance.init();

      expect(ThemeService.instance.currentTheme, AppThemeMode.light);
    });

    test('Correctly loads saved "dark" preference', () async {
      SharedPreferences.setMockInitialValues({
        'selected_app_theme': 'dark',
      });

      await ThemeService.instance.init();

      expect(ThemeService.instance.currentTheme, AppThemeMode.dark);
    });

    test('Switching theme updates in-memory state and persists to storage', () async {
      SharedPreferences.setMockInitialValues({});
      await ThemeService.instance.init();

      await ThemeService.instance.setTheme(AppThemeMode.light);
      expect(ThemeService.instance.currentTheme, AppThemeMode.light);

      var prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_app_theme'), 'light');

      await ThemeService.instance.setTheme(AppThemeMode.dark);
      expect(ThemeService.instance.currentTheme, AppThemeMode.dark);

      prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_app_theme'), 'dark');
    });
  });
}
