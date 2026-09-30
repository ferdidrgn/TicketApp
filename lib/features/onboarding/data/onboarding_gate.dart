import 'package:flutter/foundation.dart';

import '../../../core/services/local_storage_service.dart';

/// İlk açılış tanıtımının (onboarding) gösterilip gösterilmeyeceği.
///
/// Sadece mobil uygulamada, cihazda bir kez gösterilir. Web'e çoğu kişi
/// arama motorundan bir oyun sayfasına düşerek geldiği için web'de hiç
/// gösterilmez (kimseyi kapıda bekletmeyiz). Bayrak açılışta
/// [AppInitializer] tarafından bir kez okunur; router'ın `redirect`'i
/// senkron olduğu için değer bellekte tutulur.
abstract final class OnboardingGate {
  static const String _key = 'onboarding_seen_v1';

  static bool _shouldShow = false;
  static bool get shouldShow => _shouldShow;

  static Future<void> load() async {
    if (kIsWeb) return;
    try {
      _shouldShow = await LocalStorageService.readSecureData(_key) != 'true';
    } catch (_) {
      // Depolama okunamazsa tanıtımı zorlamayız.
      _shouldShow = false;
    }
  }

  static Future<void> markSeen() async {
    _shouldShow = false;
    try {
      await LocalStorageService.writeSecureData(_key, 'true');
    } catch (_) {}
  }
}
