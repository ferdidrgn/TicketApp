import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/presentation/mobil/pages/login/login_screen.dart';
import 'package:ticketapp/presentation/mobil/pages/onboarding/onboarding_container.dart';
import 'package:ticketapp/presentation/mobil/pages/splash/splash_screen.dart';
import 'core/constants/app_constants.dart';
import 'core/services/local_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'core/theme/web_theme.dart';
import 'core/util/platform_checker.dart';
import 'firebase_options.dart';

// ✅ Router dosyalarınızı ana noktadan import edin:
import 'router/app_home_page.dart'; // /home için (AppHomePage widget'ı seçimi)
import 'router/splash_router.dart'; // Splash için (Rota ve kontrol seçimi)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    await LocalStorageService.init();
  } catch (e) {
    debugPrint('LocalStorageService initialization failed: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    final bool isWeb = PlatformChecker.isWeb;
    final ThemeData theme = isWeb
        ? WebTheme.darkTheme
        : (themeMode == ThemeMode.dark
            ? AppTheme.darkTheme
            : AppTheme.lightTheme);

    final ThemeMode effectiveThemeMode = isWeb ? ThemeMode.dark : themeMode;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: theme,
      darkTheme: theme,
      themeMode: effectiveThemeMode,
      onGenerateRoute: (final settings) {
        switch (settings.name) {
          case '/':
            // ✅ SplashRouter.initialRoute'u SplashScreen'e iletiyoruz.
            // Web için '/home', Mobil için '/onboarding' (veya /login) olacak.
            return MaterialPageRoute(
                builder: (final _) =>
                    SplashScreen(initialRoute: SplashRouter.initialRoute));
          case '/login':
            return MaterialPageRoute(builder: (final _) => const LoginScreen());
          case '/onboarding':
            return MaterialPageRoute(
                builder: (final _) => const OnboardingContainer());
          case '/home':
            // ✅ AppHomePage koşullu içe aktarma ile doğru widget'ı getirir.
            return MaterialPageRoute(builder: (final _) => const AppHomePage());
          default:
            return MaterialPageRoute(builder: (final _) => const LoginScreen());
        }
      },
    );
  }
}
