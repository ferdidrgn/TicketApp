import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:ticketapp/presentation/mobil/pages/splash/dataguard.dart';

// Core imports
import 'core/constants/app_constants.dart';
import 'core/network/connectivity_wrapper.dart';
import 'core/services/local_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'core/theme/web_theme.dart';
import 'core/util/platform_checker.dart';
import 'firebase_options.dart';

// Provider ve Router import
import 'data/providers/login/login_provider.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await LocalStorageService.init();
    debugPrint('✅ LocalStorageService initialized');
  } catch (e) {
    debugPrint('❌ LocalStorageService initialization failed: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final bool isWeb = PlatformChecker.isWeb;

    // 1. Router'ı Provider'dan alıyoruz (Artık Auth dinleyen akıllı bir router)
    final router = ref.watch(appRouterProvider);

    // 2. Global Yüklenme Durumunu İzle (Login kontrolü yapılıyor mu?)
    final loginState = ref.watch(loginProvider);
    // Sadece Mobil'de Login Loading'i önemlidir. Web'de zaten atlıyoruz.
    final bool isAuthLoading = !isWeb && loginState.isLoading;

    final ThemeData theme = isWeb
        ? WebTheme.darkTheme
        : (themeMode == ThemeMode.dark
            ? AppTheme.darkTheme
            : AppTheme.lightTheme);

    final ThemeMode effectiveThemeMode = isWeb ? ThemeMode.dark : themeMode;

    return MaterialApp.router(
      routerConfig: router,
      // ✅ Provider'dan gelen router
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: theme,
      darkTheme: theme,
      themeMode: effectiveThemeMode,

      // 🎯 GLOBAL BUILDER: İşte "Splash Screen" widget'ının yeni evi burası
      builder: (final context, final child) {
        // Router'dan gelen asıl sayfa
        final safeChild = child ?? const SizedBox.shrink();

        return ConnectivityWrapper(
          // Auth kontrolü yapılırken kullanıcıya boş ekran gösterme,
          // şık DataSplashGuard'ı göster.
          child: DataSplashGuard(
            isLoading: isAuthLoading,
            loadingMessage: 'TiyatRol Başlatılıyor...',
            child: safeChild,
          ),
        );
      },
    );
  }
}
