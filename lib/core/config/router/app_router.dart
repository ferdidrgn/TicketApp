import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ticketapp/core/config/router/page_transitions.dart';
import '../../../features/home/presentation/pages/wrapper/app_home_page.dart';
import '../../../features/login/presentation/pages/login_screen.dart';
import '../../../features/login/presentation/providers/login_provider.dart';
import '../../../features/onboarding/presentation/pages/onboarding_container.dart';
import '../../../features/shows/presentation/pages/show_detail_page_mobil.dart';
import '../../errors/not_found_page.dart';

final appRouterProvider = Provider<GoRouter>((final ref) {
  // 1. Login State'i izle
  final loginState = ref.watch(loginProvider);

  // 2. 🔥 YENİ EKLENEN KISIM: Router'ı dürtecek bir dinleyici oluşturuyoruz.
  // Bu dinleyiciye ihtiyacımız var çünkü GoRouter, "Ne zaman tekrar redirect çalıştırayım?" diye sorar.
  // LoginState her değiştiğinde bu notifier tetiklenecek.
  final authNotifier = ValueNotifier(loginState);

  // Riverpod dinleyicisi: State her değiştiğinde Router'ın dinleyicisini güncelle.
  ref.listen(loginProvider, (previous, next) {
    authNotifier.value = next; // Router'a "Hey, durum değişti!" sinyali gönder.
  });

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: '/home',

    // 3. 🔥 YENİ EKLENEN KISIM: refreshListenable
    // Router artık bu notifier her değiştiğinde "redirect" fonksiyonunu tekrar çalıştıracak.
    refreshListenable: authNotifier,

    redirect: (final context, final state) {
      final isWeb = kIsWeb;
      final currentPath = state.uri.path;

      // Web Senaryosu
      if (isWeb) {
        if (currentPath == '/') return '/home';
        return null;
      }

      // Mobil Senaryosu
      // 🔥 DİKKAT: Artık doğrudan 'loginState' yerine en güncel 'authNotifier.value' üzerinden de bakabiliriz
      // ama ref.watch(loginProvider) zaten bu fonksiyonu rebuild ettirmez, refreshListenable ettirir.
      // O yüzden buradaki loginState değişkeni (yukarıda tanımlı) o anki güncel değer olmayabilir.
      // EN SAĞLAMI: redirect içinde provider'ı tekrar okumaktır AMA GoRouter içinde ref.read önerilmez.
      // Bu yüzden refreshListenable üzerinden gelen tetikleme ile loginState değişkeninin güncel halini kullanmamız lazım.
      // Yukarıdaki ref.watch sayesinde bu provider her değiştiğinde bu blok (appRouterProvider)
      // yeniden oluştuğu için loginState günceldir.

      final isLoggedIn = loginState.user != null;
      final isLoggingIn = currentPath == '/login';
      final isOnboarding = currentPath == '/onboarding';
      final isLoading = loginState.isLoading;

      // 1. Yükleniyorsa Bekle (null döndür, mevcut sayfada -Splash- kalsın)
      if (isLoading) return null;

      // 2. Yükleme Bitti, Giriş Yapılmamış -> Login'e git
      if (!isLoggedIn && !isLoggingIn && !isOnboarding) return '/login';

      // 3. Giriş Yapılmış ama Login sayfasına gitmeye çalışıyor -> Home'a at
      if (isLoggedIn && isLoggingIn) return '/home';

      return null;
    },

    routes: [
      // ... (Route tanımların AYNI kalsın) ...
      // Home, Login, ShowDetail vs.
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
    errorBuilder: (context, state) => NotFoundPage(errorPath: state.uri.path),
  );
});