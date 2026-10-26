import 'push_message_mapper.dart';
import 'push_payload.dart';

/// FCM'in (test edilebilir) soyutlaması.
abstract class PushGateway {
  Future<String?> getToken();
  Future<void> deleteToken();
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
}

/// Kullanıcı dökümanındaki `fcmToken` alanı.
abstract class PushTokenStore {
  /// Giriş yapmış kullanıcının `fcmToken` alanını boşaltır.
  Future<void> clearTokenForCurrentUser();
}

/// Basit bool tercih deposu (SharedPreferences arkasında).
abstract class PushPrefs {
  Future<bool?> readBool(String key);
  Future<void> writeBool(String key, bool value);
}

/// Yerel bildirim gösterici.
abstract class LocalNotifier {
  Future<void> show(LocalNotificationSpec spec);
}

typedef IncomingPresenter = Future<void> Function(
    PushIncoming message, PushPayload payload);

/// Push iş mantığı: duyuru topic tercihi, çıkışta temizlik, mesaj işleme.
/// Firebase/Flutter'a doğrudan bağlı değildir; bağımlılıklar enjekte edilir.
class PushService {
  static const String announcementsTopic = 'all_users';
  static const String announcementsPrefKey = 'push_announcements_enabled';

  final PushGateway gateway;
  final PushTokenStore tokenStore;
  final PushPrefs prefs;
  final LocalNotifier notifier;

  /// Ön planda gelen alarm için uygulama içi uyarı.
  final IncomingPresenter? alarmPresenter;

  /// Ön planda gelen normal mesaj için uygulama içi şerit.
  final IncomingPresenter? bannerPresenter;

  PushService({
    required this.gateway,
    required this.tokenStore,
    required this.prefs,
    required this.notifier,
    this.alarmPresenter,
    this.bannerPresenter,
  });

  /// Varsayılan: açık.
  Future<bool> announcementsEnabled() async =>
      await prefs.readBool(announcementsPrefKey) ?? true;

  Future<void> setAnnouncementsEnabled(final bool enabled) async {
    await prefs.writeBool(announcementsPrefKey, enabled);
    if (enabled) {
      await gateway.subscribeToTopic(announcementsTopic);
    } else {
      await gateway.unsubscribeFromTopic(announcementsTopic);
    }
  }

  /// Kayıtlı tercihe göre topic aboneliğini eşitler (açılış / çıkış sonrası).
  Future<void> syncAnnouncementTopic() async {
    if (await announcementsEnabled()) {
      await gateway.subscribeToTopic(announcementsTopic);
    } else {
      await gateway.unsubscribeFromTopic(announcementsTopic);
    }
  }

  /// Çıkış / hesap değişimi ÖNCESİ çağrılır (Firestore yazısı için oturum
  /// hâlâ açık olmalı). Her adım diğerinden bağımsız denenir; biri
  /// patlarsa ötekiler yine çalışır. Dönen liste başarısız adımlardır.
  Future<List<String>> detachFromUser() async {
    final List<String> failed = [];
    Future<void> step(final String name, final Future<void> Function() f) async {
      try {
        await f();
      } catch (_) {
        failed.add(name);
      }
    }

    await step('clearToken', tokenStore.clearTokenForCurrentUser);
    await step('unsubscribe',
        () => gateway.unsubscribeFromTopic(announcementsTopic));
    await step('deleteToken', gateway.deleteToken);
    return failed;
  }

  /// Ön planda mesaj geldi.
  Future<void> handleForeground(final PushIncoming message) async {
    final PushPayload payload = PushPayload.fromData(message.data);
    if (payload.isAlarm) {
      // Ses + titreşim alarm kanalındaki yerel bildirimden gelir.
      await notifier.show(PushMessageMapper.toSpec(message));
      await alarmPresenter?.call(message, payload);
    } else {
      await bannerPresenter?.call(message, payload);
    }
  }

  /// Arka plan/kapalı: `notification` bloğu varsa sistem gösterir, yoksa
  /// (yalnız data) biz yerel bildirim olarak gösteririz.
  Future<void> handleBackground(final PushIncoming message) async {
    if (message.hasNotificationBlock) return;
    final LocalNotificationSpec spec = PushMessageMapper.toSpec(message);
    if (spec.body.isEmpty && spec.title == PushMessageMapper.defaultTitle) {
      return; // gösterilecek içerik yok
    }
    await notifier.show(spec);
  }
}
