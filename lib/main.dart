import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ticketapp/presentation/pages/login/login.dart';
import 'package:ticketapp/presentation/pages/main_pages/main_pages_container.dart';
import 'package:ticketapp/presentation/pages/onboarding/onboarding_container.dart';
import 'package:ticketapp/presentation/pages/splash/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final themeMode = await getThemeMode();
  runApp(MyApp(themeMode: themeMode));
}

Future<ThemeMode> getThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final themeString = prefs.getString('themeMode') ?? 'system';
  switch (themeString) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

class MyApp extends StatefulWidget {
  final ThemeMode themeMode;

  const MyApp({super.key, required this.themeMode});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.themeMode;
  }

  Future<void> _changeTheme(final ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = themeMode;
      prefs.setString('themeMode', themeMode.toString().split('.').last);
    });
  }

  @override
  Widget build(final BuildContext context) {
    return MaterialApp(
      title: 'Bilet Satış Uygulaması',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      initialRoute: '/',
      routes: {
        '/': (final context) => const SplashScreen(),
        '/login': (final context) => LoginScreen(),
        '/onboarding': (final context) => const OnboardingContainer(),
        '/home': (final context) => HomePageContainer(onThemeChanged: _changeTheme)
      },
    );
  }
}
