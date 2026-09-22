import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../common/enum/enums.dart';
import '../services/local_storage_service.dart';

final themeProvider =
    NotifierProvider<ThemeNotifier, AppThemeStyle>(ThemeNotifier.new);

/// Kullanıcının "Tema Rengi" ekranından seçtiği özel vurgu rengi.
/// `AppThemeStyle.custom` seçiliyken `ThemeManager` bu rengi `seedColor`
/// olarak kullanır. `ThemeNotifier.setCustomAccentColor()` ile senkron
/// tutulur — biri diğerini set etmeden yalnız başına anlamlı değildir.
final customAccentColorProvider =
    NotifierProvider<CustomAccentColorNotifier, Color?>(
        CustomAccentColorNotifier.new);

class CustomAccentColorNotifier extends Notifier<Color?> {
  static const String _colorKey = 'app_custom_accent_color_v1';

  @override
  Color? build() {
    Future.microtask(() => _loadColor());
    return null; // Kayıtlı özel renk yüklenene / seçilene kadar null
  }

  Future<void> _loadColor() async {
    final saved = await LocalStorageService.readSecureData(_colorKey);
    if (saved != null) {
      final value = int.tryParse(saved);
      if (value != null) state = Color(value);
    }
  }

  Future<void> setColor(final Color color) async {
    state = color;
    await LocalStorageService.writeSecureData(
        _colorKey, color.value.toString());
  }
}

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

  /// Kullanıcının Ayarlar'dan renk ızgarasından seçtiği rengi kalıcı tutar
  /// ve temayı otomatik olarak `AppThemeStyle.custom`'a geçirir. İki
  /// provider'ı (`themeProvider` + `customAccentColorProvider`) senkron
  /// tutan tek giriş noktası budur.
  Future<void> setCustomAccentColor(final Color color) async {
    await ref.read(customAccentColorProvider.notifier).setColor(color);
    await setTheme(AppThemeStyle.custom);
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
      case AppThemeStyle.custom:
      case AppThemeStyle.system:
        return ThemeMode.system;
    }
  }
}
