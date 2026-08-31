import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/config/seo/seo_route_observer.dart';
import 'package:ticketapp/features/home/presentation/pages/web_landing_page.dart';
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
import '../../../features/notifications/presentation/pages/notification_center_page.dart';
import '../../../features/onboarding/presentation/pages/onboarding_container.dart';
import '../../services/onboarding_service.dart';
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

// 🔑 KRİTİK DÜZELTME:
// Shell branch'lerin navigatorKey'leri önceden Provider builder'ının İÇİNDE
// oluşturuluyordu. appRouterProvider her rebuild olduğunda (ör. login/logout)
// bu key'ler de sıfırdan üretiliyor, bu da GoRouter'ın ve altındaki tüm
// Navigator/State ağacının komple yıkılıp yeniden kurulmasına yol açıyordu.
// Sonuç: login olduktan hemen sonra Profil sayfası hâlâ "giriş yapılmamış"
// gibi görünüyor, butonlara basınca login ekranı geliyordu çünkü sayfa
// yarım kalmış bir yeniden inşa (rebuild) sürecinde donuyordu.
// Artık bu key'ler modül seviyesinde SABİT (tek seferlik) oluşturuluyor.
final GlobalKey<NavigatorState> _shellHomeKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellHome');
final GlobalKey<NavigatorState> _shellDiscoverKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellDiscover');
final GlobalKey<NavigatorState> _shellNearbyKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellNearby');
final GlobalKey<NavigatorState> _shellProfileKey =
    GlobalKey<NavigatorState>(debugLabel: 'shellProfile');

final appRouterProvider = Provider<GoRouter>((final ref) {
  // 🔑 KRİTİK DÜZELTME:
  // Burada artık `ref.watch(isLoggedInProvider)` KULLANILMIYOR.
  // watch() kullanmak, login durumu her değiştiğinde bu Provider'ın (ve
  // dolayısıyla GoRouter'ın) baştan yaratılmasına sebep oluyordu - bu da
  // navigasyon geçmişini ve ekran state'lerini sıfırlıyordu.
  // Sadece ref.read ile başlangıç değeri okunuyor; sonraki güncellemeler
  // aşağıdaki ref.listen + ValueNotifier (refreshListenable) üzerinden
  // GoRouter'a iletiliyor. Böylece GoRouter nesnesi HİÇ yeniden yaratılmıyor,
  // sadece `redirect` fonksiyonu yeniden değerlendiriliyor.
  final authNotifier = ValueNotifier(ref.read(isLoggedInProvider));

  ref.listen(isLoggedInProvider, (final _, final next) {
    authNotifier.value = next;
  });

  ref.onDispose(authNotifier.dispose);

  final isWeb = kIsWeb;

  return GoRouter(
    navigatorKey: NavigationKeys.rootNavigator,
    initialLocation: isWeb
        ? '/'
        : (OnboardingService.hasSeenOnboarding ? '/app' : '/onboarding'),
    refreshListenable: authNotifier,
    observers: [
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      SeoRouteObserver(),
    ],
    redirect: (final context, final state) {
      // 🔑 Her redirect çağrısında GÜNCEL login durumu okunuyor
      // (artık asla "donmuş"/bayat bir değer değil).
      final loggedIn = authNotifier.value;
      final path = state.uri.path;

      // 🎬 Mobilde onboarding'i hiç görmemiş kullanıcı, deep-link ile bile
      // olsa başka bir yere gidemez — önce onboarding tamamlanmalı.
      if (!isWeb &&
          !OnboardingService.hasSeenOnboarding &&
          path != '/onboarding') {
        return '/onboarding';
      }

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
            child: const WebLandingPage(),
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
            navigatorKey: _shellHomeKey,
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
            navigatorKey: _shellDiscoverKey,
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
            navigatorKey: _shellNearbyKey,
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
            navigatorKey: _shellProfileKey,
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
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (final context, final state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NotificationCenterPage(),
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
