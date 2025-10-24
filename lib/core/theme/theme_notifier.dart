import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tema modu yönetimi için provider
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

/// Uygulama tema modunu yöneten Notifier sınıfı
/// Web'de light mode, mobilde SharedPreferences'tan yükleme yapar
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    if (kIsWeb) return ThemeMode.light;


    _loadThemeFromStorage();
    return ThemeMode.system;
  }

  Future<void> _loadThemeFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString('themeMode') ?? 'system';
    state = _parseThemeMode(themeString);
  }

  Future<void> setTheme(final ThemeMode theme) async {
    if (kIsWeb) return; // Web'de tema değişimi engellenir

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', theme.name); //theme.toString().split('.').last
    state = theme;
  }

  ThemeMode _parseThemeMode(final String themeString) {
    return switch (themeString) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
