import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/navigation/providers/navigation_keys.dart';
import '../../shared/navigation/widgets/nav_handler.dart';
import 'push/alarm_alert_dialog.dart';
import 'push/fcm_token_list.dart';
import 'push/local_notification_service.dart';
import 'push/push_message_mapper.dart';
import 'push/push_payload.dart';
import 'push/push_service.dart';

// Manager'ı Singleton olarak dışarı açar
final fcmServiceProvider =
    Provider<FCMManager>((final ref) => FCMManager.instance);

// Başlatma işlemini takip eden provider
final fcmInitializerProvider = FutureProvider<void>(
    (final ref) async => ref.read(fcmServiceProvider).init());

/// "Duyuruları al" (topic `all_users`) tercihi. Ayarlar ekranındaki anahtar.
class AnnouncementsEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => FCMManager.instance.service.announcementsEnabled();

  Future<void> set(final bool enabled) async {
    state = AsyncData(enabled);
    try {
      await FCMManager.instance.service.setAnnouncementsEnabled(enabled);
    } catch (e) {
      debugPrint('Duyuru tercihi uygulanamadı: $e');
      state = AsyncData(!enabled);
    }
  }
}

final announcementsEnabledProvider =
    AsyncNotifierProvider<AnnouncementsEnabledNotifier, bool>(
        AnnouncementsEnabledNotifier.new);

/// "Sessizdeyken de sesli hatırlat" tercihi (varsayılan KAPALI).
/// Açma, [LoudAlarmResult.permissionDenied] dönebilir: bildirim izni verilmediyse
/// tercih AÇILMAZ. Telefonun zil/sessiz modu hiçbir durumda değiştirilmez.
enum LoudAlarmResult { enabled, disabled, permissionDenied, failed }

class LoudAlarmEnabledNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => FCMManager.instance.service.loudAlarmEnabled();

  Future<LoudAlarmResult> set(final bool enabled) async {
    try {
      if (enabled) {
        // Android 13+ POST_NOTIFICATIONS / iOS bildirim izni. Yalnız bildirim
        // izni istenir; Rahatsız Etme (NOTIFICATION_POLICY) erişimi İSTENMEZ.
        final PermissionStatus st = await Permission.notification.request();
        if (!st.isGranted && !st.isProvisional) {
          state = const AsyncData(false);
          return LoudAlarmResult.permissionDenied;
        }
      }
      await FCMManager.instance.service.setLoudAlarmEnabled(enabled);
      state = AsyncData(enabled);
      return enabled ? LoudAlarmResult.enabled : LoudAlarmResult.disabled;
    } catch (e) {
      debugPrint('Sesli hatırlatma tercihi uygulanamadı: $e');
      return LoudAlarmResult.failed;
    }
  }
}

final loudAlarmEnabledProvider =
    AsyncNotifierProvider<LoudAlarmEnabledNotifier, bool>(
        LoudAlarmEnabledNotifier.new);

// ───────────────────────── Firebase bağdaştırıcıları ─────────────────────────

class _FirebasePushGateway implements PushGateway {
  FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  @override
  Future<String?> getToken() => _fcm.getToken();
  @override
  Future<void> deleteToken() => _fcm.deleteToken();
  @override
  Future<void> subscribeToTopic(final String topic) =>
      _fcm.subscribeToTopic(topic);
  @override
  Future<void> unsubscribeFromTopic(final String topic) =>
      _fcm.unsubscribeFromTopic(topic);
}

class _FirestoreTokenStore implements PushTokenStore {
  @override
  Future<void> clearTokenForCurrentUser(final String? token) async {
    final User? u = FirebaseAuth.instance.currentUser;
    if (u == null || u.isAnonymous || token == null || token.isEmpty) return;
    final ref = FirebaseFirestore.instance.collection('User').doc(u.uid);
    await FirebaseFirestore.instance.runTransaction((final tx) async {
      final Map<String, dynamic>? d = (await tx.get(ref)).data();
      if (d == null) return;
      final Map<String, Object?> patch = {};
      if (d['fcmTokens'] is List) {
        patch['fcmTokens'] = FcmTokenList.remove(d['fcmTokens'], token);
      }
      // Eski tekil alan yalnız bu cihaza aitse boşaltılır.
      if (d['fcmToken'] == token) patch['fcmToken'] = '';
      if (patch.isNotEmpty) tx.update(ref, patch);
    });
  }
}

class _FirestoreLoudAlarmRemote implements LoudAlarmRemote {
  @override
  Future<void> write(final bool enabled) async {
    final User? u = FirebaseAuth.instance.currentUser;
    if (u == null || u.isAnonymous) return;
    await FirebaseFirestore.instance
        .collection('User')
        .doc(u.uid)
        .update({'notifPrefs': {'loudAlarm': enabled}});
  }
}

class _SharedPrefsStore implements PushPrefs {
  @override
  Future<bool?> readBool(final String key) async =>
      (await SharedPreferences.getInstance()).getBool(key);
  @override
  Future<void> writeBool(final String key, final bool value) async =>
      (await SharedPreferences.getInstance()).setBool(key, value);
}

