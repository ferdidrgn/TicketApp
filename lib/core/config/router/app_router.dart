import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/config/router/page_transitions.dart';
import '../../../features/home/presentation/pages/wrapper/app_home_page.dart';
import '../../../features/login/presentation/pages/login_screen.dart';
import '../../../features/login/presentation/pages/phone_login_page.dart';
import '../../../features/login/presentation/providers/login_provider.dart';
import '../../../features/onboarding/presentation/pages/onboarding_container.dart';
import '../../../features/shows/presentation/pages/show_detail_page.dart';
import '../../../features/users/presentation/pages/user_profile_edit.dart';
import '../../errors/not_found_page.dart';

/// 🛣️ App Router with Clean Auth Logic
final appRouterProvider = Provider<GoRouter>((ref) {
  final loginState = ref.watch(loginProvider);
  final authNotifier = ValueNotifier(loginState);

  ref.listen(loginProvider, (_, next) {
    authNotifier.value = next;
  });

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final currentPath = state.uri.path;
      final isLoggedIn = loginState.isLoggedIn;
      final isGuest = loginState.isGuest;

      // Page checks
      final isLoginPage = currentPath == '/login';
      final isPhoneLoginPage = currentPath == '/phone-login';
      final isOnboardingPage = currentPath == '/onboarding';
      final isProfileEditPage = currentPath.startsWith('/profile-edit');

      // Wait while loading
      if (loginState.isLoading) return null;

      // Public pages (accessible without login)
      final publicPages = ['/login', '/phone-login', '/onboarding'];
      final isPublicPage = publicPages.contains(currentPath);

      // 1. NOT LOGGED IN
      if (!isLoggedIn) {
        // Allow public pages
        if (isPublicPage) return null;

        // Otherwise redirect to login
        return '/login';
      }

      // 2. LOGGED IN
      if (isLoggedIn) {
        // If on phone login page, let them finish
        if (isPhoneLoginPage) return null;

        // If on login/onboarding page, redirect to home
        if (isLoginPage || isOnboardingPage) {
          // Unless trying to go to profile edit
          if (isProfileEditPage) return null;
          return '/home';
        }
      }

      return null;
    },
    routes: [
      // HOME
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) {
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

      // ONBOARDING
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingContainer(),
          transitionsBuilder: fadeTransition,
          transitionDuration: const Duration(milliseconds: 600),
        ),
      ),

      // LOGIN
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: slideTransition,
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),

      // PHONE LOGIN
      GoRoute(
        path: '/phone-login',
        name: 'phoneLogin',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PhoneLogInPage(),
          transitionsBuilder: slideTransition,
          transitionDuration: const Duration(milliseconds: 400),
        ),
      ),

      // PROFILE EDIT
      GoRoute(
        path: '/profile-edit/:userId',
        name: 'profileEdit',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: UserProfileEditScreen(userId: userId),
            transitionsBuilder: fadeTransition,
            transitionDuration: const Duration(milliseconds: 500),
          );
        },
      ),

      // SHOW DETAIL
      GoRoute(
        path: '/show/:id',
        name: 'showDetail',
        pageBuilder: (context, state) {
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

    // 404 Error Page
    errorBuilder: (context, state) => NotFoundPage(errorPath: state.uri.path),
  );
});
