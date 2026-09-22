import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart'; // kReleaseMode ve kIsWeb için

abstract final class AppCheckService {
  // google.com/recaptcha/admin'de oluşturulan reCAPTCHA v3 SITE KEY (Secret
  // Key DEĞİL — o hiçbir zaman uygulama koduna girmez, sadece Firebase
  // Console'un reCAPTCHA kayıt ekranında bir "secret key" alanı varsa oraya
  // girilir). Site key istemci tarafı, herkese açık bir anahtardır —
  // Maps anahtarının aksine kodda düz yazılması normal, gizlenmesine
  // gerek yok.
  static const String _webRecaptchaSiteKey = '6LfS18ktAAAAAE9vhOD22QbK9cB1Vt1SgU7zJuAT';

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
