import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart'; // kReleaseMode ve kIsWeb için

abstract final class AppCheckService {
  // Firebase Console > Build > App Check > Web uygulaması > "reCAPTCHA v3"
  // sağlayıcısını kaydettiğinde üretilen SITE KEY buraya gelir. Bu bir
  // "secret key" DEĞİL — reCAPTCHA v3 site anahtarları istemci tarafı,
  // herkese açık anahtarlardır (doğrulama Firebase'in kendi backend'inde
  // yapılır), o yüzden Maps anahtarının aksine kodda düz yazılması normal
  // ve beklenen bir kullanım — gizlenmesine gerek yok.
  static const String _webRecaptchaSiteKey = 'TODO_RECAPTCHA_V3_SITE_KEY';

  static Future<void> init() async {
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider(_webRecaptchaSiteKey),

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
