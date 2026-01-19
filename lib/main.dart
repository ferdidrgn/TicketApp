import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/common/constants/app_constants.dart';
import 'core/config/app_initializer.dart';
import 'core/config/router/app_router.dart';
import 'core/localization/locale_provider.dart';
import 'core/network/connectivity_wrapper.dart';
import 'core/services/deeplink/deeplink_listener_service.dart';
import 'core/theme/theme_manager.dart';
import 'core/theme/theme_notifier.dart';
import 'core/theme/web_theme.dart';
import 'core/util/platform_checker.dart';
import 'features/login/presentation/providers/login_provider.dart';
import 'features/splash/presentation/widgets/splash_data_guard.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  await AppInitializer.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _router = ref.read(appRouterProvider);

    // 🔗 Deeplink listener (1 kere)
    DeeplinkListener.start(_router);
  }

  @override
  void dispose() {
    DeeplinkListener.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    // State izleme
    final currentStyle = ref.watch(themeProvider);
    final themeNotifier = ref.watch(themeProvider.notifier);
    final localeAsync = ref.watch(localeControllerProvider);
    final loginState = ref.watch(loginProvider);
    final isWeb = PlatformChecker.isWeb;
    final themeManager = ThemeManager(currentStyle);

    return DynamicColorBuilder(builder:
        (final ColorScheme? lightDynamic, final ColorScheme? darkDynamic) {
      // 1. Eğer telefon destekliyorsa duvar kağıdı rengini al.
      // 2. Desteklemiyorsa (iOS veya eski Android) varsayılan 'seedColor' kullan.
      // Not: AppTheme.lightScheme ve darkScheme senin kendi belirlediğin fallback renkler olmalı.

      final lightTheme = themeManager.getLightTheme(lightDynamic);
      final darkTheme = themeManager.getDarkTheme(darkDynamic);

      return MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        // Web için özel tema, mobil için hesaplanan tema
        theme: lightTheme,
        darkTheme: isWeb ? WebTheme.darkTheme : darkTheme,
        themeMode: isWeb ? ThemeMode.dark : themeNotifier.themeMode,
        locale: localeAsync.value ?? const Locale('tr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router,
        builder: (final context, final child) {
          if (child == null) return const SizedBox.shrink();
          return ConnectivityWrapper(
            child: SplashDataGuard(
              isLoading: loginState.isLoading,
              loadingMessage: loginState.hasError
                  ? loginState.errorMessage!
                  : 'TiyatRol Sahnesi Hazırlanıyor...',
              // Web değilse sarmalayıcıyı kullan
              child: isWeb ? child : _MobileSystemUIWrapper(child: child),
            ),
          );
        },
      );
    });
  }
}

/// Mobil cihazlarda status bar ve navigation bar stilini ayarlamak için
/// kullanılan wrapper widget
class _MobileSystemUIWrapper extends StatelessWidget {
  final Widget child;

  const _MobileSystemUIWrapper({required this.child});

  @override
  Widget build(final BuildContext context) {
    //Extentions ı çağırma! Çünkü app daha açılmadı.
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        // Status Bar İkon Renkleri
        statusBarColor: Colors.transparent,
        // M3 standardı şeffaf status bar
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        // Tam şeffaf navigasyon
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: child,
    );
  }
}
