import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'core/config/app_initializer.dart';
import 'core/config/router/app_router.dart';
import 'core/constants/app_constants.dart';
import 'core/enum/enums.dart';
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
    // State izleme
    final currentStyle = ref.watch(themeProvider);
    final themeNotifier = ref.watch(themeProvider.notifier);
    final router = ref.watch(appRouterProvider);
    final loginState = ref.watch(loginProvider);
    final isWeb = PlatformChecker.isWeb;

    // Sabit App Renkleri (WebColors veya AppLightColors'dan çekilir)
    const fixedSeedColor = AppLightColors.primary; // Kırmızı/Altın rengin

    return DynamicColorBuilder(builder:
        (final ColorScheme? lightDynamic, final ColorScheme? darkDynamic) {
      // 1. Eğer telefon destekliyorsa duvar kağıdı rengini al.
      // 2. Desteklemiyorsa (iOS veya eski Android) varsayılan 'seedColor' kullan.
      // Not: AppTheme.lightScheme ve darkScheme senin kendi belirlediğin fallback renkler olmalı.

      ThemeData lightThemeData;
      ThemeData darkThemeData;

      // --- TEMA MANTIĞI ---
      switch (currentStyle) {
        // 1. SABİT GÜNDÜZ (Zorla Kendi Rengin)
        case AppThemeStyle.appLight:
          lightThemeData = AppTheme.createTheme(
            colors: ColorScheme.fromSeed(
                seedColor: fixedSeedColor, brightness: Brightness.light),
          );
          darkThemeData = AppTheme.createTheme(
            // Kullanılmayacak ama null olmasın
            colors: ColorScheme.fromSeed(
                seedColor: fixedSeedColor, brightness: Brightness.dark),
          );
          break;

        // 2. SABİT GECE (Zorla Kendi Rengin)
        case AppThemeStyle.appDark:
          lightThemeData = AppTheme.createTheme(
            colors: ColorScheme.fromSeed(
                seedColor: fixedSeedColor, brightness: Brightness.light),
          );
          darkThemeData = AppTheme.createTheme(
            colors: ColorScheme.fromSeed(
                seedColor: fixedSeedColor, brightness: Brightness.dark),
          );
          break;

        // 3. SİSTEM (Telefona Göre Senin Renklerin)
        case AppThemeStyle.system:
          lightThemeData = AppTheme.createTheme(
            colors: ColorScheme.fromSeed(
                seedColor: fixedSeedColor, brightness: Brightness.light),
          );
          darkThemeData = AppTheme.createTheme(
            colors: ColorScheme.fromSeed(
                seedColor: fixedSeedColor, brightness: Brightness.dark),
          );
          break;

        // 4. MATERIAL GÜNDÜZ (Duvar Kağıdı Rengi)
        case AppThemeStyle.materialLight:
          final seed = lightDynamic?.primary ?? fixedSeedColor;
          lightThemeData = AppTheme.createTheme(
            colors: lightDynamic ??
                ColorScheme.fromSeed(
                    seedColor: seed, brightness: Brightness.light),
          );
          darkThemeData = AppTheme.createTheme(
            colors: darkDynamic ??
                ColorScheme.fromSeed(
                    seedColor: seed, brightness: Brightness.dark),
          );
          break;

        // 5. MATERIAL ATMOSFERİK GECE (Duvar Kağıdı + Özel Koyu Mod)
        case AppThemeStyle.materialDark:
          final seed = darkDynamic?.primary ?? fixedSeedColor;

          // Light tema standart kalır
          lightThemeData = AppTheme.createTheme(
            colors: lightDynamic ??
                ColorScheme.fromSeed(
                    seedColor: seed, brightness: Brightness.light),
          );

          // Dark Tema için SİHİRLİ DOKUNUŞ:
          final atmosphericColor = AppTheme.createAtmosphericBackground(seed);

          darkThemeData = AppTheme.createTheme(
            // Şemanın surface rengini override ediyoruz
            scaffoldBackgroundOverride: atmosphericColor,

            colors: (darkDynamic ??
                    ColorScheme.fromSeed(
                        seedColor: seed, brightness: Brightness.dark))
                .copyWith(
              surface: atmosphericColor, // Yüzey rengini değiştir
              onSurface: Colors.white, // Yazılar beyaz
            ),
          );
          break;
      }

      return MaterialApp.router(
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        // Web için özel tema, mobil için hesaplanan tema
        theme: lightThemeData,
        darkTheme: isWeb ? WebTheme.darkTheme : darkThemeData,
        themeMode: isWeb ? ThemeMode.dark : themeNotifier.themeMode,
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
