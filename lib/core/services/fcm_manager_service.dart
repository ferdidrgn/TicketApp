import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Manager'ı Singleton olarak dışarı açar
final fcmServiceProvider =
    Provider<FCMManager>((final ref) => FCMManager.instance);

// Başlatma işlemini takip eden provider
final fcmInitializerProvider = FutureProvider<void>(
    (final ref) async => ref.read(fcmServiceProvider).init());

class FCMManager {
  FCMManager._();

  static final FCMManager instance = FCMManager._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Servisi başlat ve izinleri yönet
  Future<void> init() async {
    // 1. İzinleri tazele
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    //Firebase Console'dan tek tek cihaz seçmek yerine "all_users" konusuna mesaj atarak herkese ulaşabiliriz.
    await _fcm.subscribeToTopic("all_users");
    // 2. Token'ı al (Konsola yazdır ki Firebase'den test yapabilesin)
    final String? token = await _fcm.getToken();
    debugPrint("--------------------------------------------------");
    debugPrint("FCM ADRESİN (TOKEN): $token");
    debugPrint("--------------------------------------------------");

    // 3. Dinleyicileri (Kulakları) Aç
    _setupListeners();
  }

  void _setupListeners() {
    // UYGULAMA AÇIKKEN GELEN HER MESAJI YAKALA
    FirebaseMessaging.onMessage.listen((final RemoteMessage message) {
      debugPrint('FCM: Uygulama açıkken bir mesaj yakalandı!');
      debugPrint('Başlık: ${message.notification?.title}');
      debugPrint('İçerik: ${message.notification?.body}');

      // Buraya bir SnackBar ekleyerek kullanıcıya canlı gösterebilirsin
    });

    // BİLDİRİME TIKLAYARAK GİRİLDİĞİNDE YAKALA
    FirebaseMessaging.onMessageOpenedApp.listen((final RemoteMessage message) {
      debugPrint('FCM: Bildirime tıklandı, kullanıcı içeride!');
      // Örn: message.data['type'] == 'chat' ise mesaj sayfasına yönlendir
    });
  }
}

// ARKA PLAN HANDLER (Main dışında, top-level olmalı)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    final RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("FCM: Kapalıyken mesaj geldi: ${message.messageId}");
}
