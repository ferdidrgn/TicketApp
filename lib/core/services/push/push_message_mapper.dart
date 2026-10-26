import 'push_payload.dart';

/// `RemoteMessage`'ın düz (Firebase'siz) özeti — test edilebilirlik için.
class PushIncoming {
  final String? messageId;
  final String? title;
  final String? body;
  final Map<String, dynamic> data;

  /// Mesajda `notification` bloğu var mı? Arka planda varsa sistem tepsisi
  /// bildirimi zaten kendisi gösterir; yoksa (yalnız data) biz göstermeliyiz.
  final bool hasNotificationBlock;

  const PushIncoming({
    this.messageId,
    this.title,
    this.body,
    this.data = const {},
    this.hasNotificationBlock = true,
  });
}

/// Yerel bildirim isteği (platform eklentisinden bağımsız).
class LocalNotificationSpec {
  final int id;
  final String title;
  final String body;
  final String channelId;
  final bool isAlarm;
  final String payload;

  const LocalNotificationSpec({
    required this.id,
    required this.title,
    required this.body,
    required this.channelId,
    required this.isAlarm,
    required this.payload,
  });
}

abstract final class PushMessageMapper {
  static const String defaultTitle = 'TiyatRol';
  static const String alarmTitle = 'Önemli duyuru';

  /// Kararlı, pozitif 31-bit bildirim kimliği (aynı mesaj tekrarlanırsa
  /// bildirim çoğalmaz).
  static int notificationId(final String? messageId) {
    if (messageId == null || messageId.isEmpty) {
      return DateTime.now().millisecondsSinceEpoch & 0x7fffffff;
    }
    int h = 0;
    for (final int c in messageId.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return h;
  }

  static String _clean(final String? s) => (s ?? '').trim();

  static LocalNotificationSpec toSpec(final PushIncoming m) {
    final PushPayload payload = PushPayload.fromData(m.data);
    String title = _clean(m.title);
    if (title.isEmpty) title = _clean(m.data['title']?.toString());
    if (title.isEmpty) title = payload.isAlarm ? alarmTitle : defaultTitle;
    String body = _clean(m.body);
    if (body.isEmpty) body = _clean(m.data['body']?.toString());
    return LocalNotificationSpec(
      id: notificationId(m.messageId),
      title: title,
      body: body,
      channelId: PushChannels.forKind(payload.kind),
      isAlarm: payload.isAlarm,
      payload: payload.encode(),
    );
  }
}
