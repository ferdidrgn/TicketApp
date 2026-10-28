import 'dart:convert';

/// Push mesajının türü. Backend sözleşmesi: `data.kind = 'normal' | 'alarm'`.
enum PushKind {
  normal,
  alarm;

  static PushKind parse(final Object? value) =>
      value == 'alarm' ? PushKind.alarm : PushKind.normal;
}

/// Android bildirim kanalı kimlikleri (backend `channelId` ile AYNI olmalı:
/// functions/src/config.js NOTIFY.ALARM_CHANNEL / DEFAULT_CHANNEL).
///
/// KURAL (sahibin kararı, docs/BILDIRIM-ISTATISTIK.md): NEVER change ringer
/// mode. Uygulama telefonun zil/sessiz/titreşim modunu ASLA değiştirmez;
/// AudioManager / setRingerMode / Rahatsız Etme (NOTIFICATION_POLICY) erişimi
/// kullanılmaz ve istenmez. Alarm kanalı yalnız kullanıcı AÇIKÇA izin verdiyse
/// (User.notifPrefs.loudAlarm) kullanılır; ses sonrası telefon kendi
/// durumunda kalır. Bu kural test/push_notifications_test.dart'ta denetlenir.
abstract final class PushChannels {
  static const String alarm = 'tiyatrol_alarm';
  static const String normal = 'tiyatrol_default';

  /// Alarm türü yalnız [loudAlarm] izni varsa alarm kanalına gider.
  static String forKind(final PushKind kind, {final bool loudAlarm = false}) =>
      kind == PushKind.alarm && loudAlarm ? alarm : normal;
}

/// FCM `data` alanlarından güvenle çözülen yük. Dışarıdan gelen her alan
/// güvenilmez kabul edilir: kimlikler yalnız `[A-Za-z0-9_-]` içerebilir.
class PushPayload {
  final PushKind kind;
  final String? eventId;
  final String? ticketId;

  /// Ham `route` değeri — kullanmadan önce [PushRoutes.safeRoute] ile doğrula.
  final String? route;

  const PushPayload({
    this.kind = PushKind.normal,
    this.eventId,
    this.ticketId,
    this.route,
  });

  static final RegExp _idPattern = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  static String? _id(final Object? v) =>
      v is String && _idPattern.hasMatch(v) ? v : null;

  factory PushPayload.fromData(final Map<String, dynamic>? data) {
    if (data == null) return const PushPayload();
    final Object? route = data['route'];
    return PushPayload(
      kind: PushKind.parse(data['kind']),
      eventId: _id(data['eventId']),
      ticketId: _id(data['ticketId']),
      route: route is String && route.length <= 200 ? route : null,
    );
  }

  bool get isAlarm => kind == PushKind.alarm;

  /// Yerel bildirimin `payload` alanı için (dokununca geri çözülür).
  String encode() => jsonEncode({
        'kind': kind.name,
        if (eventId != null) 'eventId': eventId,
        if (ticketId != null) 'ticketId': ticketId,
        if (route != null) 'route': route,
      });

  static PushPayload decode(final String? raw) {
    if (raw == null || raw.isEmpty) return const PushPayload();
    try {
      final Object? json = jsonDecode(raw);
      if (json is Map<String, dynamic>) return PushPayload.fromData(json);
    } catch (_) {}
    return const PushPayload();
  }
}

/// Bildirimden gelen yönlendirmelerin beyaz listesi: yalnız uygulama içi,
/// herkese açık / kullanıcıya ait rotalar. `/admin`, harici URL, `//`, `..`,
/// sorgu dizgisi vb. reddedilir.
abstract final class PushRoutes {
  static const String fallback = '/notifications';

  static final RegExp _fixed = RegExp(
      r'^/(app|discover|nearby|profile|favorites|settings|notifications|search)$');
  static final RegExp _detail =
      RegExp(r'^/(show|player|stage|team|my-tickets)/[A-Za-z0-9_-]{1,160}$');

  /// Geçerliyse [route], değilse `null`.
  static String? safeRoute(final String? route) {
    if (route == null) return null;
    final String r = route.trim();
    if (_fixed.hasMatch(r) || _detail.hasMatch(r)) return r;
    return null;
  }

  static String ticketsFor(final String userId) =>
      '/my-tickets/bildirim-$userId';

  static String showFor(final String showId) => '/show/bildirim-$showId';

  /// Eşzamanlı çözüm: `route` > `ticketId` > (eventId → önceden çözülmüş
  /// [showIdForEvent]) > [fallback]. Her zaman güvenli bir rota döner.
  static String resolve(
    final PushPayload payload, {
    final String? userId,
    final String? showIdForEvent,
  }) {
    final String? explicit = safeRoute(payload.route);
    if (explicit != null) return explicit;
    if (payload.ticketId != null && userId != null && userId.isNotEmpty) {
      final String? t = safeRoute(ticketsFor(userId));
      if (t != null) return t;
    }
    if (showIdForEvent != null && showIdForEvent.isNotEmpty) {
      final String? s = safeRoute(showFor(showIdForEvent));
      if (s != null) return s;
    }
    return fallback;
  }
}
