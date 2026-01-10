import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/app_check_service.dart';
import '../services/fcm_manager_service.dart';
import '../util/platform_checker.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
        final RemoteMessage message) async =>
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

abstract final class AppInitializer {
  static Future<void> init() async {
    // 1. Flutter bindings başlatılması (En önce bu gelmeli)
    WidgetsFlutterBinding.ensureInitialized();

    // 🌐 Web URL stratejisi (# işaretini kaldırır)
    if (PlatformChecker.isWeb) usePathUrlStrategy();

    // 💾 Yerel Veri Depolama (Secure Storage'ın init()'e ihtiyacı yoktur)
    // Eğer SharedPreferences kullanmaya devam edecekseniz init kalsın,
    // ama Secure Storage'da bu satırı siliyoruz veya sadece log basıyoruz.
    debugPrint('🔐 Güvenli depolama hazır.');

    // 🔥 Firebase Temel Kurulum
    await _initFirebase();
    await MobileAds.instance.initialize();

    // 🛡️ Güvenlik ve Hata Takibi (Firebase bağımlı servisler)
    if (Firebase.apps.isNotEmpty) {
      await AppCheckService.init();
      _setupCrashlytics();
    }

    // ☁️ Bildirim Yönetimi
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    if (!PlatformChecker.isWeb) await FCMManager.instance.init();

    // 📱 Sistem Arayüzü (StatusBar vb.)
    _configureSystemUI();
  }

  static Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('🔥 Firebase init hatası: $e');
    }
  }

  static void _setupCrashlytics() {
    if (kIsWeb) return;

    FlutterError.onError = (errorDetails) {
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
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
      ));
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }
}
