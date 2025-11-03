import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/presentation/mobil/pages/login/login_screen.dart';
import 'package:ticketapp/presentation/mobil/pages/onboarding/onboarding_container.dart';
import 'package:ticketapp/presentation/mobil/pages/splash/splash_screen.dart';
import 'package:ticketapp/web_or_mobil_check.dart';
import 'core/constants/app_constants.dart';
import 'core/services/local_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'firebase_options.dart';

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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      onGenerateRoute: (final settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
                builder: (final _) => const SplashScreen());
          case '/login':
            return MaterialPageRoute(builder: (final _) => const LoginScreen());
          case '/onboarding':
            return MaterialPageRoute(
                builder: (final _) => const OnboardingContainer());
          case '/home':
            return MaterialPageRoute(
                builder: (final _) => const WebOrMobilCheck());
          default:
            return MaterialPageRoute(builder: (final _) => const LoginScreen());
        }
      },
    );
  }
}
