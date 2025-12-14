import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider =
    NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

/// Uygulama tema modunu yöneten Notifier sınıfı
/// Web'de dark mode, mobilde SharedPreferences'tan yükleme yapar
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadThemeFromStorage();
    return ThemeMode.system;
  }

  Future<void> _loadThemeFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Kayıtlı veri yoksa (ilk indirme) null döner, biz de 'system' varsayarız.
      final themeString = prefs.getString('themeMode');
      if (themeString != null)
        // Eğer kullanıcı daha önce bir seçim yapmışsa onu yükle
        state = _parseThemeMode(themeString);
      // else: Kayıt yoksa zaten build() metodunda ThemeMode.system döndürmüştük, dokunma.
    } catch (e) {
      debugPrint('Theme loading error: $e');
    }
  }

  Future<void> setTheme(final ThemeMode theme) async {
    // if (PlatformChecker.isWeb) return;

    try {
      state = theme; // Arayüzü hemen güncelle
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('themeMode', theme.toString().split('.').last);
    } catch (e) {
      debugPrint('Theme saving error: $e');
    }
  }

  // String'i Enum'a çevir
  ThemeMode _parseThemeMode(final String themeString) {
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // Toggle (Değiştirme) Fonksiyonu
  Future<void> toggleTheme(final BuildContext context) async {
    // if (PlatformChecker.isWeb) return;

    // Şu anki aktif mod SYSTEM ise, telefonun o anki haline bakıp tersini yapmalıyız
    if (state == ThemeMode.system) {
      final isPlatformDark =
          MediaQuery.platformBrightnessOf(context) == Brightness.dark;
      // Telefon Dark ise Light'a geç, Light ise Dark'a geç
      await setTheme(isPlatformDark ? ThemeMode.light : ThemeMode.dark);
    } else {
      // Zaten manuel seçilmişse tersine çevir
      final newTheme =
          state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      await setTheme(newTheme);
    }
  }
}
