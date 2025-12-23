import 'dart:ui';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // SystemChrome için gerekli
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:ticketapp/features/splash/presentation/widgets/splash_data_guard.dart';
import 'core/config/firebase_options.dart';
import 'core/config/router/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/network/connectivity_wrapper.dart';
import 'core/services/local_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'core/theme/web_theme.dart';
import 'core/util/platform_checker.dart';
import 'features/login/presentation/providers/login_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // 1. Firebase'i Başlat
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Android 15 ve Uçtan Uca Ekran Uyumluluğu
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    // Simgeler siyah (Açık tema varsayılan)
    statusBarBrightness: Brightness.light,
    // iOS için
    systemNavigationBarColor: Colors.transparent,
    // navigationBarColor değil, budur!
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  // Crashlytics Yapılandırması
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Asenkron hataları (Future, Stream vb.) yakala
  PlatformDispatcher.instance.onError = (final error, final stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Local Storage Başlatma
  try {
    await LocalStorageService.init();
  } catch (e) {
    debugPrint('❌ LocalStorage Hatası: $e');
  }

  // Messaging İzinleri (Hızlıca üzerinden geçiyoruz)
  try {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
  } catch (e) {
    debugPrint('⚠️ Messaging Hatası: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final bool isWeb = PlatformChecker.isWeb;
    final router = ref.watch(appRouterProvider);
    final loginState = ref.watch(loginProvider);
    final bool isAuthLoading = !isWeb && loginState.isLoading;

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: isWeb ? WebTheme.darkTheme : AppTheme.darkTheme,
      themeMode: isWeb ? ThemeMode.dark : themeMode,
      builder: (final context, final child) {
        final safeChild = child ?? const SizedBox.shrink();

        return ConnectivityWrapper(
          child: SplashDataGuard(
            isLoading: isAuthLoading,
            loadingMessage: 'TiyatRol Başlatılıyor...',
            child: safeChild,
          ),
        );
      },
    );
  }
}