PushIncoming _incomingFrom(final RemoteMessage m) => PushIncoming(
      messageId: m.messageId,
      title: m.notification?.title,
      body: m.notification?.body,
      data: m.data,
      hasNotificationBlock: m.notification != null,
    );

class FCMManager {
  FCMManager._() {
    service = PushService(
      gateway: _FirebasePushGateway(),
      tokenStore: _FirestoreTokenStore(),
      prefs: _SharedPrefsStore(),
      notifier: LocalNotificationService.instance,
      loudAlarmRemote: _FirestoreLoudAlarmRemote(),
      alarmPresenter: _presentAlarm,
      bannerPresenter: _presentBanner,
    );
  }

  static final FCMManager instance = FCMManager._();

  late final PushService service;
  bool _started = false;

  // Servisi başlat ve izinleri yönet (yalnız mobil; web sitesi artık
  // ayrı HTML projesi ve FCM'i kullanmıyor).
  Future<void> init() async {
    if (kIsWeb || _started) return;
    _started = true;
    final FirebaseMessaging fcm = FirebaseMessaging.instance;

    // 1. Yerel bildirim eklentisi + Android kanalları (idempotent).
    await LocalNotificationService.instance
        .ensureInitialized(onTap: _onLocalNotificationTap);

    // 2. İzinleri tazele
    await fcm.requestPermission(alert: true, badge: true, sound: true);

    // iOS ön planda sistem bannerı göstermesin: yerel bildirim/banner biz.
    await fcm.setForegroundNotificationPresentationOptions(
        alert: false, badge: false, sound: false);

    // Arka plan / kapalı mesajlar (top-level işleyici).
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Duyuru topic'i: kullanıcının kayıtlı tercihine göre (varsayılan açık).
    try {
      await service.syncAnnouncementTopic();
    } catch (e) {
      debugPrint('Duyuru topic aboneliği eşitlenemedi: $e');
    }

    final String? token = await fcm.getToken();
    if (kDebugMode) debugPrint('FCM token alındı (${token?.length ?? 0} krk)');

    // Oturum açık bir kullanıcı varsa güncel token'ı dökümanına yaz.
    // Giriş SIRASINDA yapılan asıl kayıt auth_mutation_provider.dart ->
    // _handlePostLogin içinde.
    await registerTokenForCurrentUser(token);
    fcm.onTokenRefresh.listen(registerTokenForCurrentUser);

    _setupListeners(fcm);
    unawaited(_handleLaunchTaps(fcm));
  }

  /// Şu an giriş yapmış (anonim OLMAYAN) kullanıcının Firestore
  /// dökümanına FCM token'ını yazar.
  ///
  /// NOT (MİMARİ TERCİH): FCMManager bir core servisi — Users feature'ının
  /// zincirini import etmek yerine diğer datasource'larla AYNI SEVİYEDE
  /// doğrudan Firestore'a yazıyoruz (collection('User')).
  Future<void> registerTokenForCurrentUser(final String? token) async {
    if (token == null || token.isEmpty) return;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null || firebaseUser.isAnonymous) return;

