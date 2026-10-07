import 'package:flutter/material.dart';

/// Uygulama genelinde kullanılan tek derinlik (elevation) ölçeği.
///
/// Renk sistemine karışmaz — her çağıran kendi markasının tonunu
/// (`WebColors.veryDarkBlue`, `context.colors.shadow`, vb.) `tint` olarak
/// geçer; burada sadece blur/offset/opaklık YAPISI merkezileşiyor (mevcut
/// kodda `blurRadius: 20`/`10`/`24`/`8` gibi değerler onlarca yerde ayrı
/// ayrı elle yazılmıştı — bkz. rapor madde 2).
///
/// Aynı anda çok fazla gölge katmanı kullanmayın: bir öğe genelde tek bir
/// seviyeye ait olmalı (ör. sıradan bir kart `level2`, öne çıkan/hover
/// durumundaki bir kart `level3`).
class AppShadows {
  AppShadows._();

  /// Düz — hiç gölge yok.
  static const List<BoxShadow> level0 = [];

  /// Hafif yükseklik — bir listedeki sıradan, dinlenme hâlindeki bir öğe.
  static List<BoxShadow> level1(final Color tint) => [
        BoxShadow(
            color: tint.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4)),
      ];

  /// Kart — varsayılan kart/panel gölgesi.
  static List<BoxShadow> level2(final Color tint) => [
        BoxShadow(
            color: tint.withOpacity(0.20),
            blurRadius: 16,
            offset: const Offset(0, 8)),
      ];

  /// Öne çıkan içerik — hover/vurgulanmış kart, öne çıkan panel.
  static List<BoxShadow> level3(final Color tint) => [
        BoxShadow(
            color: tint.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10)),
      ];

  /// Modal / overlay — bottom sheet, dialog, açılır panel.
  static List<BoxShadow> level4(final Color tint) => [
        BoxShadow(
            color: tint.withOpacity(0.32),
            blurRadius: 30,
            offset: const Offset(0, 14)),
      ];

  /// Hero / yüzen CTA — sayfanın en dramatik, tek seferlik öğesi
  /// (ör. bir ana buton, bir hero panel). Sık kullanılırsa etkisini
  /// yitirir.
  static List<BoxShadow> level5(final Color tint) => [
        BoxShadow(
            color: tint.withOpacity(0.36),
            blurRadius: 40,
            offset: const Offset(0, 20)),
      ];
}
