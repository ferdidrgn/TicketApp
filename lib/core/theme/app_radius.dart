import 'package:flutter/material.dart';

/// Uygulama genelinde kullanılan tek köşe yuvarlaklığı (radius) ölçeği.
///
/// **Asimetrik köşe** (`asymSm`/`asymLg`: iki köşe hafifçe, iki köşe
/// belirgince yuvarlak) uygulamanın bilinçli bir tasarım imzası —
/// `home_page_web.dart`, `home_campaign_rail.dart`, `home_promo_banner.dart`,
/// `show_detail_page_web.dart`, `player_section.dart`, `search_header_web.dart`,
/// `search_result_cards_web.dart`, `home_show_grid.dart`, `discovery_featured_show.dart`
/// dahil en az 10 dosyada BİREBİR AYNI `BorderRadius.only(...)` bloğu elle
/// kopyalanmış. Değerler buradan (o mevcut, tutarlı kullanımdan) alındı —
/// yeni bir köşe dili icat edilmedi. Yeni kod bu sabitleri kullanmalı.
class AppRadius {
  AppRadius._();

  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  /// Sohbet balonu / rozet gibi tam yuvarlak (pill) şekiller için.
  static const double pill = 100;

  /// "Sahne Köşesi" — uygulamanın asimetrik köşe imzası, küçük ölçek
  /// (rozet, buton, küçük kart). Sol-üst ve sol-alt keskin, sağ-üst ve
  /// sağ-alt belirgin yuvarlak — bir sahne perdesinin kıvrımını andırır.
  static const BorderRadius asymSm = BorderRadius.only(
    topLeft: Radius.circular(2),
    topRight: Radius.circular(12),
    bottomLeft: Radius.circular(2),
    bottomRight: Radius.circular(12),
  );

  /// "Sahne Köşesi" — büyük ölçek (kampanya kartı, banner, hero panel).
  static const BorderRadius asymLg = BorderRadius.only(
    topLeft: Radius.circular(6),
    topRight: Radius.circular(32),
    bottomLeft: Radius.circular(6),
    bottomRight: Radius.circular(32),
  );
}
