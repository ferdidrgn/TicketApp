import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../ads/ads_manager.dart';
import '../services/app_check_service.dart';
import '../services/remote_config_service.dart';
import '../util/date_formatter.dart';
import '../util/platform_checker.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    final RemoteMessage message) async {
  // Arka plan bildirimleri için Firebase'i başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

abstract final class AppInitializer {
  static Future<void> init() async {
    // 1. Flutter bindings başlatılması
    WidgetsFlutterBinding.ensureInitialized();

    // 🌐 Web URL stratejisi (# işaretini kaldırır)
    if (PlatformChecker.isWeb) usePathUrlStrategy();

    // 💾 Yerel Veri Depolama (Secure Storage'ın init()'e ihtiyacı yoktur)
    // Eğer SharedPreferences kullanmaya devam edecekseniz init kalsın,
    // ama Secure Storage'da bu satırı siliyoruz veya sadece log basıyoruz.
    debugPrint('🔐 Güvenli depolama hazır.');

    // Dil formatlarını hazırla
    await DateFormatter.initializeLocale();

    // 🔥 Firebase Temel Kurulum (Artık her platform için ortak)
    await _initFirebase();

    await RemoteConfigService.init();

    await AdManager.initialize();

    // 📢 Google Mobile Ads Başlatma
    if (kIsWeb) // Web'de bunları await etme, arka planda başlasınlar
      MobileAds.instance.initialize();
    else
      await MobileAds.instance.initialize();

    // 🛡️ Güvenlik ve Hata Takibi (Firebase bağımlı servisler)
    if (Firebase.apps.isNotEmpty) {
      await AppCheckService.init(); // App Check (Hacker koruması)
      // Crashlytics (Hata raporlama - Sadece Mobil)
      if (!kIsWeb) _setupCrashlytics();
    }

    // ☁️ Bildirim Yönetimi
    //FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    //if (!PlatformChecker.isWeb) await FCMManager.instance.init();

    // 📱 Sistem Arayüzü Ayarları
    _configureSystemUI();
    debugPrint('🚀 Sağlam Spot Sistemleri Hazır.');
  }

  static Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 10));
      debugPrint('🔥 Firebase başarıyla bağlandı.');
    } catch (e) {
      debugPrint('🔥 Firebase başlatma hatası: $e');
    }
  }

  static void _setupCrashlytics() {
    // Web'de Crashlytics desteklenmez, bu yüzden kontrol ekliyoruz
    FlutterError.onError = (final errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };

    PlatformDispatcher.instance.onError = (final error, final stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  static void _configureSystemUI() {
    if (!PlatformChecker.isWeb) {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        // Koyu ikonlar daha okunaklıdır
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ));
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }
}
