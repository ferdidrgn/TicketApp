import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

// Core imports
import 'core/constants/app_constants.dart';
import 'core/network/connectivity_wrapper.dart';
import 'core/services/local_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'core/theme/web_theme.dart';
import 'core/util/platform_checker.dart';
import 'firebase_options.dart';

// Router import
import 'router/app_router.dart';

Future<void> main() async {
  // Flutter binding'i başlat
  WidgetsFlutterBinding.ensureInitialized();

  // URL stratejisini ayarla (# işaretini kaldır)
  usePathUrlStrategy();

  // Firebase'i başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Local storage'ı başlat
  try {
    await LocalStorageService.init();
    debugPrint('✅ LocalStorageService initialized');
  } catch (e) {
    debugPrint('❌ LocalStorageService initialization failed: $e');
  }

  // Uygulamayı başlat
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final bool isWeb = PlatformChecker.isWeb;

    // Platform'a göre tema seç
    final ThemeData theme = isWeb
        ? WebTheme.darkTheme
        : (themeMode == ThemeMode.dark
            ? AppTheme.darkTheme
            : AppTheme.lightTheme);

    final ThemeMode effectiveThemeMode = isWeb ? ThemeMode.dark : themeMode;

    return MaterialApp.router(
      // 🎯 Router konfigürasyonunu dışarıdan al
      routerConfig: AppRouter.createRouter(),

      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,

      // Tema ayarları
      theme: theme,
      darkTheme: theme,
      themeMode: effectiveThemeMode,

      // Connectivity wrapper
      builder: (final context, final child) {
        return ConnectivityWrapper(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
