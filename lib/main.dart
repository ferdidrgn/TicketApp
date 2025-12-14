import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
    // 1. Kullanıcının seçtiği mod (Light / Dark / System)
    final themeMode = ref.watch(themeProvider);
    final bool isWeb = PlatformChecker.isWeb;

    // 2. Router
    final router = ref.watch(appRouterProvider);

    // 3. Auth Loading Durumu (Sadece Mobil için kritik)
    final loginState = ref.watch(loginProvider);
    final bool isAuthLoading = !isWeb && loginState.isLoading;

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: isWeb ? WebTheme.darkTheme : AppTheme.darkTheme,
      // Web ise zorla Dark yap, Mobil ise kullanıcının seçimine (veya sisteme) bırak.
      themeMode: isWeb ? ThemeMode.dark : themeMode,
      // -----------------------------------------------------------------------

      // 🎯 GLOBAL BUILDER & SPLASH GUARD
      builder: (final context, final child) {
        // Router'dan gelen asıl sayfa
        final safeChild = child ?? const SizedBox.shrink();

        return ConnectivityWrapper(
          // Auth kontrolü yapılırken kullanıcıya boş ekran gösterme,
          // şık DataSplashGuard'ı göster.
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
