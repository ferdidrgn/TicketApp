import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Manager'ı Singleton olarak dışarı açar
final fcmServiceProvider = Provider<FCMManager>((final ref) {
  return FCMManager.instance;
});

// Başlatma işlemini takip eden provider
final fcmInitializerProvider = FutureProvider<void>((final ref) async {
  await ref.read(fcmServiceProvider).init();
});

class FCMManager {
  FCMManager._();

  static final FCMManager instance = FCMManager._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Servisi başlat ve izinleri yönet
  Future<void> init() async {
    // 1. İzin İste
    final NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('FCM: Yetki verildi.');
      _setupListeners();
    }

    // 2. Cihaz Token'ını al (Backend için lazım olur)
    final String? token = await _fcm.getToken();
    debugPrint("FCM Cihaz Token: $token");
  }

  void _setupListeners() {
    // UYGULAMA AÇIKKEN (Foreground)
    FirebaseMessaging.onMessage.listen((final RemoteMessage message) {
      _handleMessage(message, "Ön Plan");
    });

    // ARKA PLANDA TIKLANDIĞINDA (Background Click)
    FirebaseMessaging.onMessageOpenedApp.listen((final RemoteMessage message) {
      _handleMessage(message, "Arka Plan Tıklama");
    });
  }

  void _handleMessage(final RemoteMessage message, final String context) {
    debugPrint(
        "FCM ($context): ${message.notification?.title} - ${message.notification?.body}");
    // Buraya bildirim geldiğinde yapılacak global işlemler gelebilir
  }
}

// ARKA PLAN HANDLER (Main dışında, top-level olmalı)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    final RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("FCM: Kapalıyken mesaj geldi: ${message.messageId}");
}
