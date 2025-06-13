import 'package:flutter/foundation.dart'; // kIsWeb için
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((final ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(kIsWeb ? ThemeMode.light : ThemeMode.system) {
    if (!kIsWeb) _loadTheme(); // Sadece mobilde yükle
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('themeMode') ?? 'system';
    state = _getThemeModeFromString(themeString);
  }

  Future<void> setTheme(final ThemeMode theme) async {
    if (kIsWeb) return; // Web'de tema değişimi engellenir

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', theme.toString().split('.').last);
    state = theme;
  }

  ThemeMode _getThemeModeFromString(final String themeString) {
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
