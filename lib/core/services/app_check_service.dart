import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart'; // kReleaseMode ve kIsWeb için

abstract final class AppCheckService {
  static Future<void> init() async {
    // Web ise pas geç
    if (kIsWeb) return;

    await FirebaseAppCheck.instance.activate(
      // 🔥 DÜZELTME BURASI:
      // Eski: providerAndroid: AndroidPlayIntegrityProvider()  <-- BU ARTIK YOK
      // Yeni: androidProvider: AndroidProvider.playIntegrity   <-- DOĞRUSU BU

      androidProvider: kReleaseMode
          ? AndroidProvider.playIntegrity // Play Store (Release)
          : AndroidProvider.debug, // Bilgisayar (Debug)

      appleProvider: kReleaseMode
          ? AppleProvider.deviceCheck // iOS Release
          : AppleProvider.debug, // iOS Debug
    );
  }
}

/*abstract final class AppCheckService {
  static Future<void> init() async {
    // Web için şu anlık boş geçiyoruz (İhtiyaç olursa ReCaptcha eklenir)
    if (PlatformChecker.isWeb)
      return; //FirebaseAppCheck.instance.activate(providerWeb: ReCaptchaV3Provider('RECAPTCHA_SITE_KEY'));

    await FirebaseAppCheck.instance.activate(
      providerAndroid:
          kDebugMode ? AndroidDebugProvider() : AndroidPlayIntegrityProvider(),
      providerApple:
          kDebugMode ? AppleDebugProvider() : AppleDeviceCheckProvider(),
    );
  }
}*/
