import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// 🔗 Uygulama deeplink / app link dinleyicisi
/// - App kapalıyken gelen link
/// - App açıkken gelen link
/// - Double init & crash protection
final class DeeplinkListener {
  DeeplinkListener._();

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _subscription;

  static bool _initialized = false;

  /// 🚀 Uygulama başlarken SADECE 1 KEZ çağrılır
  static Future<void> start(final GoRouter router) async {
    if (_initialized) return; // 🛑 ikinci kez başlatma
    _initialized = true;

    if (kIsWeb) return; // 🌐 Web deeplink dinlemez

    // 1️⃣ App TAM KAPALIYKEN gelen deeplink
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) _handleUri(router, initialUri);
    } catch (e) {
      debugPrint('❌ Initial deeplink error: $e');
    }

    // 2️⃣ App AÇIKKEN gelen deeplink
    _subscription = _appLinks.uriLinkStream.listen(
      (final uri) {
        _handleUri(router, uri);
      },
      onError: (final error) {
        debugPrint('❌ Deeplink stream error: $error');
      },
    );
  }

  /// 🧹 Hot restart / dispose için
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _initialized = false;
  }

  /// 🎯 Gerçek yönlendirme
  static void _handleUri(final GoRouter router, final Uri uri) {
    final String path = uri.path;

    debugPrint('🔗 Deeplink received: $path');

    // Aynı sayfadaysak tekrar gitme (crash önler)
    final currentPath = router.routerDelegate.currentConfiguration.fullPath;

    if (currentPath == path) {
      debugPrint('ℹ️ Already on $path, navigation skipped');
      return;
    }

    try {
      router.go(path);
    } catch (e) {
      debugPrint('❌ Invalid deeplink path: $path');
    }
  }
}
