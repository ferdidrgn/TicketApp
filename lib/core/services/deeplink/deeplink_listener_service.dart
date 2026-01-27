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
    final String path = uri.path;
    if (path.isEmpty || path == '/') return;

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
