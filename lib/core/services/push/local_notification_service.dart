import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'push_message_mapper.dart';
import 'push_payload.dart';
import 'push_service.dart';

/// `flutter_local_notifications` sarmalayıcısı: iki Android kanalını
/// (idempotent) oluşturur ve yerel bildirim gösterir. Web'de hiçbir şey yapmaz.
class LocalNotificationService implements LocalNotifier {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  /// Alarm: en yüksek önem, ses + titreşim, ALARM ses akışı.
  /// NOT: "Rahatsız Etme'yi aş" (bypassDnd) bilerek açılmaz — kullanıcı
  /// izni/tercihi gerektirir; kullanıcı Ayarlar'dan kanalı kendisi seçer.
  static final AndroidNotificationChannel alarmChannel =
      AndroidNotificationChannel(
    PushChannels.alarm,
    'Sahne alarmı',
    description: 'Sahneden gelen acil ve önemli duyurular (sesli).',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    vibrationPattern: Int64List.fromList(<int>[0, 600, 300, 600, 300, 900]),
    audioAttributesUsage: AudioAttributesUsage.alarm,
    showBadge: true,
  );

  static const AndroidNotificationChannel defaultChannel =
      AndroidNotificationChannel(
    PushChannels.normal,
    'Duyurular',
    description: 'Yeni oyunlar, kampanyalar ve genel duyurular.',
    importance: Importance.high,
  );

  /// Eklentiyi başlatır ve kanalları oluşturur (tekrar çağrılabilir).
  /// [onTap]: kullanıcı yerel bildirime dokununca payload ile çağrılır.
  Future<void> ensureInitialized({
    final void Function(String? payload)? onTap,
  }) async {
    if (kIsWeb) return;
    if (!_initialized) {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // İzni FCM (requestPermission) ister; burada tekrar sorulmaz.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (final NotificationResponse r) =>
            onTap?.call(r.payload),
      );
      _initialized = true;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(alarmChannel);
      await android?.createNotificationChannel(defaultChannel);
    }
  }

  /// Uygulama bir yerel bildirime dokunularak açıldıysa payload'ı döner.
  Future<String?> launchPayload() async {
    if (kIsWeb) return null;
    final NotificationAppLaunchDetails? d =
        await _plugin.getNotificationAppLaunchDetails();
    if (d != null && d.didNotificationLaunchApp) {
      return d.notificationResponse?.payload;
    }
    return null;
  }

  @override
  Future<void> show(final LocalNotificationSpec spec) async {
    if (kIsWeb) return;
    await ensureInitialized();
    final bool alarm = spec.isAlarm;
    final NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        spec.channelId,
        alarm ? alarmChannel.name : defaultChannel.name,
        channelDescription:
            alarm ? alarmChannel.description : defaultChannel.description,
        importance: alarm ? Importance.max : Importance.high,
        priority: Priority.high,
        category: alarm ? AndroidNotificationCategory.alarm : null,
        audioAttributesUsage:
            alarm ? AudioAttributesUsage.alarm : AudioAttributesUsage.notification,
        styleInformation: BigTextStyleInformation(spec.body),
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        // Apple "Kritik Uyarı" yetkisi YOK; time-sensitive en yükseği.
        interruptionLevel:
            alarm ? InterruptionLevel.timeSensitive : InterruptionLevel.active,
      ),
    );
    await _plugin.show(
      id: spec.id,
      title: spec.title,
      body: spec.body,
      notificationDetails: details,
      payload: spec.payload,
    );
  }
}
