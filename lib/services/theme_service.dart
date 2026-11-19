import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available global application themes for Cognitive Gym.
enum AppThemeMode { dark, light }

/// Singleton service managing theme state and persistent storage.
class ThemeService extends ChangeNotifier {
  ThemeService._();

  static final ThemeService instance = ThemeService._();
  static const String _themeKey = 'selected_app_theme';

  AppThemeMode _currentTheme = AppThemeMode.light;

  AppThemeMode get currentTheme => _currentTheme;

  /// Initializes the theme from local storage with legacy migration.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeStr = prefs.getString(_themeKey);
      if (savedThemeStr == 'dark') {
        _currentTheme = AppThemeMode.dark;
      } else if (savedThemeStr == 'light') {
        _currentTheme = AppThemeMode.light;
      } else if (savedThemeStr == 'forest' || savedThemeStr == 'violet') {
        // Safe migration: legacy forest and violet preferences migrate cleanly to dark
        _currentTheme = AppThemeMode.dark;
        await prefs.setString(_themeKey, 'dark');
      } else {
        // Default to light mode
        _currentTheme = AppThemeMode.light;
      }
    } catch (_) {
      _currentTheme = AppThemeMode.light;
    }
    notifyListeners();
  }

  /// Sets the application theme and persists choice to storage.
  Future<void> setTheme(AppThemeMode theme) async {
    final changed = _currentTheme != theme;
    _currentTheme = theme;
    if (changed) {
      notifyListeners();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, theme.name);
    } catch (_) {}
  }
}
