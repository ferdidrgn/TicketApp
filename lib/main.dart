import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
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
import 'features/splash/presentation/widgets/splash_data_guard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // Web'de url'deki # işaretini kaldırır

  // 1. Firebase Başlatma
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. Crashlytics Yapılandırması
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (final error, final stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // context olmadığında PlatformDispatcher bize cihazın parlaklık ayarını doğrudan verir.
  final bool isDarkMode =
      PlatformDispatcher.instance.platformBrightness == Brightness.dark;

  if (!PlatformChecker.isWeb) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness:
          isDarkMode ? Brightness.light : Brightness.dark,
    ));

    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  try {
    await LocalStorageService.init();
    await FirebaseMessaging.instance
        .requestPermission(alert: true, badge: true, sound: true);
  } catch (e) {
    debugPrint('Servis Başlatma Hatası: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(appRouterProvider);
    final loginState = ref.watch(loginProvider);
    final bool isWeb = PlatformChecker.isWeb;

    // Mobil'de auth yükleniyorsa SplashGuard devreye girer
    final bool isAuthLoading = !isWeb && loginState.isLoading;

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: isWeb ? WebTheme.darkTheme : AppTheme.darkTheme,
      themeMode: isWeb ? ThemeMode.dark : themeMode,
      builder: (final context, final child) {
        return ConnectivityWrapper(
          child: SplashDataGuard(
            isLoading: isAuthLoading,
            loadingMessage: 'TiyatRol Sahnesi Hazırlanıyor...',
            // child asılı kalmasın diye null check
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
