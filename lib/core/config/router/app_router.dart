import 'package:flutter/foundation.dart'; // kIsWeb için gerekli
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/config/router/page_transitions.dart';
import '../../../features/home/presentation/pages/wrapper/app_home_page.dart';
import '../../../features/login/presentation/pages/login_screen.dart';
import '../../../features/login/presentation/providers/login_provider.dart';
import '../../../features/onboarding/presentation/pages/onboarding_container.dart';
import '../../../features/shows/presentation/pages/show_detail_page_mobil.dart';
import '../../errors/not_found_page.dart';

final appRouterProvider = Provider<GoRouter>((final ref) {
  final loginState = ref.watch(loginProvider);

  return GoRouter(
    debugLogDiagnostics: true,
    // Uygulama açılışında direkt buraya gitmeye çalışır
    initialLocation: '/home',

    // 🛡️ YÖNLENDİRME MANTIĞI (GUARD)
    redirect: (final context, final state) {
      // Platform Kontrolü (SplashRouter yerine direkt kIsWeb)
      // kIsWeb: Flutter'ın kendi değişkenidir. Web'de true, mobilde false döner.
      final isWeb = kIsWeb;
      final currentPath = state.uri.path;

      // 1. WEB SENARYOSU
      if (isWeb) {
        // Web'de kök dizine (/) gelindiyse /home'a yönlendir.
        if (currentPath == '/') return '/home';
        // Diğer tüm linklere (örn: /show/123) izin ver.
        return null;
      }

      // 2. MOBİL SENARYOSU
      // Mobil ise Auth kontrolü şarttır.
      final isLoggedIn = loginState.user != null;
      final isLoggingIn = currentPath == '/login';
      final isOnboarding = currentPath == '/onboarding';

      // Eğer Auth durumu hala yükleniyorsa (Loading), yönlendirme yapma.
      // Çünkü main.dart'taki Global Splash zaten ekranda dönüyor.
      if (loginState.isLoading) return null;

      // KURAL A: Giriş yapmamış kullanıcıyı Login'e at (Onboarding hariç)
      if (!isLoggedIn && !isLoggingIn && !isOnboarding) return '/login';

      // KURAL B: Giriş yapmış kullanıcı Login sayfasına gitmeye çalışırsa Home'a at
      if (isLoggedIn && isLoggingIn) return '/home';

      return null; // Her şey yolundaysa geçişe izin ver
    },

    routes: [
      // ✅ HOME
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (final context, final state) {
          final startAnimations = state.extra is Map
              ? (state.extra! as Map)['startAnimations'] ?? false
              : false;

          return CustomTransitionPage(
            key: state.pageKey,
            child: AppHomePage(startAnimations: startAnimations),
            // Yeni dosyadan gelen transition fonksiyonu
            transitionsBuilder: fadeTransition,
            transitionDuration: const Duration(milliseconds: 500),
          );
        },
      ),

      // ✅ LOGIN
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: slideTransition,
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),

      // ✅ ONBOARDING
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingContainer(),
          transitionsBuilder: fadeTransition,
          transitionDuration: const Duration(milliseconds: 600),
        ),
      ),

      // ✅ SHOW DETAIL
      GoRoute(
        path: '/show/:id',
        name: 'showDetail',
        pageBuilder: (final context, final state) {
          final showId = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ShowDetailPage(showId: showId),
            transitionsBuilder: scaleTransition,
            transitionDuration: const Duration(milliseconds: 500),
          );
        },
      ),
    ],

    // 404 Hata Sayfası
    errorBuilder: (final context, final state) =>
        NotFoundPage(errorPath: state.uri.path),
  );
});
