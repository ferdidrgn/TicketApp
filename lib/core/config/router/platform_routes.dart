import 'package:flutter/foundation.dart';

class PlatformRoutes {
  PlatformRoutes._();

  static bool get isWeb => kIsWeb;

  /// ROOT
  static String get appRoot => isWeb ? '/' : '/app';

  /// TABS
  static String discover() => isWeb ? '/discover' : '/app/discover';

  static String nearby() => isWeb ? '/nearby' : '/app/nearby';

  static String profile() => isWeb ? '/profile' : '/app/profile';

  /// AUTH
  static String login() => '/login';

  static String phoneLogin() => '/phone-login';

  /// STATIC
  static String search() => '/search';

  static String settings() => '/settings';

  static String contracts() => '/contracts';

  static String helpSupport() => '/help-support';

  /// DETAILS (WEB + MOBILE AYNI)
  static String show(final String id, final String slug) => '/show/$slug-$id';

  static String player(final String id, final String slug) =>
      '/player/$slug-$id';

  static String stage(final String id, final String slug) => '/stage/$slug-$id';

  static String team(final String id, final String slug) => '/team/$slug-$id';

  static String seatSelection(
    final String showId,
    final String eventId,
    final String userId,
  ) =>
      '/seat-selection/$showId-$eventId-$userId';

  static String profileEdit(final String userId) => '/profile-edit/$userId';

  static String myTickets(final String userId) => '/my-tickets/$userId';

  static String campaigns({final int? index}) =>
      index != null ? '/campaign-details?index=$index' : '/campaign-details';
}
