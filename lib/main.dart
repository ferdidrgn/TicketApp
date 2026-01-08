import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/app_initializer.dart';
import 'core/config/router/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/network/connectivity_wrapper.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'core/theme/web_theme.dart';
import 'core/util/platform_checker.dart';
import 'features/login/presentation/providers/login_provider.dart';
import 'features/splash/presentation/widgets/splash_data_guard.dart';

Future<void> main() async {
  await AppInitializer.init();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // 1. Notifier'ın kendisini okuyoruz (Helper getter'lara erişmek için)
    final themeNotifier = ref.watch(themeProvider.notifier);
    // 2. State'i izliyoruz (Değişiklikte rebuild olması için)
    final currentPreference = ref.watch(themeProvider);
    final router = ref.watch(appRouterProvider);
    final loginState = ref.watch(loginProvider);
    final isWeb = PlatformChecker.isWeb;

    return DynamicColorBuilder(builder:
        (final ColorScheme? lightDynamic, final ColorScheme? darkDynamic) {
      // 1. Eğer telefon destekliyorsa duvar kağıdı rengini al.
      // 2. Desteklemiyorsa (iOS veya eski Android) varsayılan 'seedColor' kullan.
      // Not: AppTheme.lightScheme ve darkScheme senin kendi belirlediğin fallback renkler olmalı.

      ColorScheme lightScheme;
      ColorScheme darkScheme;

      // Eğer kullanıcı "Senin Teman" (Monet) seçtiyse VE cihaz destekliyorsa:
      if (themeNotifier.isDynamicColorEnabled &&
          lightDynamic != null &&
          darkDynamic != null) {
        lightScheme = lightDynamic.harmonized();
        darkScheme = darkDynamic.harmonized();
      } else {
        // Diğer seçeneklerde (Gündüz/Gece/Sistem) senin varsayılan renklerin kullanılır
        lightScheme =
            ColorScheme.fromSeed(seedColor: Colors.deepPurple); // Senin rengin
        darkScheme = ColorScheme.fromSeed(
            seedColor: Colors.deepPurple, brightness: Brightness.dark);
      }

      return MaterialApp.router(
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        theme: AppTheme.createTheme(lightScheme),
        darkTheme:
            isWeb ? WebTheme.darkTheme : AppTheme.createTheme(darkScheme),
        themeMode: isWeb ? ThemeMode.dark : themeNotifier.currentThemeMode,
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
