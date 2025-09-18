import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static const String _prefKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeService() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? mode = prefs.getString(_prefKey);
      switch (mode) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
      notifyListeners();
    } catch (_) {
      // Ignore persistence errors
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      String value = 'system';
      if (mode == ThemeMode.light) value = 'light';
      if (mode == ThemeMode.dark) value = 'dark';
      await prefs.setString(_prefKey, value);
    } catch (_) {
      // Ignore persistence errors
    }
  }

  Future<void> toggleDarkMode(bool enable) async {
    await setThemeMode(enable ? ThemeMode.dark : ThemeMode.light);
  }
}


