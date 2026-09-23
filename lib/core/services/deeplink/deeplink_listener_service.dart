import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// 🔗 TiyatRol Deeplink / App Link Dinleyicisi
final class TiyatrolDeeplinkListener {
  TiyatrolDeeplinkListener._();

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _subscription;
  static bool _isInitialized = false;

  /// 🚀 Uygulama başlatıldığında GoRouter ile entegre edilir.
  static Future<void> init(final GoRouter router) async {
    if (_isInitialized) return;
    _isInitialized = true;

    if (kIsWeb) return;

    // 1️⃣ Uygulama TAM KAPALIYKEN gelen linki yakala
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handleNavigation(router, initialUri);
    } catch (e) {
      debugPrint('❌ Deeplink Initial Error: $e');
    }

    // 2️⃣ Uygulama AÇIKKEN gelen linkleri dinle
    _subscription = _appLinks.uriLinkStream.listen(
      (final uri) => _handleNavigation(router, uri),
      onError: (final err) => debugPrint('❌ Deeplink Stream Error: $err'),
    );
  }

  /// 🎯 Navigasyon ve URL Senkronizasyonu
  static void _handleNavigation(final GoRouter router, final Uri uri) {
    var path = uri.path;
    if (path.isEmpty || path == '/') return;

    // 🔑 KRİTİK: Gelen App Link/Universal Link URL'i her zaman gerçek web
    // yapısını yansıtır (https://tiyatrol.web.app/app/show/...), çünkü
    // AndroidManifest'teki pathPrefix ve iOS'taki AASA "paths" bilinçli
    // olarak "/app" altını hedefliyor (bkz. android/app/src/main/
    // AndroidManifest.xml, landing/.well-known/apple-app-site-association).
    // Ancak native (mobil) tarafta GoRouter'ın route tablosu bu "/app"
    // önekini TANIMIYOR — yalnızca ana sayfa route'u zaten literal olarak
    // '/app' (bkz. app_router.dart), alt route'lar ise '/show/:id' gibi
    // önek OLMADAN tanımlı. Bu yüzden burada önek soyuluyor; aksi halde
    // her gelen deep link "sayfa bulunamadı"na düşer.
    if (path.startsWith('/app/')) {
      path = path.substring(4); // '/app/show/x' -> '/show/x'
    }
    if (path.isEmpty) return;

    debugPrint('🔗 Deeplink yakalandı: $path');

    final currentPath = router.routerDelegate.currentConfiguration.fullPath;
    if (currentPath == path) return;

    try {
      router.go(path); // URL senkronizasyonu için 'go' kullanıyoruz
    } catch (e) {
      debugPrint('❌ Invalid deeplink path: $path');
    }
  }

  /// 🧹 Bellek Temizliği (Dispose)
  static void stop() {
    _subscription?.cancel();
    _subscription = null;
    _isInitialized = false;
  }
}
