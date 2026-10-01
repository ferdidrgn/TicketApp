import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// İlk açılış tanıtımının (onboarding) gösterilip gösterilmeyeceği.
///
/// Sadece mobil uygulamada, cihazda bir kez gösterilir. Web'e çoğu kişi
/// arama motorundan bir oyun sayfasına düşerek geldiği için web'de hiç
/// gösterilmez. Bayrak açılışta [AppInitializer] tarafından bir kez
/// okunur; router'ın `redirect`'i senkron olduğu için değer bellekte
/// tutulur.
///
/// Neden `SharedPreferences` (güvenli depolama değil): uygulama silinince
/// kesin temizlenir (iOS Keychain silinmeden kalıyordu) ve Android
/// Keystore gibi ilk okumada hata verebilen bir katmana bağlı değildir.
/// Okuma yine de hata verirse tanıtım GÖSTERİLİR — zararsız bir ekran,
/// kullanıcı "Geç" ile tek dokunuşta çıkar.
abstract final class OnboardingGate {
  static const String _key = 'onboarding_seen_v2';

  static bool _shouldShow = false;
  static bool get shouldShow => _shouldShow;

  static Future<void> load() async {
    if (kIsWeb) {
      debugPrint('🎭 Onboarding: web — gösterilmiyor.');
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      _shouldShow = !(prefs.getBool(_key) ?? false);
    } catch (e) {
      _shouldShow = true;
      debugPrint('🎭 Onboarding: bayrak okunamadı ($e) — gösterilecek.');
    }
    debugPrint('🎭 Onboarding: ${_shouldShow ? 'ilk açılış, gösterilecek' : 'daha önce görülmüş'}.');
  }

  static Future<void> markSeen() async {
    _shouldShow = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (e) {
      debugPrint('🎭 Onboarding: bayrak yazılamadı ($e).');
    }
  }
}
