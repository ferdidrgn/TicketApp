import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ticketapp/core/services/push/fcm_token_list.dart';
import 'package:ticketapp/core/services/push/push_message_mapper.dart';
import 'package:ticketapp/core/services/push/push_payload.dart';
import 'package:ticketapp/core/services/push/push_service.dart';
import 'package:ticketapp/features/notifications/data/mappers/notification_mapper.dart';
import 'package:ticketapp/features/notifications/data/models/notification_model.dart';
import 'package:ticketapp/features/notifications/domain/entities/app_notification.dart';

class FakeGateway implements PushGateway {
  final List<String> calls = [];
  bool failDelete = false;
  @override
  Future<String?> getToken() async => 'tok';
  @override
  Future<void> deleteToken() async {
    calls.add('deleteToken');
    if (failDelete) throw Exception('boom');
  }

  @override
  Future<void> subscribeToTopic(final String topic) async =>
      calls.add('sub:$topic');
  @override
  Future<void> unsubscribeFromTopic(final String topic) async =>
      calls.add('unsub:$topic');
}

class FakeTokenStore implements PushTokenStore {
  final List<String> calls;
  bool fail = false;
  FakeTokenStore(this.calls);
  final List<String?> clearedTokens = [];
  @override
  Future<void> clearTokenForCurrentUser(final String? token) async {
    clearedTokens.add(token);
    calls.add('clearToken');
    if (fail) throw Exception('firestore');
  }
}

class FakePrefs implements PushPrefs {
  final Map<String, bool> map = {};
  @override
  Future<bool?> readBool(final String key) async => map[key];
  @override
  Future<void> writeBool(final String key, final bool value) async =>
      map[key] = value;
}

class FakeLoudRemote implements LoudAlarmRemote {
  final List<bool> writes = [];
  bool fail = false;
  @override
  Future<void> write(final bool enabled) async {
    if (fail) throw Exception('offline');
    writes.add(enabled);
  }
}

class FakeNotifier implements LocalNotifier {
  final List<LocalNotificationSpec> shown = [];
  @override
  Future<void> show(final LocalNotificationSpec spec) async => shown.add(spec);
}

