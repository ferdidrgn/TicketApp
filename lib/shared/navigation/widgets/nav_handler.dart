import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/common/extentions/reg_exp_extentions.dart';
import '../../widgets/tiyatrol_hero.dart';
import '../providers/navigation_keys.dart';

/// 🧭 Global Navigation Handler
/// Merkezi navigasyon mantığı: Safe navigation ve otomatik path encoding sağlar.
class NavigationHandler {
  NavigationHandler._();

  static final NavigationHandler instance = NavigationHandler._();

  // ═══════════════════════════════════════════════════════════════
  // CORE LOGIC (AZ KOD - ÇOK İŞ)
  // ═══════════════════════════════════════════════════════════════

  /// Merkezi Güvenli Navigasyon: Frame çakışmalarını önler.
  static void _safeNavigate(
      final BuildContext context, final String targetPath) {
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (context.mounted) context.go(targetPath);
    });
  }

  /// Detay sayfaları: `push` — kaynak kart ağaçta kalır, Hero geri uçabilir.
  static void _safePush(
    final BuildContext context,
    final String targetPath, {
    final Object? extra,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      if (context.mounted) context.push(targetPath, extra: extra);
    });
  }

  /// Ortak Path Oluşturucu: Slug ve 'from' parametresini otomatik ekler.
  /// Bu metod kod tekrarını önleyen "Hook" mantığıdır.
  static String _buildPath(final BuildContext context, final String baseRoute,
      {final String? slug,
      final String? id,
      final Map<String, String>? extraParams}) {
    final String currentPath = GoRouterState.of(context).uri.path;
    String finalPath = baseRoute;

    // Eğer id ve slug varsa slug-id formatına çevir (SEO dostu)
    if (slug != null && id != null)
      finalPath += '/${slug.toSlug()}-$id';
    else if (id != null) finalPath += '/$id';

    // Geri dönüş rotasını (from) ve varsa extra parametreleri ekle
    final uri = Uri(
      path: finalPath,
      queryParameters: {
        'from': currentPath,
        if (extraParams != null) ...extraParams,
      },
    );

    return uri.toString();
  }

  // ═══════════════════════════════════════════════════════════════
  // REFACTORED ROUTES (DAHA KISA VE TEMİZ)
  // ═══════════════════════════════════════════════════════════════

  // Basit Rotalar
  static void goToHome(final BuildContext context) => context.go('/app');

  static void goToApp(final BuildContext context) => context.go('/app');

  static void goToSearch(final BuildContext context) => context.go('/search');

  // 🔧 FIX: Direkt go() kullanımı, initialLocation parametresi kaldırıldı
  static void goToNearby(final BuildContext context) => context.go('/nearby');

  static void goToDiscover(final BuildContext context) =>
      context.go('/discover');

  static void goToProfile(final BuildContext context) => context.go('/profile');

  static void goToDiscoverWithCategory(
          final BuildContext context, final String category) =>
      // Kategori adı '&', '#', '+' gibi karakterler içerebilir; kodlanmazsa
      // adres kesilir ve Keşfet sessizce "Tümü"ne düşer.
      context.go(
          '/discover?category=${Uri.encodeQueryComponent(category.trim())}');

  static void goToShow(final BuildContext context, final String showId,
          final String showSlug,
          {final String? heroTag,
          final String? imageUrl,
          final String? title}) =>
      _safePush(
        context,
        _buildPath(context, '/show', slug: showSlug, id: showId),
        extra: TiyatrolHeroFlight.extra(
          heroTag: heroTag,
          imageUrl: imageUrl,
          title: title ?? showSlug,
        ),
      );

  static void goToPlayer(final BuildContext context, final String playerId,
          final String playerSlug,
          {final String? heroTag,
          final String? imageUrl,
          final String? title}) =>
      _safePush(
        context,
        _buildPath(context, '/player', slug: playerSlug, id: playerId),
        extra: TiyatrolHeroFlight.extra(
          heroTag: heroTag,
          imageUrl: imageUrl,
          title: title ?? playerSlug,
        ),
      );

  static void goToStage(final BuildContext context, final String stageId,
          final String stageSlug,
          {final String? heroTag,
          final String? imageUrl,
          final String? title}) =>
      _safePush(
        context,
        _buildPath(context, '/stage', slug: stageSlug, id: stageId),
        extra: TiyatrolHeroFlight.extra(
          heroTag: heroTag,
          imageUrl: imageUrl,
          title: title ?? stageSlug,
        ),
      );

  static void goToTeam(final BuildContext context, final String teamId,
          final String teamSlug,
          {final String? heroTag,
          final String? imageUrl,
          final String? title}) =>
      _safePush(
        context,
        _buildPath(context, '/team', slug: teamSlug, id: teamId),
        extra: TiyatrolHeroFlight.extra(
          heroTag: heroTag,
          imageUrl: imageUrl,
          title: title ?? teamSlug,
        ),
      );

  static void goToSeatSelection(final BuildContext context, final String showId,
          final String eventId, final String userId) =>
      _safeNavigate(
          context,
          _buildPath(context, '/seat-selection',
              id: '$showId-$eventId-$userId'));

  static void goToMyTickets(final BuildContext context, final String userId) =>
      _safeNavigate(
          context, _buildPath(context, '/my-tickets', id: userId.toSlug()));

  static void goToLogin(final BuildContext context) =>
      _safeNavigate(context, _buildPath(context, '/login'));

  static void goToPhoneLogin(final BuildContext context) =>
      _safeNavigate(context, _buildPath(context, '/phone-login'));

  static void goToFavorites(final BuildContext context) =>
      _safeNavigate(context, _buildPath(context, '/favorites'));

  static void goToContracts(final BuildContext context) =>
      _safeNavigate(context, _buildPath(context, '/contracts'));

  static void goToSettings(final BuildContext context) =>
      _safeNavigate(context, _buildPath(context, '/settings'));

  static void goToInstrumentStage(final BuildContext context) =>
      _safeNavigate(context, _buildPath(context, '/settings/instruments'));

  static void goToNotifications(final BuildContext context) =>
      _safeNavigate(context, _buildPath(context, '/notifications'));

  static void goToHelpSupport(final BuildContext context) =>
      _safeNavigate(context, _buildPath(context, '/help-support'));

  static void goToCampaigns(final BuildContext context, {final int? index}) =>
      _safeNavigate(
          context,
          _buildPath(context, '/campaign-details',
              extraParams: {if (index != null) 'index': index.toString()}));

// ═══════════════════════════════════════════════════════════════
// SMART BACK NAVIGATION
// ═══════════════════════════════════════════════════════════════

  static void smartGoBack(final BuildContext context) {
    // Push ile açılan detayda pop = Hero geri uçar. `from` yalnızca
    // yığın yoksa (derin bağ) kullanılır.
    if (context.canPop()) {
      context.pop();
      return;
    }
    final String? fromRoute =
        GoRouterState.of(context).uri.queryParameters['from'];
    if (fromRoute != null && fromRoute.isNotEmpty) {
      context.go(Uri.decodeComponent(fromRoute));
      return;
    }
    context.go('/app');
  }

  static bool canGoBack(final BuildContext context) {
    final state = GoRouterState.of(context);
    final fromRoute = state.uri.queryParameters['from'];
    return fromRoute != null || Navigator.canPop(context);
  }

  static NavigatorState? get _rootNav =>
      NavigationKeys.rootNavigator.currentState;

  static void globalGoTo(final String location) =>
      _rootNav?.context.go(location);
}
