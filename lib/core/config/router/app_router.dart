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

/// 🛣️ TiyatRol Büyülü Router Yapılandırması
final appRouterProvider = Provider<GoRouter>((final ref) {
  final loginState = ref.watch(loginProvider);
  final authNotifier = ValueNotifier(loginState);

  ref.listen(loginProvider, (final _, final next) {
    authNotifier.value = next;
  });

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
      /// 🌍 WEB HOME
      if (isWeb)
        GoRoute(
          path: '/home',
          builder: (final _, final __) => const AppHomePage(),
        ),

      /// 📱 MOBILE SHELL
      if (!isWeb)
        StatefulShellRoute.indexedStack(
          builder: (final context, final state, final navigationShell) {
            return MobileBottomNavBar(navigationShell: navigationShell);
          },
          branches: [
            // HOME
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  pageBuilder: (final _, final __) =>
                      const NoTransitionPage(child: HomePage()),
                ),
              ],
            ),

            // DISCOVER
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/discover',
                  pageBuilder: (final _, final __) =>
                      const NoTransitionPage(child: DiscoveryPage()),
                ),
              ],
            ),

            // NEARBY
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/nearby',
                  pageBuilder: (final _, final __) =>
                      const NoTransitionPage(child: NearbyEventsPage()),
                ),
              ],
            ),

            // PROFILE
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  pageBuilder: (final _, final __) =>
                      const NoTransitionPage(child: ProfilePage()),
                ),
              ],
            ),
          ],
        ),

      // -------------------------
      // COMMON ROUTES
      // -------------------------

      GoRoute(
        path: '/show/:id',
        builder: (final context, final state) =>
            ShowDetailPage(showId: state.pathParameters['id']!),
      ),

      GoRoute(
        path: '/login',
        builder: (final _, final __) => const LoginScreen(),
      ),

      GoRoute(
        path: '/phone-login',
        builder: (final _, final __) => const PhoneLogInPage(),
      ),

      GoRoute(
        path: '/favorites',
        builder: (final _, final __) => const FavoritesPage(),
      ),

      GoRoute(
        path: '/my-tickets/:userId',
        builder: (final context, final state) =>
            MyTicketPage(userId: state.pathParameters['userId']!),
      ),

      GoRoute(
        path: '/profile-edit/:userId',
        builder: (final context, final state) =>
            UserProfileEditScreen(userId: state.pathParameters['userId']!),
      ),

      GoRoute(
        path: '/search',
        builder: (final _, final __) => const SearchPage(),
      ),

      GoRoute(
        path: '/settings',
        builder: (final _, final __) => const AppSettingsPage(),
      ),

      GoRoute(
        path: '/contracts',
        builder: (final _, final __) => ContractsPage(),
      ),

      GoRoute(
        path: '/help-support',
        builder: (final _, final __) => HelpSupportPage(),
      ),

      GoRoute(
        path: '/onboarding',
        builder: (final _, final __) => const OnboardingContainer(),
      ),
    ],
    errorBuilder: (final context, final state) =>
        NotFoundPage(errorPath: state.uri.path),
  );
});
