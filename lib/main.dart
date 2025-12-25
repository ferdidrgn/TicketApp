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
  // 1. Flutter Engine & Web Strategy
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // 2. Firebase & Error Monitoring (Paralel başlatma performansı artırır)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  _setupCrashlytics();

  // 3. Native UI Configuration (Mobile Only)
  if (!PlatformChecker.isWeb) _configureMobileSystemUI();

  // 4. Local Services
  await _initServices();

  runApp(const ProviderScope(child: MyApp()));
}

// --- Yardımcı Başlatma Metotları ---

void _setupCrashlytics() {
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (final error, final stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

void _configureMobileSystemUI() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}

Future<void> _initServices() async {
  try {
    await LocalStorageService.init();
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (e) {
    debugPrint('Service Initialization Error: $e');
  }
}

// =============================================================================
// ROOT APP COMPONENT
// =============================================================================

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // 1. Watchers (State Takibi)
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(appRouterProvider);
    final loginState = ref.watch(loginProvider);

    // 2. Performance: Pre-calculate values
    final bool isWeb = PlatformChecker.isWeb;
    final bool isAuthLoading = !isWeb && loginState.isLoading;

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: isWeb ? WebTheme.darkTheme : AppTheme.darkTheme,
      themeMode: isWeb ? ThemeMode.dark : themeMode,
      builder: (final context, final child) {
        final Widget safeChild = child ?? const SizedBox.shrink();

        // 3. Platform Specific UI Wrapping
        return ConnectivityWrapper(
          child: SplashDataGuard(
            isLoading: isAuthLoading,
            loadingMessage: 'TiyatRol Sahnesi Hazırlanıyor...',
            child: isWeb ? safeChild : _MobileSystemUIWrapper(child: safeChild),
          ),
        );
      },
    );
  }
}

/// Mobil cihazlarda Sistem Barlarının rengini temaya göre dinamik yöneten Wrapper
class _MobileSystemUIWrapper extends StatelessWidget {
  final Widget child;

  const _MobileSystemUIWrapper({required this.child});

  @override
  Widget build(final BuildContext context) {
    //Extentions ı çağırma! Çünkü app daha açılmadı.
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
