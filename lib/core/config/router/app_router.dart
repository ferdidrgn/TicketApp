import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/config/seo/seo_route_observer.dart';
import 'package:ticketapp/features/home/presentation/pages/wrapper/app_home_page.dart';
import 'package:ticketapp/features/players/presentation/pages/player_details.dart';
import 'package:ticketapp/features/shows/presentation/pages/show_detail_page.dart';
import 'package:ticketapp/features/stages/presentation/pages/stage_details.dart';
import 'package:ticketapp/features/teams/presentation/pages/team_details_mobile.dart';
import '../../../features/appTools/presentation/pages/contracts.dart';
import '../../../features/appTools/presentation/pages/help_support_page.dart';
import '../../../features/auth/presentation/page/login_screen.dart';
import '../../../features/auth/presentation/page/phone_login_page.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../features/campaigns/presentation/pages/campaign_showcase_page.dart';
import '../../../features/discovery/presentation/pages/discovery_page.dart';
import '../../../features/discovery/presentation/pages/nearby_events_page.dart';
import '../../../features/favorite/presentation/pages/favorite_screen.dart';
import '../../../features/home/presentation/pages/home_page_mobile.dart';
import '../../../features/onboarding/presentation/pages/onboarding_container.dart';
import '../../../features/search/presentation/pages/search_page.dart';
import '../../../features/seat/presentation/pages/seat_details.dart';
import '../../../features/settings/presentation/pages/app_settings.dart';
import '../../../features/tickets/presentation/pages/my_ticket_page.dart';
import '../../../features/users/presentation/pages/profile_page.dart';
import '../../../features/users/presentation/pages/user_profile_edit.dart';
import '../../../shared/navigation/providers/navigation_keys.dart';
import '../../../shared/navigation/widgets/mobile_bottom_nav_bar.dart';
import '../../../shared/navigation/widgets/web_top_navigation_bar.dart';
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
    initialLocation: isWeb ? '/' : '/app',
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
        return isWeb ? '/app' : '/app';

      return null;
    },
    routes: [
      /// 🌐 WEB LANDING PAGE (Sadece web için)
      /// Route: /
      if (isWeb)
        GoRoute(
          path: '/',
          pageBuilder: (final context, final state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AppHomePage(),
            transitionsBuilder: fadeTransition,
            transitionDuration: const Duration(milliseconds: 500),
          ),
        ),

      /// 🎭 STATEFUL SHELL ROUTE - TAB NAVIGATION
      StatefulShellRoute.indexedStack(
        builder: (final context, final state, final navigationShell) {
          if (isWeb)
            // WEB: Üst menü
            return WebTopNavigationBar(navigationShell: navigationShell);
          else
            // MOBİL: Alt menü
            return MobileBottomNavBar(navigationShell: navigationShell);
        },
        branches: [
          /// BRANCH 0: ANA SAYFA (/app)
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'shellHome'),
            routes: [
              GoRoute(
                path: '/app',
                name: 'home', // 🔧 Name ekle
                pageBuilder: (final context, final state) =>
                    CustomTransitionPage(
                  key: state.pageKey,
                  child: const HomePage(),
                  transitionsBuilder: curtainTransition,
                  transitionDuration: const Duration(milliseconds: 500),
                ),
              ),
            ],
          ),

          /// BRANCH 1: KEŞFET (/discover)
          StatefulShellBranch(
            navigatorKey:
                GlobalKey<NavigatorState>(debugLabel: 'shellDiscover'),
            routes: [
              GoRoute(
                path: '/discover',
                name: 'discover', // 🔧 Name ekle
                pageBuilder: (final context, final state) =>
                    CustomTransitionPage(
                  key: state.pageKey,
                  child: DiscoveryPage(
                      selectedCategory: state.uri.queryParameters['category']),
                  transitionsBuilder: fadeTransition,
                  transitionDuration: const Duration(milliseconds: 500),
                ),
              ),
            ],
          ),

          /// BRANCH 2: YAKINDAKİLER (/nearby)
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'shellNearby'),
            routes: [
              GoRoute(
                path: '/nearby',
                name: 'nearby', // 🔧 Name ekle
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

          /// BRANCH 3: PROFİL (/profile)
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'shellProfile'),
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile', // 🔧 Name ekle
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

      /// 🔗 DETAY SAYFALARI (Shell dışında)
      GoRoute(
        path: '/show/:slugWithId',
        name: 'showDetail',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: ShowDetailPage(
              showId: state.pathParameters['slugWithId']!.split('-').last),
          transitionsBuilder: fadeTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/player/:slugWithId',
        name: 'playerDetail',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: PlayerDetailPage(
              playerId: state.pathParameters['slugWithId']!.split('-').last),
          transitionsBuilder: curtainTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/stage/:slugWithId',
        name: 'stageDetail',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: StageDetailPage(
              stageId: state.pathParameters['slugWithId']!.split('-').last),
          transitionsBuilder: fadeTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/team/:slugWithId',
        name: 'teamDetail',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: TeamDetailsPage(
              teamId: state.pathParameters['slugWithId']!.split('-').last),
          transitionsBuilder: fadeTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/search',
        name: 'search',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: SearchPage(),
          transitionsBuilder: fadeTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: AppSettingsPage(),
          transitionsBuilder: fadeTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/favorites',
        name: 'favorites',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: FavoritesPage(),
          transitionsBuilder: cinematicFadeTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/my-tickets/:slugWithId',
        name: 'myTickets',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: MyTicketPage(
              userId: state.pathParameters['slugWithId']!.split('-').last),
          transitionsBuilder: scrollSlideTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/profile-edit/:slugWithId',
        name: 'profileEdit',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: UserProfileEditScreen(
              userId: state.pathParameters['slugWithId']!.split('-').last),
          transitionsBuilder: fadeTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/contracts',
        name: 'contracts',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: ContractsPage(),
          transitionsBuilder: shadowGateTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/help-support',
        name: 'helpSupport',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: HelpSupportPage(),
          transitionsBuilder: shadowGateTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/campaign-details',
        name: 'campaignDetails',
        pageBuilder: (final context, final state) {
          // URL'deki 'index' parametresini oku, yoksa 0 kabul et
          final indexRaw = state.uri.queryParameters['index'];
          final initialIndex = int.tryParse(indexRaw ?? '0') ?? 0;

          return CustomTransitionPage(
            key: state.pageKey,
            child: CampaignShowcasePage(initialIndex: initialIndex),
            transitionsBuilder: shadowGateTransition,
            transitionDuration: const Duration(milliseconds: 500),
          );
        },
      ),

      /// 🚪 AUTH & ONBOARDING
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: shimmerSlideTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/phone-login',
        name: 'phoneLogin',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PhoneLogInPage(),
          transitionsBuilder: shadowGateTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingContainer(),
          transitionsBuilder: curtainTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/seat-selection/:slugWithId',
        name: 'seatSelection',
        pageBuilder: (final context, final state) {
          final params = state.pathParameters['slugWithId']!.split('-');
          // URL yapısı: showId-eventId-userId
          return CustomTransitionPage(
            key: state.pageKey,
            child: SeatSelectionPage(
              showId: params[0],
              eventId: params[1],
              customerId: params[2],
            ),
            transitionsBuilder: fadeTransition,
            transitionDuration: const Duration(milliseconds: 500),
          );
        },
      ),
    ],
    errorBuilder: (final context, final state) =>
        NotFoundPage(errorPath: state.uri.path),
  );
});
