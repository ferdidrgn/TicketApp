import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/appTools/presentation/pages/contracts.dart';
import '../../../features/appTools/presentation/pages/help_support_page.dart';
import '../../../features/discovery/presentation/pages/discovery_page.dart';
import '../../../features/discovery/presentation/pages/nearby_events_page.dart';
import '../../../features/favorite/presentation/pages/favorite_screen.dart';
import '../../../features/home/presentation/pages/home_page_mobile.dart';
import '../../../features/home/presentation/pages/wrapper/app_home_page.dart';
import '../../../features/login/presentation/pages/login_screen.dart';
import '../../../features/login/presentation/pages/phone_login_page.dart';
import '../../../features/login/presentation/providers/login_provider.dart';
import '../../../features/onboarding/presentation/pages/onboarding_container.dart';
import '../../../features/search/presentation/pages/search_page.dart';
import '../../../features/settings/presentation/pages/app_settings.dart';
import '../../../features/shows/presentation/pages/show_detail_page.dart';
import '../../../features/tickets/presentation/pages/my_ticket_page.dart';
import '../../../features/users/presentation/pages/profile_page.dart';
import '../../../features/users/presentation/pages/user_profile_edit.dart';
import '../../../shared/navigation/providers/navigation_keys.dart';
import '../../../shared/navigation/widgets/mobile_bottom_nav_bar.dart';
import '../../errors/not_found_page.dart';
import 'page_transitions.dart';

/// 🛣️ TiyatRol Router (Transitionlı)
final appRouterProvider = Provider<GoRouter>((final ref) {
  final loginState = ref.watch(loginProvider);
  final authNotifier = ValueNotifier(loginState);

  ref.listen(loginProvider, (final _, final next) => authNotifier.value = next);

  final isWeb = kIsWeb;

  return GoRouter(
    navigatorKey: NavigationKeys.rootNavigator,
    initialLocation: '/home',
    refreshListenable: authNotifier,
    redirect: (final context, final state) {
      final loggedIn = loginState.isLoggedIn;
      final path = state.uri.path;

      final protectedRoutes = [
        '/profile',
        '/favorites',
        '/my-tickets',
      ];

      if (!loggedIn && protectedRoutes.any(path.startsWith)) return '/login';
      if (loggedIn && (path == '/login' || path == '/phone-login'))
        return '/home';
      return null;
    },
    routes: [
      // 🌍 WEB HOME
      if (isWeb)
        GoRoute(
          path: '/home',
          pageBuilder: (final context, final state) => CustomTransitionPage(
            key: state.pageKey,
            child: const AppHomePage(),
            transitionsBuilder: curtainTransition,
            transitionDuration: const Duration(milliseconds: 500),
          ),
        ),

      // 📱 MOBILE SHELL
      if (!isWeb)
        StatefulShellRoute.indexedStack(
          builder: (final context, final state, final shell) =>
              MobileBottomNavBar(navigationShell: shell),
          branches: [
            // HOME
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
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

            // DISCOVER
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/discover',
                  pageBuilder: (final context, final state) {
                    final selectedCategory =
                        state.uri.queryParameters['category'];
                    return CustomTransitionPage(
                      key: state.pageKey,
                      child: DiscoveryPage(selectedCategory: selectedCategory),
                      transitionsBuilder: fadeTransition,
                      transitionDuration: const Duration(milliseconds: 500),
                    );
                  },
                ),
              ],
            ),

            // NEARBY
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/nearby',
                  pageBuilder: (final context, final state) =>
                      CustomTransitionPage(
                    key: state.pageKey,
                    child: const NearbyEventsPage(),
                    transitionsBuilder: scrollSlideTransition,
                    transitionDuration: const Duration(milliseconds: 500),
                  ),
                ),
              ],
            ),

            // PROFILE
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  pageBuilder: (final context, final state) =>
                      CustomTransitionPage(
                    key: state.pageKey,
                    child: const ProfilePage(),
                    transitionsBuilder: cinematicFadeTransition,
                    transitionDuration: const Duration(milliseconds: 500),
                  ),
                ),
              ],
            ),
          ],
        ),

      // COMMON ROUTES
      GoRoute(
        path: '/show/:id',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: ShowDetailPage(showId: state.pathParameters['id']!),
          transitionsBuilder: fadeTransition,
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
        path: '/favorites',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: const FavoritesPage(),
          transitionsBuilder: cinematicFadeTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/my-tickets/:userId',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: MyTicketPage(userId: state.pathParameters['userId']!),
          transitionsBuilder: scrollSlideTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/profile-edit/:userId',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: UserProfileEditScreen(userId: state.pathParameters['userId']!),
          transitionsBuilder: fadeTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/search',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SearchPage(),
          transitionsBuilder: fadeTransition,
          transitionDuration: const Duration(milliseconds: 500),
        ),
      ),

      GoRoute(
        path: '/settings',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AppSettingsPage(),
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
    ],
    errorBuilder: (final context, final state) =>
        NotFoundPage(errorPath: state.uri.path),
  );
});
