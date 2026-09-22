import 'package:flutter/material.dart';

/// Uygulama genelinde kullanılan tek hareket (motion) ölçeği: süre + eğri.
///
/// Mevcut kodda `Duration(milliseconds: ...)` için düzinelerce farklı ham
/// değer vardı ama gerçek dağılım zaten üç doğal kümeye ayrılıyordu (hızlı
/// geri bildirim ~180-220ms, normal geçiş ~300-500ms, dramatik/sahne
/// anları ~650-800ms — bkz. `page_transitions.dart`, hover/press
/// durumları, `curtainTransition`/`focalTransition`). Bu sınıf o üç
/// kümeyi isimlendiriyor; yeni bir hız dili icat etmiyor.
class AppMotion {
  AppMotion._();

  /// Hover/press gibi anlık geri bildirim (feedback) için.
  static const Duration fast = Duration(milliseconds: 200);

  /// Kart açılışı, bölüm geçişi gibi standart hareketler için — sayfa
  /// geçişlerinin de varsayılan süresi (`app_router.dart`) bu.
  static const Duration normal = Duration(milliseconds: 500);

  /// Perde açılışı, spot ışığı gibi tek seferlik, "özel an" hareketleri
  /// için — sık tekrarlanan bir yerde kullanılırsa etkisini kaybeder.
  static const Duration slow = Duration(milliseconds: 700);

  /// Genel amaçlı, en sık kullanılan eğri — hızlanarak başlayıp yavaşça
  /// yerine oturur.
  static const Curve standard = Curves.easeOutCubic;

  /// Simetrik geçişler (fade in/out) için.
  static const Curve symmetric = Curves.easeInOut;

  /// Dramatik, "sahne anı" hareketleri için (bkz. `curtainTransition`).
  static const Curve dramatic = Curves.easeInOutQuart;
}