    try {
      // Token ile "sessizde sesli hatırlat" tercihi AYNI cihaza aittir: birlikte
      // yazılır (tercih hiç seçilmediyse yazılmaz -> sunucuda varsayılan KAPALI).
      final bool? loud = await service.loudAlarmPreference();
      final ref =
          FirebaseFirestore.instance.collection('User').doc(firebaseUser.uid);
      // Çoklu cihaz: token listeye eklenir (en çok 5, en eskisi düşer; bu yüzden
      // salt arrayUnion değil işlem içinde okuyup birleştirilir). Eski sürümler
      // çalışsın diye tekil `fcmToken` da son cihazla güncellenir.
      await FirebaseFirestore.instance.runTransaction((final tx) async {
        final Map<String, dynamic>? d = (await tx.get(ref)).data();
        final Object? old = d?['fcmToken'];
        tx.update(ref, {
          'fcmTokens': FcmTokenList.add(
              d?['fcmTokens'], old is String ? old : null, token),
          'fcmToken': token,
          if (loud != null) 'notifPrefs': {'loudAlarm': loud},
        });
      });
    } catch (e) {
      debugPrint("FCM token Firestore'a yazılamadı: $e");
    }
  }

  /// Giriş sonrası: bu cihazın kayıtlı "sessizde sesli hatırlat" tercihini
  /// (seçildiyse) giriş yapan hesaba yazar. Oturum yoksa/anonimse atlanır.
  Future<void> syncLoudAlarmPref() async {
    if (kIsWeb) return;
    final bool? loud = await service.loudAlarmPreference();
    if (loud == null) return;
    await _FirestoreLoudAlarmRemote().write(loud);
  }

  /// ÇIKIŞTAN ÖNCE çağır: User.fcmToken'ı boşaltır, topic'ten çıkar,
  /// cihaz token'ını siler (eski token başka hesaba bildirim sızdırmasın).
  Future<void> detachFromUser() async {
    if (kIsWeb) return;
    final failed = await service.detachFromUser();
    if (failed.isNotEmpty) debugPrint('FCM temizlik adımları başarısız: $failed');
  }

  /// Çıkıştan sonra: token silindiği için topic aboneliğini (tercih açıksa)
  /// yeni token ile yeniden kurar. Kullanıcıya özel veri taşımaz.
  Future<void> syncAnnouncementTopic() async {
    if (kIsWeb) return;
    try {
      await service.syncAnnouncementTopic();
    } catch (e) {
      debugPrint('Duyuru topic aboneliği eşitlenemedi: $e');
    }
  }

  void _setupListeners(final FirebaseMessaging fcm) {
    // UYGULAMA AÇIKKEN GELEN HER MESAJ
    FirebaseMessaging.onMessage.listen((final RemoteMessage message) {
      unawaited(service.handleForeground(_incomingFrom(message)));
    });

    // BİLDİRİME (sistem tepsisi) DOKUNARAK ARKA PLANDAN GİRİLDİĞİNDE
    FirebaseMessaging.onMessageOpenedApp.listen((final RemoteMessage message) {
      unawaited(_openPayload(PushPayload.fromData(message.data)));
    });
  }

  /// Uygulama KAPALIYKEN bildirime dokunularak açıldıysa.
  Future<void> _handleLaunchTaps(final FirebaseMessaging fcm) async {
    try {
      final RemoteMessage? initial = await fcm.getInitialMessage();
      if (initial != null) {
        await _openPayload(PushPayload.fromData(initial.data));
        return;
      }
      final String? local = await LocalNotificationService.instance.launchPayload();
      if (local != null) await _openPayload(PushPayload.decode(local));
    } catch (e) {
      debugPrint('İlk bildirim işlenemedi: $e');
    }
  }

  void _onLocalNotificationTap(final String? payload) =>
      unawaited(_openPayload(PushPayload.decode(payload)));

  // ─────────────────────────── Yönlendirme ───────────────────────────

  Future<String?> _showIdForEvent(final String eventId) async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('Event').doc(eventId).get();
      final Object? showId = snap.data()?['showId'];
      return showId is String && showId.isNotEmpty ? showId : null;
    } catch (_) {
      return null;
    }
  }

  /// Yükten güvenli hedef rotayı çözer ve gider.
  Future<void> _openPayload(final PushPayload payload) async {
    String? showId;
    if (payload.route == null && payload.ticketId == null &&
        payload.eventId != null) {
      showId = await _showIdForEvent(payload.eventId!);
    }
    final String target = PushRoutes.resolve(
      payload,
      userId: FirebaseAuth.instance.currentUser?.uid,
      showIdForEvent: showId,
    );
    await _goWhenReady(target);
  }

  /// Bildirim kutusundaki bir etkinliğe bağlı kayıttan açmak için.
  Future<void> openEvent(final String eventId) =>
      _openPayload(PushPayload(eventId: eventId));

  /// Soğuk açılışta router henüz hazır değilse kısa süre bekleyip dener.
  Future<void> _goWhenReady(final String location) async {
    for (int i = 0; i < 20; i++) {
      final ctx = NavigationKeys.rootNavigator.currentContext;
      if (ctx != null && ctx.mounted) {
        NavigationHandler.globalGoTo(location);
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }

  // ───────────────────── Uygulama içi sunum (ön plan) ─────────────────────

  Future<void> _presentAlarm(
      final PushIncoming message, final PushPayload payload) async {
    final context = NavigationKeys.rootNavigator.currentContext;
    if (context == null || !context.mounted) return;
    final spec = PushMessageMapper.toSpec(message);
    await AlarmAlertDialog.show(
      context,
      title: spec.title,
      body: spec.body,
      onOpen: () => unawaited(_openPayload(payload)),
    );
  }

  Future<void> _presentBanner(
      final PushIncoming message, final PushPayload payload) async {
    final context = NavigationKeys.rootNavigator.currentContext;
    if (context == null || !context.mounted) return;
    final spec = PushMessageMapper.toSpec(message);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(spec.title,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              if (spec.body.isNotEmpty) Text(spec.body),
            ],
          ),
          action: SnackBarAction(
            label: 'Görüntüle',
            onPressed: () => unawaited(_openPayload(payload)),
          ),
        ),
      );
  }
}

// ARKA PLAN HANDLER (Main dışında, top-level olmalı)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    final RemoteMessage message) async {
  await Firebase.initializeApp();
  // Ayrı isolate: kanallar burada da (idempotent) hazırlanır; yalnız-data
  // mesajlar yerel bildirim olarak gösterilir.
  await LocalNotificationService.instance.ensureInitialized();
  final service = PushService(
    gateway: _FirebasePushGateway(),
    tokenStore: _FirestoreTokenStore(),
    prefs: _SharedPrefsStore(),
    notifier: LocalNotificationService.instance,
  );
  await service.handleBackground(_incomingFrom(message));
}