void main() {
  group('Zil modu kuralı: NEVER change ringer mode', () {
    test('lib/ ve Android tarafında ringer-DND politikası API yok', () {
      // Sahibin kuralı: telefonun sessiz/zil modunu ASLA değiştirmeyiz.
      final banned = RegExp(
          r'AudioManager|setRingerMode|setStreamVolume|ACCESS_NOTIFICATION_POLICY|MODIFY_AUDIO_SETTINGS|NotificationPolicyAccess|setInterruptionFilter|bypassDnd:\s*true|setBypassDnd\(true|canBypassDnd');
      final roots = <Directory>[
        Directory('lib'),
        Directory('android/app/src'),
      ];
      final hits = <String>[];
      for (final d in roots.where((final d) => d.existsSync())) {
        for (final f in d.listSync(recursive: true).whereType<File>()) {
          final n = f.path.replaceAll(r'\', '/');
          if (!(n.endsWith('.dart') ||
              n.endsWith('.kt') ||
              n.endsWith('.java') ||
              n.endsWith('.xml'))) {
            continue;
          }
          final text = f.readAsStringSync();
          // Yorumlardaki kural açıklamaları sayılmaz.
          final code = text
              .split('\n')
              .where((final l) => !l.trimLeft().startsWith('//') &&
                  !l.trimLeft().startsWith('///') &&
                  !l.trimLeft().startsWith('*'))
              .join('\n');
          if (banned.hasMatch(code)) hits.add(n);
        }
      }
      expect(hits, isEmpty, reason: 'Yasak ses/DND API: $hits');
    });
  });

  group('PushRoutes (beyaz liste)', () {
    test('geçerli uygulama içi rotalar kabul edilir', () {
      for (final r in [
        '/notifications',
        '/app',
        '/my-tickets/bildirim-abc123',
        '/show/oyun-adi-XyZ9',
        '/stage/s-1',
      ]) {
        expect(PushRoutes.safeRoute(r), r, reason: r);
      }
    });

    test('tehlikeli / bilinmeyen rotalar reddedilir', () {
      for (final r in [
        'https://evil.example/x',
        '//evil.example',
        '/admin',
        '/show/../admin',
        '/show/a?x=1',
        '/login',
        'javascript:alert(1)',
        '/notifications/../admin',
        '',
        null,
      ]) {
        expect(PushRoutes.safeRoute(r), isNull, reason: '$r');
      }
    });

    test('resolve: route > ticketId > event > varsayılan', () {
      expect(
          PushRoutes.resolve(const PushPayload(route: '/favorites')),
          '/favorites');
      expect(
          PushRoutes.resolve(const PushPayload(route: 'https://x.y'),
              userId: 'u1', showIdForEvent: null),
          '/notifications');
      expect(
          PushRoutes.resolve(const PushPayload(ticketId: 't1'), userId: 'u1'),
          '/my-tickets/bildirim-u1');
      expect(PushRoutes.resolve(const PushPayload(ticketId: 't1')),
          '/notifications'); // giriş yok -> güvenli varsayılan
      expect(
          PushRoutes.resolve(const PushPayload(eventId: 'e1'),
              showIdForEvent: 'show9'),
          '/show/bildirim-show9');
    });

    test('payload kimlikleri temizlenir ve encode/decode gidiş-dönüş yapar',
        () {
      final p = PushPayload.fromData({
        'kind': 'alarm',
        'eventId': 'ev_1',
        'ticketId': '../../x',
        'route': '/notifications',
      });
      expect(p.isAlarm, isTrue);
      expect(p.ticketId, isNull);
      final back = PushPayload.decode(p.encode());
      expect(back.kind, PushKind.alarm);
      expect(back.eventId, 'ev_1');
      expect(PushPayload.decode('not json').kind, PushKind.normal);
      expect(PushPayload.fromData({'kind': 'whatever'}).kind, PushKind.normal);
    });
  });

  group('PushMessageMapper', () {
    test('alarm + izin YOK (varsayılan) -> normal kanal; izinli -> alarm kanalı',
        () {
      const m = PushIncoming(data: {'kind': 'alarm'});
      final off = PushMessageMapper.toSpec(m);
      expect(off.channelId, 'tiyatrol_default');
      expect(off.isAlarm, isTrue); // tür korunur (uygulama içi uyarı), kanal normal
      expect(PushMessageMapper.toSpec(m, loudAlarm: true).channelId,
          'tiyatrol_alarm');
      // normal tür izinli kullanıcıda bile alarm kanalına GİTMEZ.
      expect(
          PushMessageMapper.toSpec(const PushIncoming(data: {}), loudAlarm: true)
              .channelId,
          'tiyatrol_default');
    });

    test('alarm (izinli) -> tiyatrol_alarm kanalı', () {
      final s = PushMessageMapper.toSpec(
          const PushIncoming(
              messageId: 'm1',
              title: 'Sahne değişti',
              body: 'Salon B',
              data: {'kind': 'alarm', 'eventId': 'e1'}),
          loudAlarm: true);
      expect(s.channelId, 'tiyatrol_alarm');
      expect(s.isAlarm, isTrue);
      expect(s.title, 'Sahne değişti');
      expect(PushPayload.decode(s.payload).eventId, 'e1');
    });

    test('normal / eksik veri -> tiyatrol_default ve varsayılan başlık', () {
      final s = PushMessageMapper.toSpec(const PushIncoming(data: {}));
      expect(s.channelId, 'tiyatrol_default');
      expect(s.title, PushMessageMapper.defaultTitle);
      final a = PushMessageMapper.toSpec(
          const PushIncoming(data: {'kind': 'alarm'}));
      expect(a.title, PushMessageMapper.alarmTitle);
    });

    test('data-only mesajda başlık/gövde data alanından, kimlik kararlı', () {
      final a = PushMessageMapper.toSpec(const PushIncoming(
          messageId: 'same', data: {'title': 'T', 'body': 'B'},
          hasNotificationBlock: false));
      final b = PushMessageMapper.toSpec(
          const PushIncoming(messageId: 'same', title: 'x'));
      expect(a.title, 'T');
      expect(a.body, 'B');
      expect(a.id, b.id);
      expect(a.id, greaterThanOrEqualTo(0));
    });
  });

  group('PushService', () {
    late FakeGateway gw;
    late FakeTokenStore store;
    late FakePrefs prefs;
    late FakeNotifier notifier;
    late List<String> alarms;
    late List<String> banners;
    late PushService svc;

    setUp(() {
      gw = FakeGateway();
      store = FakeTokenStore(gw.calls);
      prefs = FakePrefs();
      notifier = FakeNotifier();
      alarms = [];
      banners = [];
      svc = PushService(
        gateway: gw,
        tokenStore: store,
        prefs: prefs,
        notifier: notifier,
        alarmPresenter: (final m, final p) async => alarms.add(m.title ?? ''),
        bannerPresenter: (final m, final p) async => banners.add(m.title ?? ''),
      );
    });

    test('duyuru topic tercihi: varsayılan açık, kapat/aç abonelik değiştirir',
        () async {
      expect(await svc.announcementsEnabled(), isTrue);
      await svc.setAnnouncementsEnabled(false);
      expect(await svc.announcementsEnabled(), isFalse);
      expect(gw.calls.last, 'unsub:all_users');
      await svc.setAnnouncementsEnabled(true);
      expect(gw.calls.last, 'sub:all_users');
    });

    test('syncAnnouncementTopic kayıtlı tercihe uyar', () async {
      prefs.map[PushService.announcementsPrefKey] = false;
      await svc.syncAnnouncementTopic();
      expect(gw.calls, ['unsub:all_users']);
    });

    test('çıkışta token temizlenir, topicten çıkılır, token silinir (sırayla)',
        () async {
      final failed = await svc.detachFromUser();
      expect(failed, isEmpty);
      expect(gw.calls, ['clearToken', 'unsub:all_users', 'deleteToken']);
    });

    test('çıkışta YALNIZ bu cihazın tokeni çıkarılır (gateway tokeni store a iletilir)',
        () async {
      await svc.detachFromUser();
      expect(store.clearedTokens, ['tok']);
    });

    test('bir temizlik adımı patlasa da diğerleri çalışır', () async {
      store.fail = true;
      gw.failDelete = true;
      final failed = await svc.detachFromUser();
      expect(failed, ['clearToken', 'deleteToken']);
      expect(gw.calls, contains('unsub:all_users'));
    });

    test('sesli hatırlatma tercihi: varsayılan KAPALI, yerel yazılır, sunucuya iletilir',
        () async {
      final remote = FakeLoudRemote();
      final s2 = PushService(
          gateway: gw,
          tokenStore: store,
          prefs: prefs,
          notifier: notifier,
          loudAlarmRemote: remote);
      expect(await s2.loudAlarmEnabled(), isFalse);
      expect(await s2.loudAlarmPreference(), isNull);
      await s2.setLoudAlarmEnabled(true);
      expect(await s2.loudAlarmEnabled(), isTrue);
      expect(remote.writes, [true]);
      remote.fail = true; // sunucu hatası yerel tercihi bozmaz
      await s2.setLoudAlarmEnabled(false);
      expect(await s2.loudAlarmEnabled(), isFalse);
      expect(await s2.loudAlarmPromptSeen(), isFalse);
      await s2.markLoudAlarmPromptSeen();
      expect(await s2.loudAlarmPromptSeen(), isTrue);
    });

    test('ön plan: izin yokken alarm da NORMAL kanalda gösterilir', () async {
      await svc.handleForeground(
          const PushIncoming(title: 'ALARM', data: {'kind': 'alarm'}));
      expect(notifier.shown.single.channelId, 'tiyatrol_default');
      expect(alarms, ['ALARM']); // uygulama içi uyarı sessiz kanaldan bağımsız
    });

    test('ön plan: alarm yerel bildirim + uyarı, normal yalnız şerit',
        () async {
      prefs.map[PushService.loudAlarmPrefKey] = true;
      await svc.handleForeground(const PushIncoming(
          title: 'ALARM', data: {'kind': 'alarm'}));
      expect(notifier.shown.single.channelId, 'tiyatrol_alarm');
      expect(alarms, ['ALARM']);
      expect(banners, isEmpty);

      await svc.handleForeground(
          const PushIncoming(title: 'Merhaba', data: {'kind': 'normal'}));
      expect(notifier.shown, hasLength(1));
      expect(banners, ['Merhaba']);
    });

    test('arka plan: notification bloğu varsa tekrar gösterilmez, yalnız-data '
        'ise gösterilir', () async {
      await svc.handleBackground(const PushIncoming(
          title: 'x', body: 'y', data: {'kind': 'alarm'}));
      expect(notifier.shown, isEmpty);
      await svc.handleBackground(const PushIncoming(
          data: {'kind': 'alarm', 'title': 'Acil', 'body': 'Detay'},
          hasNotificationBlock: false));
      expect(notifier.shown.single.channelId, 'tiyatrol_default'); // izin yok
      notifier.shown.clear();
      prefs.map[PushService.loudAlarmPrefKey] = true;
      await svc.handleBackground(const PushIncoming(
          data: {'kind': 'alarm', 'title': 'Acil', 'body': 'Detay'},
          hasNotificationBlock: false));
      expect(notifier.shown.single.channelId, 'tiyatrol_alarm');
      expect(notifier.shown.single.title, 'Acil');
    });
  });

  group('Bildirim kutusu modeli', () {
    test('yeni türler ve eventId okunur; createdAt yedek alan çalışır', () {
      final e = NotificationModel.fromFirestore({
        '_id': 'n1',
        'userId': 'u',
        'title': 'T',
        'body': 'B',
        'type': 'alarm',
        'eventId': 'ev1',
        'isRead': false,
        'createdAt': '2026-10-26T10:00:00.000',
      }).toEntity();
      expect(e.type, NotificationType.alarm);
      expect(e.eventId, 'ev1');
      expect(e.createdAt, '2026-10-26T10:00:00.000');
      expect(NotificationType.fromString('announcement'),
          NotificationType.announcement);
      expect(NotificationType.fromString('???'), NotificationType.unknown);
    });
  });

  group('FcmTokenList (çoklu cihaz)', () {
    test('ekleme: yinelenmez, yeni token sona gelir', () {
      expect(FcmTokenList.add(['a', 'b'], null, 'c'), ['a', 'b', 'c']);
      expect(FcmTokenList.add(['a', 'b'], null, 'a'), ['b', 'a']);
    });

    test('üst sınır 5: en eski düşer', () {
      expect(FcmTokenList.add(['1', '2', '3', '4', '5'], null, '6'),
          ['2', '3', '4', '5', '6']);
    });

    test('eski tekil alan geçişte listeye alınır; liste yoksa/bozuksa güvenli', () {
      expect(FcmTokenList.add(null, 'old', 'new'), ['old', 'new']);
      expect(FcmTokenList.add(['old'], 'old', 'new'), ['old', 'new']);
      expect(FcmTokenList.add('bozuk', '', 'new'), ['new']);
      expect(FcmTokenList.add([1, null, 'x'], null, 'y'), ['x', 'y']);
    });

    test('çıkarma: yalnız bu cihaz, diğerleri korunur', () {
      expect(FcmTokenList.remove(['a', 'b', 'c'], 'b'), ['a', 'c']);
      expect(FcmTokenList.remove(null, 'b'), isEmpty);
    });
  });
}
