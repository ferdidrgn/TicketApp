import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../util/platform_checker.dart';

/// Tema modu yönetimi için provider
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

/// Uygulama tema modunu yöneten Notifier sınıfı
/// Web'de dark mode, mobilde SharedPreferences'tan yükleme yapar
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    if (PlatformChecker.isWeb) return ThemeMode.dark; // Web'de her zaman dark

    _loadThemeFromStorage();
    return ThemeMode.system;
  }

  Future<void> _loadThemeFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString('themeMode') ?? 'system';
      state = _parseThemeMode(themeString);
    } catch (e) {
      debugPrint('Theme loading error: $e');
      state = ThemeMode.system;
    }
  }

  Future<void> setTheme(final ThemeMode theme) async {
    if (PlatformChecker.isWeb) return; // Web'de tema değişimi engellenir

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('themeMode', theme.toString().split('.').last);
      state = theme;
    } catch (e) {
      debugPrint('Theme saving error: $e');
    }
  }

  ThemeMode _parseThemeMode(final String themeString) {
    return switch (themeString) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  // Mobil uygulama için tema değiştirme metodu
  Future<void> toggleTheme() async {
    if (PlatformChecker.isWeb) return; // Web'de toggle yapma

    final newTheme = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setTheme(newTheme);
  }
}
