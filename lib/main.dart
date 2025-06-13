import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/presentation/mobil/pages/login/login_screen.dart';
import 'package:ticketapp/presentation/mobil/pages/onboarding/onboarding_container.dart';
import 'package:ticketapp/presentation/mobil/pages/splash/splash_screen.dart';
import 'package:ticketapp/web_or_mobil_check.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: '/',
      routes: {
        '/': (final context) => const SplashScreen(),
        '/login': (final context) => const LoginScreen(),
        '/onboarding': (final context) => const OnboardingContainer(),
        '/home': (final context) => const WebOrMobilCheck(),
      },
    );
  }
}
