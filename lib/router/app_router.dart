import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/presentation/commonPages/showPage/show_detail_page.dart';
import 'package:ticketapp/presentation/mobil/pages/login/login_screen.dart';
import 'package:ticketapp/presentation/mobil/pages/onboarding/onboarding_container.dart';
import 'package:ticketapp/presentation/mobil/pages/splash/splash_screen.dart';
import 'package:ticketapp/router/app_home_page.dart';
import 'package:ticketapp/router/splash_router.dart';

/// 🎯 Uygulama Session Yönetimi
/// Deep link durumlarını ve splash gösterim mantığını kontrol eder
mixin AppSession {
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static void markAsInitialized() {
    _initialized = true;
    debugPrint('✅ App session initialized');
  }

  static void reset() {
    _initialized = false;
    debugPrint('🔄 App session reset');
  }
}

/// 🎯 Ana Router Konfigürasyonu
/// Tüm route'lar ve navigation logic burada tanımlanır
mixin AppRouter {
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,

      // 🎯 REDIRECT LOGIC: Deep link ve splash mantığı
      redirect: (final BuildContext context, final GoRouterState state) {
        final location = state.uri.path;
        debugPrint('🔍 Router redirect check: $location');

        // WEB için özel mantık
        if (SplashRouter.shouldSkipAuthCheck) {
          // Henüz initialize edilmemişse
          if (!AppSession.isInitialized) {
            // Root path → Splash göster
            if (location == '/') {
              debugPrint('🎬 First visit to root, showing splash');
              return null; // Splash route'una git (zaten / root)
            }

            // Deep link → Splash atla, direkt hedef sayfaya git
            if (location != '/' && location != '/splash') {
              debugPrint('🔗 Deep link to $location, skipping splash');
              AppSession.markAsInitialized();
              return null; // İstenen sayfaya devam et
            }
          }
        }

        // Mobil veya diğer durumlar için normal akış
        return null;
      },

      routes: [
        // 🎬 SPLASH ROUTE
        GoRoute(
          path: '/',
          name: 'splash',
          pageBuilder: (final context, final state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: SplashScreen(
                initialRoute: SplashRouter.initialRoute,
                onComplete: () {
                  // Splash tamamlandığında session'ı initialize et
                  AppSession.markAsInitialized();
                  debugPrint('✅ Splash completed');
                },
              ),
              transitionsBuilder: (final context, final animation,
                  final secondaryAnimation, final child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            );
          },
        ),

        // 🏠 HOME ROUTE
        GoRoute(
          path: '/home',
          name: 'home',
          pageBuilder: (final context, final state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const AppHomePage(),
              transitionsBuilder: (final context, final animation,
                  final secondaryAnimation, final child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            );
          },
        ),

        // 🔐 LOGIN ROUTE
        GoRoute(
          path: '/login',
          name: 'login',
          pageBuilder: (final context, final state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const LoginScreen(),
              transitionsBuilder: (final context, final animation,
                  final secondaryAnimation, final child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
            );
          },
        ),

        // 👋 ONBOARDING ROUTE
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          pageBuilder: (final context, final state) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const OnboardingContainer(),
              transitionsBuilder: (final context, final animation,
                  final secondaryAnimation, final child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            );
          },
        ),

        // 🎭 SHOW DETAILS ROUTE (Deep Link için önemli!)
        GoRoute(
          path: '/show-details/:id',
          name: 'showDetail',
          pageBuilder: (final context, final state) {
            final id = state.pathParameters['id'];
            return CustomTransitionPage(
              key: state.pageKey,
              child: ShowDetailPage(showId: id ?? ''),
              transitionsBuilder: (final context, final animation,
                  final secondaryAnimation, final child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            );
          },
        ),

        // 📄 Ek route'lar buraya eklenebilir
        // Örnek: '/about', '/contact', '/team', vb.
      ],

      // ❌ 404 ERROR HANDLER
      errorBuilder: (final context, final state) {
        return Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.theater_comedy,
                  size: 80,
                  color: Color(0xFFD4AF37),
                ),
                const SizedBox(height: 24),
                const Text(
                  '404',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sayfa Bulunamadı',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.uri.path,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text(
                    'Ana Sayfaya Dön',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
