import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/presentation/commonPages/showPage/show_detail_page.dart';
import 'package:ticketapp/presentation/mobil/pages/login/login_screen.dart';
import 'package:ticketapp/presentation/mobil/pages/onboarding/onboarding_container.dart';
import 'package:ticketapp/presentation/mobil/pages/splash/splash_screen.dart';
import 'package:ticketapp/router/app_home_page.dart';
import 'package:ticketapp/router/splash_router.dart';

mixin AppRouter {
  static GoRouter createRouter() {
    return GoRouter(
      debugLogDiagnostics: false,
      initialLocation: '/',

      routes: [
        // ✅ SPLASH - İlk açılış
        GoRoute(
          path: '/',
          pageBuilder: (final context, final state) => NoTransitionPage(
            key: state.pageKey,
            child: SplashScreen(
              initialRoute: '/home',
              onComplete: () {
                debugPrint('✅ Splash completed');
              },
            ),
          ),
        ),

        // ✅ HOME - Ana sayfa (Web/Mobile otomatik)
        GoRoute(
          path: '/home',
          name: 'home',
          pageBuilder: (final context, final state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AppHomePage(),
            transitionsBuilder:
                (final context, final animation, final secondaryAnimation, final child) {
              // Fade-in geçiş
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
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

      // ✅ 404 ERROR PAGE
      errorBuilder: (final context, final state) => _ErrorPage(
        errorPath: state.uri.path,
        errorMessage: state.error?.toString(),
      ),

      // ✅ REDIRECT LOGIC
      redirect: (final context, final state) {
        final isOnSplash = state.matchedLocation == '/';

        // Splash'teyse dokunma
        if (isOnSplash) return null;

        // Web için auth check yok
        if (SplashRouter.shouldSkipAuthCheck) return null;

        // Mobil için auth kontrolü (gerekirse aktif edilir)
        // final isLoggedIn = ref.read(loginProvider).user != null;
        // final isOnLoginPage = state.matchedLocation == '/login';
        // if (!isLoggedIn && !isOnLoginPage) return '/login';
        // if (isLoggedIn && isOnLoginPage) return '/home';

        return null;
      },
    );
  }

  // ═══════════════════════════════════════════════════════
  // TRANSITIONS
  // ═══════════════════════════════════════════════════════

  static Widget _fadeTransition(
    final BuildContext context,
    final Animation<double> animation,
    final Animation<double> secondaryAnimation,
    final Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      child: child,
    );
  }

  static Widget _slideTransition(
    final BuildContext context,
    final Animation<double> animation,
    final Animation<double> secondaryAnimation,
    final Widget child,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    );
  }

  static Widget _scaleTransition(
    final BuildContext context,
    final Animation<double> animation,
    final Animation<double> secondaryAnimation,
    final Widget child,
  ) {
    return ScaleTransition(
      scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}

// ═══════════════════════════════════════════════════════
// 404 ERROR PAGE
// ═══════════════════════════════════════════════════════
class _ErrorPage extends StatelessWidget {
  final String errorPath;
  final String? errorMessage;

  const _ErrorPage({
    required this.errorPath,
    this.errorMessage,
  });

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (final context, final value, final child) {
                  return Transform.scale(
                    scale: value,
                    child: const Icon(
                      Icons.theater_comedy,
                      size: 100,
                      color: Color(0xFFD4AF37),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              const Text(
                '404',
                style: TextStyle(
                  fontSize: 80,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFD4AF37),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Sayfa Bulunamadı',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFD4AF37).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  errorPath,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'monospace',
                    color: Colors.white.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  errorMessage!,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home, size: 20),
                label: const Text(
                  'Ana Sayfaya Dön',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  shadowColor: const Color(0xFFD4AF37).withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Geri Dön'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
