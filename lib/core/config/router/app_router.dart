import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/config/router/page_transitions.dart';
import 'package:ticketapp/features/appTools/presentation/pages/help_support_page.dart';
import 'package:ticketapp/features/favorite/presentation/pages/favorite_screen.dart';
import 'package:ticketapp/features/tickets/presentation/pages/my_ticket_page.dart';
import '../../../features/appTools/presentation/pages/contracts.dart';
import '../../../features/home/presentation/pages/wrapper/app_home_page.dart';
import '../../../features/login/presentation/pages/login_screen.dart';
import '../../../features/login/presentation/pages/phone_login_page.dart';
import '../../../features/login/presentation/providers/login_provider.dart';
import '../../../features/onboarding/presentation/pages/onboarding_container.dart';
import '../../../features/search/presentation/pages/search_page.dart';
import '../../../features/settings/presentation/pages/app_settings.dart';
import '../../../features/shows/presentation/pages/show_detail_page.dart';
import '../../../features/users/presentation/pages/user_profile_edit.dart';
import '../../../shared/providers/navigation_keys.dart';
import '../../errors/not_found_page.dart';

/// 🛣️ TiyatRol Büyülü Router Yapılandırması
final appRouterProvider = Provider<GoRouter>((final ref) {
  final loginState = ref.watch(loginProvider);
  final authNotifier = ValueNotifier(loginState);

  ref.listen(loginProvider, (final _, final next) {
    authNotifier.value = next;
  });

  return GoRouter(
      initialLocation: '/home',
      refreshListenable: authNotifier,
      navigatorKey: NavigationKeys.rootNavigator,
      redirect: (final context, final state) {
        final currentPath = state.uri.path;
        final isLoggedIn = loginState.isLoggedIn;

        // Korumalı sayfalar (Sadece giriş yapanlar girebilir)
        final isProtectedPage = currentPath.startsWith('/profile-edit') ||
            currentPath.startsWith('/my-tickets') ||
            currentPath == '/favorites';

        if (!isLoggedIn && isProtectedPage) return '/login';

        // Login olan kişi login sayfasına tekrar gidemez
        if (isLoggedIn &&
            (currentPath == '/login' || currentPath == '/phone-login'))
          return '/home';

        return null;
      },
      routes: [
        // HOME
        GoRoute(
          path: '/home',
          name: 'home',
          pageBuilder: (final context, final state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AppHomePage(),
            transitionsBuilder: curtainTransition, // Perde efekti
            transitionDuration: const Duration(milliseconds: 800),
          ),
        ),

        // 👁️ GÖSTERİ DETAY: Bir esere odaklanma hissi (Focal Blur)
        GoRoute(
          path: '/show/:id',
          name: 'showDetail',
          pageBuilder: (final context, final state) {
            final showId = state.pathParameters['id']!;
            return CustomTransitionPage(
              key: state.pageKey,
              child: ShowDetailPage(showId: showId),
              transitionsBuilder: focalTransition, // Odaklanma efekti
              transitionDuration: const Duration(milliseconds: 900),
            );
          },
        ),

        // ✨ GİRİŞ EKRANI: Gizemli bir parlayış (Shimmer)
        GoRoute(
          path: '/login',
          name: 'login',
          pageBuilder: (final context, final state) => CustomTransitionPage(
            key: state.pageKey,
            child: const LoginScreen(),
            transitionsBuilder: shimmerSlideTransition,
            transitionDuration: const Duration(milliseconds: 700),
          ),
        ),

        // 🚪 TELEFON GİRİŞ: Kapıdan geçiş hissi (Shadow Gate)
        GoRoute(
          path: '/phone-login',
          name: 'phoneLogin',
          pageBuilder: (final context, final state) => CustomTransitionPage(
            key: state.pageKey,
            child: const PhoneLogInPage(),
            transitionsBuilder: shadowGateTransition, // Kapı efekti
            transitionDuration: const Duration(milliseconds: 750),
          ),
        ),

        // PROFILE EDIT
        GoRoute(
          path: '/profile-edit/:userId',
          name: 'profileEdit',
          pageBuilder: (final context, final state) {
            final userId = state.pathParameters['userId']!;
            return CustomTransitionPage(
              key: state.pageKey,
              child: UserProfileEditScreen(userId: userId),
              transitionsBuilder: fadeTransition,
              transitionDuration: const Duration(milliseconds: 500),
            );
          },
        ),

        // 📜 BİLETLERİM: Parşömen kayması
        GoRoute(
          path: '/my-tickets/:userId',
          name: 'myTickets',
          pageBuilder: (final context, final state) {
            final userId = state.pathParameters['userId']!;
            return CustomTransitionPage(
              key: state.pageKey,
              child: MyTicketPage(userId: userId),
              transitionsBuilder: scrollSlideTransition, // Parşömen efekti
              transitionDuration: const Duration(milliseconds: 700),
            );
          },
        ),

        // ❤️ FAVORİLER: Sinematik kararma
        GoRoute(
          path: '/favorites',
          name: 'favorites',
          pageBuilder: (final context, final state) => CustomTransitionPage(
            key: state.pageKey,
            child: const FavoritesPage(),
            transitionsBuilder: cinematicFadeTransition,
            // Perde arası kararma
            transitionDuration: const Duration(milliseconds: 800),
          ),
        ),

        // Diğer sayfalar için varsayılan yumuşak geçiş
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

        // 🔍 SEARCH
        GoRoute(
          path: '/search',
          name: '/search',
          pageBuilder: (final context, final state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SearchPage(),
            // Senin ayarlar sayfanın class adı
            transitionsBuilder: focalTransition,
            // Odaklanma efekti (gizemli)
            transitionDuration: const Duration(milliseconds: 700),
          ),
        ),

        // SETTINGS
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (final context, final state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AppSettingsPage(),
            // Senin ayarlar sayfanın class adı
            transitionsBuilder: focalTransition,
            // Odaklanma efekti (gizemli)
            transitionDuration: const Duration(milliseconds: 700),
          ),
        ),

        // 📜 YASAL SÖZLEŞMELER
        GoRoute(
          path: '/contracts',
          name: 'contracts',
          pageBuilder: (final context, final state) => CustomTransitionPage(
            key: state.pageKey,
            child: ContractsPage(),
            transitionsBuilder: shadowGateTransition,
            // Kapıdan geçiş efekti
            transitionDuration: const Duration(milliseconds: 750),
          ),
        ),

        // 📜 Help
        GoRoute(
          path: '/help-support',
          name: 'helpSupport',
          pageBuilder: (final context, final state) => CustomTransitionPage(
            key: state.pageKey,
            child: HelpSupportPage(),
            transitionsBuilder: shadowGateTransition,
            // Kapıdan geçiş efekti
            transitionDuration: const Duration(milliseconds: 750),
          ),
        ),
      ],

      // 404 Error Page
      errorBuilder: (final context, final state) =>
          NotFoundPage(errorPath: state.uri.path));
});
