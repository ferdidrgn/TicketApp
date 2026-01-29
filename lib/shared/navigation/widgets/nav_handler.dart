import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/common/extentions/reg_exp_extentions.dart';
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

  static void goToNearby(final BuildContext context) =>
      _safeNavigate(context, _buildPath(context, '/nearby'));

  static void goToProfile(final BuildContext context) =>
      _safeNavigate(context, _buildPath(context, '/profile'));

  static void goToDiscoverWithCategory(
          final BuildContext context, final String category) =>
      _safeNavigate(
          context, _buildPath(context, '/discover?category=$category'));

  static void goToShow(final BuildContext context, final String showId,
          final String showSlug) =>
      _safeNavigate(
          context, _buildPath(context, '/show', slug: showSlug, id: showId));

  static void goToPlayer(final BuildContext context, final String playerId,
          final String playerSlug) =>
      _safeNavigate(context,
          _buildPath(context, '/player', slug: playerSlug, id: playerId));

  static void goToStage(final BuildContext context, final String stageId,
          final String stageSlug) =>
      _safeNavigate(
          context, _buildPath(context, '/stage', slug: stageSlug, id: stageId));

  static void goToTeam(final BuildContext context, final String teamId,
          final String teamSlug) =>
      _safeNavigate(
          context, _buildPath(context, '/team', slug: teamSlug, id: teamId));

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

  static void goToHelpSupport(final BuildContext context) =>
      _safeNavigate(context, _buildPath(context, '/help-support'));

  // ═══════════════════════════════════════════════════════════════
  // SMART BACK NAVIGATION
  // ═══════════════════════════════════════════════════════════════

  static void smartGoBack(final BuildContext context) {
    final state = GoRouterState.of(context);
    final fromRoute = state.uri.queryParameters['from'];

    if (fromRoute != null && fromRoute.isNotEmpty)
      context.go(Uri.decodeComponent(fromRoute));
    else {
      if (Navigator.canPop(context))
        Navigator.pop(context);
      else
        context.go('/app');
    }
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
