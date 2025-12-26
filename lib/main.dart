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
import 'core/services/fcm_manager_service.dart';
import 'core/services/local_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'core/theme/web_theme.dart';
import 'core/util/platform_checker.dart';
import 'features/login/presentation/providers/login_provider.dart';
import 'features/splash/presentation/widgets/splash_data_guard.dart';

// 1. ARKA PLAN BİLDİRİM NÖBETÇİSİ (Background Handler)
// -----------------------------------------------------------------------------
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(
        final RemoteMessage message) async =>
    Firebase.initializeApp(
        options: DefaultFirebaseOptions
            .currentPlatform); // Arka planda Firebase servislerini kullanabilmek için tekrar initialize

Future<void> main() async {
  // 1. Flutter Motorunu Hazırla
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // 2. Firebase Başlatma (Güvenli Zaman Aşımlı)
  try {
    await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform)
        .timeout(const Duration(seconds: 5));
  } catch (e) {
    debugPrint("Firebase Başlatma Atlandı: $e");
  }

  // 3. İzleme ve Bildirimler
  _setupCrashlytics();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 4. Sistem Arayüz Ayarları
  if (!PlatformChecker.isWeb) _configureSystemUI();

  // 5. Arka Plan Servislerini Tetikle (Uygulamayı Bekletmez)
  _initServices();

  runApp(const ProviderScope(child: MyApp()));
}

void _configureSystemUI() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

void _setupCrashlytics() {
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (final error, final stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

// await kullanmıyoruz, uygulama açılırken bunlar arkada dolmaya başlar
void _initServices() => Future.wait([
      LocalStorageService.init(),
      FCMManager.instance.init(),
    ]);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // 1. Watchers (State Takibi)
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(appRouterProvider);
    final loginState = ref.watch(loginProvider);
    final isWeb = PlatformChecker.isWeb;

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: isWeb ? WebTheme.darkTheme : AppTheme.darkTheme,
      themeMode: isWeb ? ThemeMode.dark : themeMode,
      builder: (final context, final child) {
        if (child == null) return const SizedBox.shrink();

        // 3. Platform Specific UI Wrapping
        return ConnectivityWrapper(
          child: SplashDataGuard(
            // Eğer internet yoksa (hasError), isLoading true olsa bile
            // SplashDataGuard içindeki hata ekranını tetiklemek için bu mantığı kurduk
            isLoading: loginState.isLoading,
            loadingMessage: loginState.hasError
                ? loginState.errorMessage!
                : 'TiyatRol Sahnesi Hazırlanıyor...',
            child: isWeb ? child : _MobileSystemUIWrapper(child: child),
          ),
        );
      },
    );
  }
}

class _MobileSystemUIWrapper extends StatelessWidget {
  final Widget child;

  const _MobileSystemUIWrapper({required this.child});

  @override
  Widget build(final BuildContext context) {
    //Extentions ı çağırma! Çünkü app daha açılmadı.
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: child,
    );
  }
}
