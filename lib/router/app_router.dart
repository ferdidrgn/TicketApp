import 'package:flutter/foundation.dart'; // kIsWeb için gerekli
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/data/providers/login/login_provider.dart';
import 'package:ticketapp/presentation/commonPages/showPage/show_detail_page.dart';
import 'package:ticketapp/presentation/mobil/pages/login/login_screen.dart';
import 'package:ticketapp/presentation/mobil/pages/onboarding/onboarding_container.dart';
import 'package:ticketapp/router/app_home_page.dart';

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
        if (currentPath == '/') {
          return '/home';
        }
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
      if (!isLoggedIn && !isLoggingIn && !isOnboarding) {
        return '/login';
      }

      // KURAL B: Giriş yapmış kullanıcı Login sayfasına gitmeye çalışırsa Home'a at
      if (isLoggedIn && isLoggingIn) {
        return '/home';
      }

      return null; // Her şey yolundaysa geçişe izin ver
    },

    routes: [
      // ❌ SPLASH ROUTE TAMAMEN SİLİNDİ.

      // ✅ HOME - Ana sayfa
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
            transitionsBuilder: _fadeTransition,
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
          transitionsBuilder: _slideTransition,
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
          transitionsBuilder: _fadeTransition,
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
            transitionsBuilder: _scaleTransition,
            transitionDuration: const Duration(milliseconds: 500),
          );
        },
      ),
    ],

    errorBuilder: (final context, final state) => _ErrorPage(
      errorPath: state.uri.path,
      errorMessage: state.error?.toString(),
    ),
  );
});

// ═══════════════════════════════════════════════════════
// TRANSITIONS
// ═══════════════════════════════════════════════════════
Widget _fadeTransition(
    final BuildContext context,
    final Animation<double> animation,
    final Animation<double> secondaryAnimation,
    final Widget child) {
  return FadeTransition(
    opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
    child: child,
  );
}

Widget _slideTransition(
    final BuildContext context,
    final Animation<double> animation,
    final Animation<double> secondaryAnimation,
    final Widget child) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
    child: child,
  );
}

Widget _scaleTransition(
    final BuildContext context,
    final Animation<double> animation,
    final Animation<double> secondaryAnimation,
    final Widget child) {
  return ScaleTransition(
    scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
    child: FadeTransition(opacity: animation, child: child),
  );
}

// ═══════════════════════════════════════════════════════
// 404 ERROR PAGE
// ═══════════════════════════════════════════════════════
class _ErrorPage extends StatelessWidget {
  final String errorPath;
  final String? errorMessage;

  const _ErrorPage({required this.errorPath, this.errorMessage});

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Color(0xFFD4AF37)),
            const SizedBox(height: 20),
            const Text('404 - Sayfa Bulunamadı',
                style: TextStyle(color: Colors.white, fontSize: 24)),
            Text(errorPath, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Ana Sayfaya Dön'),
            )
          ],
        ),
      ),
    );
  }
}
