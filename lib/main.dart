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
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        // iOS için
        // Alt Navigasyon Bar İkon Renkleri
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        // EdgeToEdge sayesinde
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: child,
    );
  }
}
