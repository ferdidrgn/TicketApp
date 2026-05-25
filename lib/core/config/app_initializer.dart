import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import '../ads/ads_manager.dart';
import '../services/app_check_service.dart';
import '../services/remote_config_service.dart';
import '../util/date_formatter.dart';
import '../util/platform_checker.dart';
import 'firebase_options.dart';

abstract final class AppInitializer {
  static Future<void> init(WidgetsBinding binding) async {
    // 1. Web URL Stratejisi
    if (PlatformChecker.isWeb) {
      usePathUrlStrategy();
    }

    // 2. Yerel Veri ve Servis Başlatma
    await DateFormatter.initializeLocale();
    await _initFirebase();

    await Future.wait([
      _safeInitializeRemoteConfig(),
      _safeInitializeAdEngine(),
    ]);

    debugPrint('🚀 TiyatRol Sistemleri Hazır.');
  }

  static void configureSystemUIPreBoot() {
    if (!kIsWeb) {
      // Android 15 Edge-to-Edge için şeffaf mod
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
      ));
    }
  }

  static Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 10));

      if (Firebase.apps.isNotEmpty) {
        await AppCheckService.init();
        if (!kIsWeb) {
          _setupCrashlytics();
        }
      }
    } catch (e) {
      debugPrint('🔥 Firebase hata: $e');
    }
  }

  static Future<void> _setupCrashlytics() {
    FlutterError.onError = (final errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (final error, final stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    return Future.value();
  }

  static Future<void> _safeInitializeRemoteConfig() async {
    try {
      await RemoteConfigService.init();
    } catch (_) {}
  }

  static Future<void> _safeInitializeAdEngine() async {
    try {
      await AdManager.initialize();
    } catch (_) {}
  }
}
