// theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  final SharedPreferences prefs;

  ThemeMode get themeMode => _themeMode;

  ThemeProvider(this.prefs) {
    _loadTheme();
  }

  void toggleTheme() async {
    _themeMode = (_themeMode == ThemeMode.dark) ? ThemeMode.light : ThemeMode.dark;

    await _saveTheme();
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final isDark = prefs.getBool('isDarkTheme') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    prefs.setBool('isDarkTheme', _themeMode == ThemeMode.dark);
  }
}
