import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../enum/enums.dart';
import '../services/local_storage_service.dart';

final themeProvider =
    NotifierProvider<ThemeNotifier, AppThemePreference>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<AppThemePreference> {
  static const String _themeKey = 'app_theme_preference';

  @override
  AppThemePreference build() {
    // Build işlemi bittikten hemen sonra yüklemeyi başlat
    Future.microtask(() => _loadThemeFromStorage());

    // Varsayılan olarak Sistem (veya Monet) başlat
    return AppThemePreference.system;
  }

  /// 💾 Kayıtlı tercihi yükle
  Future<void> _loadThemeFromStorage() async {
    try {
      final String? themeString =
          await LocalStorageService.readSecureData(_themeKey);

      if (themeString != null)
        state = AppThemePreference.values.firstWhere(
          (final e) => e.name == themeString,
          orElse: () => AppThemePreference.system,
        );
    } catch (e) {
      debugPrint('Tema yükleme hatası: $e');
    }
  }

  /// 💾 Tercihi kaydet ve güncelle
  Future<void> setTheme(final AppThemePreference preference) async {
    try {
      state = preference;
      await LocalStorageService.writeSecureData(_themeKey, preference.name);
    } catch (e) {
      debugPrint('Tema kaydetme hatası: $e');
    }
  }

  // --- HESAPLANAN ÖZELLİKLER (Helper Getters) ---

  /// 1. MaterialApp için gerekli ThemeMode'u hesaplar
  ThemeMode get currentThemeMode {
    switch (state) {
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
      case AppThemePreference.system:
      case AppThemePreference.monet:
        // Monet de sistemin aydınlık/karanlık moduna uyar
        return ThemeMode.system;
    }
  }

  /// 2. Dinamik renklerin (Monet) açık olup olmadığını söyler
  bool get isDynamicColorEnabled => state == AppThemePreference.monet;
}
