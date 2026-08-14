import 'dart:async';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/features/auth/presentation/providers/auth_mutation_provider.dart';
import 'core/common/constants/app_constants.dart';
import 'core/config/app_initializer.dart';
import 'core/config/router/app_router.dart';
import 'core/localization/locale_provider.dart';
import 'core/network/connectivity_wrapper.dart';
import 'core/services/deeplink/deeplink_listener_service.dart';
import 'core/services/fcm_manager_service.dart';
import 'core/theme/theme_manager.dart';
import 'core/theme/theme_notifier.dart';
import 'core/theme/web_theme.dart';
import 'core/util/platform_checker.dart';
import 'features/splash/presentation/widgets/splash_data_guard.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  // Binding nesnesini al
  final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();

  // 1. Arayüzü uçtan uca şeffaf moda al
  AppInitializer.configureSystemUIPreBoot();

  // 2. Tüm servisleri başlat
  await AppInitializer.init(binding);

  // 3. Uygulama tamamen kapalıyken/arka plandayken gelen push bildirimlerini
  // yakalayacak handler'ı kaydet (Firebase.initializeApp() sonrası olmalı).
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

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
    TiyatrolDeeplinkListener.init(_router);
    FCMManager.instance.init(_router);
  }

  @override
  void dispose() {
    TiyatrolDeeplinkListener.stop();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final currentStyle = ref.watch(themeProvider);
    final themeNotifier = ref.watch(themeProvider.notifier);
    final localeAsync = ref.watch(localeControllerProvider);
    final authMutation = ref.watch(authMutationProvider);
    final isWeb = PlatformChecker.isWeb;
    final themeManager = ThemeManager(currentStyle);

    return DynamicColorBuilder(builder:
        (final ColorScheme? lightDynamic, final ColorScheme? darkDynamic) {
      final lightTheme = themeManager.getLightTheme(lightDynamic);
      final darkTheme = themeManager.getDarkTheme(darkDynamic);

      return MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
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
              isLoading: authMutation.isLoading,
              loadingMessage: authMutation.hasError
                  ? 'Bir hata oluştu, lütfen tekrar deneyin.'
                  : 'TiyatRol Sahnesi Hazırlanıyor...',
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
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: child,
    );
  }
}
