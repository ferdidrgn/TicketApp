import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../enum/enums.dart';
import '../services/local_storage_service.dart';

final themeProvider =
    NotifierProvider<ThemeNotifier, AppThemeStyle>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<AppThemeStyle> {
  static const String _themeKey = 'app_theme_style_v2';

  @override
  AppThemeStyle build() {
    Future.microtask(() => _loadTheme());
    return AppThemeStyle.system; // Varsayılan: Sistem (App Renkleri)
  }

  Future<void> _loadTheme() async {
    final saved = await LocalStorageService.readSecureData(_themeKey);
    if (saved != null)
      state = AppThemeStyle.values.firstWhere((final e) => e.name == saved,
          orElse: () => AppThemeStyle.system);
  }

  Future<void> setTheme(final AppThemeStyle style) async {
    state = style;
    await LocalStorageService.writeSecureData(_themeKey, style.name);
  }

  // --- Helper Getters ---
  ThemeMode get themeMode {
    switch (state) {
      case AppThemeStyle.appLight:
      case AppThemeStyle.materialLight:
        return ThemeMode.light;
      case AppThemeStyle.appDark:
      case AppThemeStyle.materialDark:
        return ThemeMode.dark;
      case AppThemeStyle.system:
        return ThemeMode.system;
    }
  }
}
