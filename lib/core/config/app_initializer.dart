import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  static Future<void> init(final WidgetsBinding binding) async {
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
        // Firestore'un ilk sorgusundan ÖNCE, offline persistence ayarını
        // yap — `settings` bir kez okunduktan/ilk sorgu yapıldıktan sonra
        // değiştirilemez, bu yüzden bu çağrı burada, uygulamanın herhangi
        // bir Firestore erişiminden önceki tek yerde duruyor.
        _configureFirestorePersistence();
        await AppCheckService.init();
        if (!kIsWeb) {
          _setupCrashlytics();
        }
      }
    } catch (e) {
      debugPrint('🔥 Firebase hata: $e');
    }
  }

  /// Firestore'un yerleşik çevrimdışı önbelleğini (offline persistence)
  /// açar. Bu SDK-seviyesinde bir özellik ve varsayılan olarak KAPALI
  /// geliyor — açılmadığı sürece, `cloud_firestore` üzerinden yapılan her
  /// sorgu bağlantı koptuğunda direkt hata fırlatır (uygulamanın kendi ağ
  /// katmanı yok, tüm veri Firestore SDK'sı üzerinden geliyor — bkz.
  /// `pubspec.yaml`: `dio` bağımlılığı ekli ama `lib/` içinde HİÇBİR yerde
  /// `import 'package:dio/dio.dart'` yok, fiilen kullanılmıyor).
  ///
  /// `cloud_firestore: 6.1.0` — web'e özel ayrı `enablePersistence()`
  /// metodu bu sürümde YOK (eski bir API varsayımıydı, kaldırılmış);
  /// `Settings(persistenceEnabled: ...)` artık mobil/masaüstü VE web'de
  /// aynı, tek/birleşik API. Platforma göre dallanmaya gerek kalmadı.
  static void _configureFirestorePersistence() {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      // Zaten açık (ör. hot-restart) ya da bu platformda desteklenmiyor —
      // persistence olmadan devam et, init akışını çökertme.
      debugPrint('🗄️ Firestore persistence ayarlanamadı: $e');
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
