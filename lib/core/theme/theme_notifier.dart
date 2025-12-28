import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';

final themeProvider =
    NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeMode> {
  // Depolama anahtarı
  static const String _themeKey = 'theme_mode';

  @override
  ThemeMode build() {
    // Başlangıçta sistem varsayılanını veriyoruz
    _loadThemeFromSecureStorage();
    return ThemeMode.system;
  }

  /// 💾 Secure Storage'dan temayı yükler
  Future<void> _loadThemeFromSecureStorage() async {
    try {
      // SharedPreferences yerine senin LocalStorageService'ini kullanıyoruz
      // Ancak LocalStorageService içinde henüz theme için metod yoksa
      // doğrudan _storage.read kullanabiliriz veya LocalStorageService'e ekleyebilirsin

      // Şimdilik LocalStorageService üzerinden String olarak okuyoruz:
      final String? themeString =
          await LocalStorageService.readSecureData(_themeKey);

      if (themeString != null) {
        state = _parseThemeMode(themeString);
      }
    } catch (e) {
      debugPrint('Theme loading error: $e');
    }
  }

  /// 💾 Temayı kaydeder ve durumu günceller
  Future<void> setTheme(final ThemeMode theme) async {
    try {
      state = theme;
      // Enum'ın ismini (light, dark, system) String olarak kaydediyoruz
      await LocalStorageService.writeSecureData(_themeKey, theme.name);
    } catch (e) {
      debugPrint('Theme saving error: $e');
    }
  }

  /// String'i Enum'a çevirir
  ThemeMode _parseThemeMode(final String themeString) {
    return ThemeMode.values.firstWhere(
      (e) => e.name == themeString,
      orElse: () => ThemeMode.system,
    );
  }

  /// 🔄 Temayı tersine çevirir (Toggle)
  Future<void> toggleTheme(final BuildContext context) async {
    if (state == ThemeMode.system) {
      final isPlatformDark =
          View.of(context).platformDispatcher.platformBrightness ==
              Brightness.dark;
      await setTheme(isPlatformDark ? ThemeMode.light : ThemeMode.dark);
    } else {
      final newTheme =
          state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      await setTheme(newTheme);
    }
  }
}
