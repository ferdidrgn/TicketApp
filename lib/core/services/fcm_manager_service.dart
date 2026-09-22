import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/navigation/providers/navigation_keys.dart';
import '../../shared/navigation/widgets/nav_handler.dart';

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

    // 🔥 GERÇEK TOKEN KALICILIĞI:
    // Uygulama açılışında zaten oturum açmış bir kullanıcı varsa (ör. uygulama
    // yeniden başlatıldı), bu cihazın güncel token'ını hemen kullanıcı
    // dökümanına yaz. Giriş SIRASINDA yapılan asıl kayıt
    // auth_mutation_provider.dart -> _handlePostLogin içinde yapılıyor; bu,
    // "uygulama zaten açıkken oturum devam ediyor" senaryosunu kapsıyor.
    await _persistTokenForCurrentUser(token);

    // Token yenilendiğinde (yeniden kurulum, cache temizliği, Firebase
    // rotasyonu vb.) kullanıcı dökümanını güncel tut.
    _fcm.onTokenRefresh.listen(_persistTokenForCurrentUser);

    // 3. Dinleyicileri (Kulakları) Aç
    _setupListeners();
  }

  /// Şu an giriş yapmış (anonim OLMAYAN) kullanıcının Firestore
  /// dökümanına FCM token'ını yazar.
  ///
  /// NOT (MİMARİ TERCİH): FCMManager bir core servisi — Users feature'ının
  /// tüm repository/usecase zincirini buraya import etmek yerine (döngüsel
  /// bağımlılık riski + core'un feature'lara bağımlı olmaması ilkesi),
  /// diğer datasource'larla AYNI SEVİYEDE doğrudan Firestore'a yazıyoruz
  /// (bkz. user_remote_data_source_and_impl.dart -> collection('User')).
  Future<void> _persistTokenForCurrentUser(final String? token) async {
    if (token == null || token.isEmpty) return;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null || firebaseUser.isAnonymous) return;

    try {
      await FirebaseFirestore.instance
          .collection('User')
          .doc(firebaseUser.uid)
          .update({'fcmToken': token});
    } catch (e) {
      // Kullanıcı dökümanı henüz oluşturulmadıysa (ör. kayıt akışı sürüyor)
      // update() başarısız olabilir — kritik değil, login akışı token'ı
      // zaten ayrıca kaydediyor (bkz. auth_mutation_provider.dart).
      debugPrint("FCM token Firestore'a yazılamadı: $e");
    }
  }

  void _setupListeners() {
    // UYGULAMA AÇIKKEN GELEN HER MESAJI YAKALA
    FirebaseMessaging.onMessage.listen((final RemoteMessage message) {
      debugPrint('FCM: Uygulama açıkken bir mesaj yakalandı!');
      debugPrint('Başlık: ${message.notification?.title}');
      debugPrint('İçerik: ${message.notification?.body}');

      // ✅ Kullanıcıya GERÇEK, canlı bir geri bildirim: SnackBar.
      _showForegroundBanner(message);
    });

    // BİLDİRİME TIKLAYARAK GİRİLDİĞİNDE YAKALA
    FirebaseMessaging.onMessageOpenedApp.listen((final RemoteMessage message) {
      debugPrint('FCM: Bildirime tıklandı, kullanıcı içeride!');
      _handleNotificationTap(message);
    });
  }

  /// Uygulama ön plandayken gelen push mesajını gerçek bir SnackBar ile
  /// gösterir (mock DEĞİL — NavigationKeys.rootNavigator üzerinden gerçek
  /// BuildContext'e erişip ScaffoldMessenger'ı tetikliyor).
  void _showForegroundBanner(final RemoteMessage message) {
    final context = NavigationKeys.rootNavigator.currentContext;
    if (context == null || !context.mounted) return;

    final title = message.notification?.title ?? 'Yeni Bildirim';
    final body = message.notification?.body ?? '';

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
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              if (body.isNotEmpty) Text(body),
            ],
          ),
          action: SnackBarAction(
            label: 'Görüntüle',
            onPressed: () => _handleNotificationTap(message),
          ),
        ),
      );
  }

  /// Bildirime tıklanınca (ön planda banner'dan veya arka plandan açılınca)
  /// gerçek bir yönlendirme yapar.
  void _handleNotificationTap(final RemoteMessage message) {
    // İleride push payload'ına showId/ticketId gibi veriler eklenirse
    // (bkz. message.data), doğrudan ilgili detay sayfasına
    // yönlendirilebilir. Şimdilik bildirim gelen kutusuna götürüyoruz —
    // orada zaten ilgili bilet/etkinlik bilgisi gösteriliyor.
    NavigationHandler.globalGoTo('/notifications');
  }
}

// ARKA PLAN HANDLER (Main dışında, top-level olmalı)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    final RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("FCM: Kapalıyken mesaj geldi: ${message.messageId}");
}
