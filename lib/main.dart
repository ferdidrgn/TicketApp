import 'package:flutter/material.dart';
import 'package:ticketapp/login/login.dart';
import 'package:ticketapp/main_pages/main_pages_container.dart';
import 'package:ticketapp/splash/splash_screen.dart';
import 'onboarding/onboarding_container.dart';
import 'util/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  void _changeTheme(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = themeMode;
      prefs.setString('themeMode', themeMode.toString().split('.').last);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bilet Satış Uygulaması',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/onboarding': (context) => OnboardingContainer(),
        '/home': (context) => HomePageContainer(
              onThemeChanged: _changeTheme,
            ),
      },
    );
  }
}
