import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/presentation/commonPages/showPage/show_detail_page.dart';

// Sayfa importları
import 'package:ticketapp/presentation/mobil/pages/login/login_screen.dart';
import 'package:ticketapp/presentation/mobil/pages/onboarding/onboarding_container.dart';
import 'package:ticketapp/presentation/mobil/pages/splash/splash_screen.dart';

// Core importlar
import 'core/constants/app_constants.dart';
import 'core/network/connectivity_wrapper.dart';
import 'core/services/local_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_notifier.dart';
import 'core/theme/web_theme.dart';
import 'core/util/platform_checker.dart';
import 'firebase_options.dart';

// Router importları
import 'router/app_home_page.dart';
import 'router/splash_router.dart';

Future<void> main() async {
  // ✅ 1. Native Splash'i Kontrol Altına Al
  final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy(); //Path den "#" i kaldırıyor
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    await LocalStorageService.init();
  } catch (e) {
    debugPrint('LocalStorageService initialization failed: $e');
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

    _router = GoRouter(
      initialLocation: '/',
      routes: [
        // 1. Splash Ekranı (Native Splash sonrası devreye girer)
        GoRoute(
          path: '/',
          builder: (final context, final state) => SplashScreen(
            // SplashRouter dosyanızdaki mantığı koruyoruz:
            // Web ise '/home', Mobil ise '/login' (veya onboarding) bilgisini gönderir.
            initialRoute: SplashRouter.initialRoute,
          ),
        ),

        // 2. Login Ekranı
        GoRoute(
          path: '/login',
          builder: (final context, final state) => const LoginScreen(),
        ),

        // 3. Onboarding Ekranı
        GoRoute(
          path: '/onboarding',
          builder: (final context, final state) => const OnboardingContainer(),
        ),

        // 4. Ana Sayfa (Platforma göre Web veya Mobil Home döner)
        GoRoute(
          path: '/home',
          builder: (final context, final state) => const AppHomePage(),
        ),

        // 5. ✅ Detay Sayfası (Link paylaşımı için önemli kısım)
        // Örnek kullanım: context.pushNamed('showDetail', pathParameters: {'id': '123'});
        GoRoute(
          path: '/show-details/:id', // :id dinamik parametredir
          name: 'showDetail',
          builder: (final context, final state) {
            final id = state.pathParameters['id'];
            return ShowDetailPage(showId: id ?? '');
          },
        ),
      ],
    );
  }

  @override
  Widget build(final BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    final bool isWeb = PlatformChecker.isWeb;
    final ThemeData theme = isWeb
        ? WebTheme.darkTheme
        : (themeMode == ThemeMode.dark
            ? AppTheme.darkTheme
            : AppTheme.lightTheme);

    final ThemeMode effectiveThemeMode = isWeb ? ThemeMode.dark : themeMode;

    return MaterialApp.router(
      routerConfig: _router,
      // Router ayarlarını buraya veriyoruz
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: theme,
      darkTheme: theme,
      themeMode: effectiveThemeMode,
      builder: (final context, final child) {
        return ConnectivityWrapper(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
