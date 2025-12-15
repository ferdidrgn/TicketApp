import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/config/router/page_transitions.dart';

// --- SAYFA IMPORTLARI ---
import '../../../features/home/presentation/pages/wrapper/app_home_page.dart';
import '../../../features/login/presentation/pages/login_screen.dart';
import '../../../features/login/presentation/providers/login_provider.dart';
import '../../../features/onboarding/presentation/pages/onboarding_container.dart';
import '../../../features/shows/presentation/pages/show_detail_page_mobil.dart';
import '../../errors/not_found_page.dart';

final appRouterProvider = Provider<GoRouter>((final ref) {
  // 1. Login State'i izle
  final loginState = ref.watch(loginProvider);

  // 2. Router'ı dürtecek bir dinleyici (Notifier) oluştur.
  // GoRouter, "refreshListenable" sayesinde bu değişken her değiştiğinde yönlendirmeyi tekrar kontrol eder.
  final authNotifier = ValueNotifier(loginState);

  // 3. Riverpod dinleyicisi: State her değiştiğinde authNotifier'ı güncelle.
  ref.listen(loginProvider, (final previous, final next) {
    authNotifier.value = next;
  });

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/home',

    // 🔥 BU SATIR KRİTİK: LoginState değişince Router'ı tetikler
    refreshListenable: authNotifier,

    // 🛡️ YÖNLENDİRME MANTIĞI (GUARD)
    redirect: (final context, final state) {
      final isWeb = kIsWeb;
      final currentPath = state.uri.path;

      // --- WEB SENARYOSU ---
      if (isWeb) {
        if (currentPath == '/') return '/home';
        return null;
      }

      // --- MOBİL SENARYOSU ---
      // Not: refreshListenable sayesinde bu blok loginState her değiştiğinde çalışır.

      final isLoggedIn = loginState.user != null;
      final isLoggingIn = currentPath == '/login';
      final isOnboarding = currentPath == '/onboarding';
      final isLoading = loginState.isLoading;

      // 1. Yükleniyorsa Bekle (null döndür, mevcut sayfada -Splash- kalsın)
      if (isLoading) return null;

      // 2. Yükleme Bitti, Giriş Yapılmamış -> Login'e git (Onboarding hariç)
      if (!isLoggedIn && !isLoggingIn && !isOnboarding) return '/login';

      // 3. Giriş Yapılmış ama Login sayfasına gitmeye çalışıyor -> Home'a at
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