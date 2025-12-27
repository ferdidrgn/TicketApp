import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import '../util/platform_checker.dart';

abstract final class AppCheckService {
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
}
