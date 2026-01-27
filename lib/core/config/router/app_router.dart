import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/config/seo/seo_route_observer.dart';
import 'package:ticketapp/features/players/presentation/pages/player_details.dart';
import 'package:ticketapp/features/stages/presentation/pages/stage_details.dart';
import 'package:ticketapp/features/teams/presentation/pages/team_details_mobile.dart';
import '../../../features/appTools/presentation/pages/contracts.dart';
import '../../../features/appTools/presentation/pages/help_support_page.dart';
import '../../../features/auth/presentation/page/login_screen.dart';
import '../../../features/auth/presentation/page/phone_login_page.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/discovery/presentation/pages/discovery_page.dart';
import '../../../features/discovery/presentation/pages/nearby_events_page.dart';
import '../../../features/favorite/presentation/pages/favorite_screen.dart';
import '../../../features/home/presentation/pages/wrapper/app_home_page.dart';
import '../../../features/onboarding/presentation/pages/onboarding_container.dart';
import '../../../features/search/presentation/pages/search_page.dart';
import '../../../features/settings/presentation/pages/app_settings.dart';
import '../../../features/shows/presentation/pages/show_detail_page.dart';
import '../../../features/tickets/presentation/pages/my_ticket_page.dart';
import '../../../features/users/presentation/pages/profile_page.dart';
import '../../../features/users/presentation/pages/user_profile_edit.dart';
import '../../../shared/navigation/providers/navigation_keys.dart';
import '../../../shared/navigation/widgets/mobile_bottom_nav_bar.dart';
import '../../../shared/navigation/widgets/web_navigation_shell.dart';
import '../../errors/not_found_page.dart';
import 'page_transitions.dart';

final appRouterProvider = Provider<GoRouter>((final ref) {
  final isLoggedIn = ref.watch(isLoggedInProvider);
  final authNotifier = ValueNotifier(isLoggedIn);

  ref.listen(isLoggedInProvider, (final _, final next) {
    authNotifier.value = next;
  });

  final isWeb = kIsWeb;

  return GoRouter(
    navigatorKey: NavigationKeys.rootNavigator,
    initialLocation: '/home',
    refreshListenable: authNotifier,
    observers: [
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      SeoRouteObserver(),
    ],
    redirect: (final context, final state) {
      final loggedIn = isLoggedIn;
      final path = state.uri.path;

      // Korumalı sayfalar
      final protectedRoutes = ['/favorites', '/my-tickets'];

      // Login değilse korumalı sayfaya giremez
      if (!loggedIn && protectedRoutes.any((final r) => path.startsWith(r)))
        return '/login';

      // Login olmuşsa login sayfasına gidemez
      if (loggedIn && (path == '/login' || path == '/phone-login'))
        return '/home';

      return null;
    },
    routes: [
      /// 🎯 STATEFUL SHELL ROUTE
      /// Hem mobil hem web için aynı tab yapısı!
      /// TAB 1: ANA SAYFA
      if (isWeb)
        GoRoute(
          path: '/home',
          pageBuilder: (final context, final state) => CustomTransitionPage(
            key: state.pageKey,
            child: AppHomePage(),
            transitionsBuilder: curtainTransition,
            transitionDuration: const Duration(milliseconds: 500),
          ),
        ),

      StatefulShellRoute.indexedStack(
        builder: (final context, final state, final navigationShell) {
          return MobileBottomNavBar(navigationShell: navigationShell);
        },
        branches: [
          /// TAB 2: KEŞFET
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                pageBuilder: (final context, final state) =>
                    CustomTransitionPage(
                  key: state.pageKey,
                  child: DiscoveryPage(
                    selectedCategory: state.uri.queryParameters['category'],
                  ),
                  transitionsBuilder: fadeTransition,
                  transitionDuration: const Duration(milliseconds: 500),
                ),
              ),
            ],
          ),

          /// TAB 3: YAKINDAKİLER
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/nearby',
                pageBuilder: (final context, final state) =>
                    CustomTransitionPage(
                  key: state.pageKey,
                  child: NearbyEventsPage(),
                  transitionsBuilder: scrollSlideTransition,
                  transitionDuration: const Duration(milliseconds: 500),
                ),
              ),
            ],
          ),

          /// TAB 4: PROFİL
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (final context, final state) =>
                    CustomTransitionPage(
                  key: state.pageKey,
                  child: ProfilePage(),
                  transitionsBuilder: fadeTransition,
                  transitionDuration: const Duration(milliseconds: 500),
                ),
              ),
            ],
          ),
        ],
      ),

      /// 🔗 DETAY SAYFALARI (Hem mobil hem web için ortak)
      GoRoute(
        path: '/show/:slugWithId',
        name: 'showDetail',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: ShowDetailPage(
            showId: state.pathParameters['slugWithId']!.split('-').last,
          ),
          transitionsBuilder: fadeTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/player/:slugWithId',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: PlayerDetailPage(
            playerId: state.pathParameters['slugWithId']!.split('-').last,
          ),
          transitionsBuilder: curtainTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/stage/:slugWithId',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: StageDetailPage(
            stageId: state.pathParameters['slugWithId']!.split('-').last,
          ),
          transitionsBuilder: fadeTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/team/:slugWithId',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: TeamDetailsPage(
            teamId: state.pathParameters['slugWithId']!.split('-').last,
          ),
          transitionsBuilder: fadeTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/search',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: SearchPage(),
          transitionsBuilder: fadeTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/settings',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: AppSettingsPage(),
          transitionsBuilder: fadeTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/favorites',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: FavoritesPage(),
          transitionsBuilder: cinematicFadeTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/my-tickets/:slugWithId',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: MyTicketPage(
            userId: state.pathParameters['slugWithId']!.split('-').last,
          ),
          transitionsBuilder: scrollSlideTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/profile-edit/:slugWithId',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: UserProfileEditScreen(
            userId: state.pathParameters['slugWithId']!.split('-').last,
          ),
          transitionsBuilder: fadeTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/contracts',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: ContractsPage(),
          transitionsBuilder: shadowGateTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/help-support',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: HelpSupportPage(),
          transitionsBuilder: shadowGateTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      /// 🚪 AUTH & ONBOARDING
      GoRoute(
        path: '/login',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: shimmerSlideTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/phone-login',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PhoneLogInPage(),
          transitionsBuilder: shadowGateTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/onboarding',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingContainer(),
          transitionsBuilder: curtainTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),
    ],
    errorBuilder: (final context, final state) =>
        NotFoundPage(errorPath: state.uri.path),
  );
});
