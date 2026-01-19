import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

abstract final class RemoteConfigService {
  static final _remoteConfig = FirebaseRemoteConfig.instance;

  // 🔔 UI'ı tetikleyecek olan notifier
  static final ValueNotifier<bool> adsEnabledNotifier = ValueNotifier(true);

  static Future<void> init() async {
    try {
      // Varsayılan değerler
      await _remoteConfig.setDefaults({'adsEnabled': true});

      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval:
            kDebugMode ? Duration.zero : const Duration(hours: 6),
      ));

      await _remoteConfig.fetchAndActivate();

      // Değeri güncelle
      adsEnabledNotifier.value = _remoteConfig.getBool('adsEnabled');
      debugPrint(
          '☁️ RemoteConfig hazır. adsEnabled: ${adsEnabledNotifier.value}');
    } catch (e) {
      debugPrint('☁️ RemoteConfig hata: $e');
    }
  }

  static bool get adsEnabled => adsEnabledNotifier.value;
}
