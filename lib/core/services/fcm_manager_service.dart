import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final fcmServiceProvider = Provider<FCMManager>((final ref) => FCMManager.instance);

/// 🔔 Push bildirim yöneticisi.
///
/// - Uygulama açıkken gelen mesajları `flutter_local_notifications` ile
///   gerçek bir sistem bildirimi olarak gösterir (Android'de FCM foreground
///   mesajları kendiliğinden görünmez, bu yüzden bu adım zorunlu).
/// - Bildirime tıklanınca (uygulama arka planda/kapalıyken de dahil)
///   mesajın `route` verisine göre GoRouter ile ilgili sayfaya yönlendirir —
///   `TiyatrolDeeplinkListener` ile birebir aynı desen.
/// - Kullanıcının FCM token'ını `User.fcmToken` alanına yazar ki Cloud
///   Functions tarafı (bkz. functions/index.js) kişiye özel bildirim
///   (ör. "biletin hazır") gönderebilsin.
class FCMManager {
  FCMManager._();

  static final FCMManager instance = FCMManager._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'Önemli Bildirimler',
    description: 'Kampanya, yeni oyun ve bilet bildirimleri',
    importance: Importance.high,
  );

  GoRouter? _router;
  bool _isInitialized = false;

  /// Servisi başlatır. `router`, bildirime tıklanınca doğru sayfaya
  /// yönlendirebilmek için saklanır (web'de hiçbir şey yapılmaz).
  Future<void> init(final GoRouter router) async {
    _router = router;
    if (kIsWeb || _isInitialized) return;
    _isInitialized = true;

    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    await _initLocalNotifications();

    // Firebase Console'dan tek tek cihaz seçmek yerine "all_users" konusuna
    // mesaj atarak herkese (ücretsiz, cihaz sayısı sınırı olmadan) ulaşabiliriz.
    await _fcm.subscribeToTopic('all_users');

    // Kullanıcı giriş yaptığında/değiştiğinde token'ı profile yaz.
    FirebaseAuth.instance.authStateChanges().listen((final user) {
      if (user != null) _syncTokenWithProfile();
    });
    _fcm.onTokenRefresh.listen((final _) => _syncTokenWithProfile());

    _setupListeners();

    // Uygulama bildirime tıklanarak TAMAMEN KAPALIYKEN açıldıysa.
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) _handleNavigation(initialMessage.data);
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (final response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = (jsonDecode(payload) as Map<String, dynamic>)
              .map((final k, final v) => MapEntry(k, v.toString()));
          _handleNavigation(data);
        } catch (e) {
          debugPrint('FCM payload parse hatası: $e');
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  Future<void> _syncTokenWithProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final token = await _fcm.getToken();
      if (token == null || token.isEmpty) return;

      // `set(merge:true)`: kullanıcı dökümanı henüz oluşturulmamış olsa
      // bile (ör. ilk girişte profil henüz kaydedilmeden) hata vermez.
      await FirebaseFirestore.instance
          .collection('User')
          .doc(uid)
          .set({'fcmToken': token}, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FCM token senkronizasyonu başarısız: $e');
    }
  }

  void _setupListeners() {
    // UYGULAMA AÇIKKEN GELEN HER MESAJI YAKALA — sistem bunu otomatik
    // göstermediği için elle bir bildirim oluşturuyoruz.
    FirebaseMessaging.onMessage.listen((final message) {
      final notification = message.notification;
      if (notification == null) return;

      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    });

    // BİLDİRİME TIKLAYARAK UYGULAMA ARKA PLANDAYKEN GİRİLDİĞİNDE YAKALA
    FirebaseMessaging.onMessageOpenedApp
        .listen((final message) => _handleNavigation(message.data));
  }

  void _handleNavigation(final Map<String, dynamic> data) {
    final route = data['route'] as String?;
    if (route == null || route.isEmpty) return;
    try {
      _router?.go(route);
    } catch (e) {
      debugPrint('❌ Bildirim yönlendirme hatası: $e');
    }
  }
}

// ARKA PLAN HANDLER (main() içinde, uygulama tamamen kapalıyken/arka
// plandayken gelen mesajlar için — Main dışında, top-level olmalı)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    final RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("FCM: Kapalıyken mesaj geldi: ${message.messageId}");
}
