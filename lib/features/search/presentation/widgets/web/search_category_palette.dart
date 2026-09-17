import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';

/// =============================================================================
/// ARAMA KATEGORİ PALETİ — "Çam & Mercan" marka kimliğinden türetilmiş
/// =============================================================================
///
/// Arama sayfasındaki 5 filtre kategorisini ("Tümü", "Etkinlikler",
/// "Oyuncular", "Mekanlar", "Ekipler") birbirinden ayırt edilebilir ama
/// markaya tamamen ait tonlarla renklendirir.
///
/// Önceki sürüm rastgele, markayla hiçbir ilgisi olmayan Tailwind renkleri
/// kullanıyordu (Indigo/Amber/Pink/Emerald/Blue). Burada onun yerine
/// SADECE [WebColors]'daki gerçek marka sabitleri — mercan (coral),
/// adaçayı (sage) ve koyu çam (pine) tonları — ve bunların [Color.lerp]
/// ile karıştırılmış türevleri kullanılır. Hiçbir yeni/ham hex değeri
/// eklenmez.
///
/// Bu tek kaynak; hem mobildeki [ArtisticBrushChip] filtre çubuğunu / arka
/// plan "ambient" rengini, hem de masaüstündeki filtre sekmelerini, bölüm
/// ikonlarını ve sonuç kartı rozetlerini besler — böylece "Mekanlar" her
/// yerde aynı tonu taşır, "Ekipler" her yerde aynı başka tonu taşır vs.
class SearchCategoryPalette {
  const SearchCategoryPalette._();

  // Filtre index'leri (search_query_provider.dart'taki sıralamayla birebir)
  static const int all = 0;
  static const int events = 1;
  static const int players = 2;
  static const int stages = 3;
  static const int teams = 4;

  /// Her kategori için [açık, koyu] gradyan çifti.
  static final List<List<Color>> tints = [
    // 0. Tümü — amiral mercan gradyanı (ana marka vurgusu)
    [WebColors.primaryGold, WebColors.primaryGoldDark],

    // 1. Etkinlikler — açık, sıcak mercan (Tümü'nden daha aydınlık)
    [WebColors.primaryGoldLight, WebColors.primaryGold],

    // 2. Oyuncular — canlı adaçayı yeşili (mercandan tamamen farklı bir
    // renk ailesi, kolayca ayırt edilir)
    [WebColors.secondaryAccentLight, WebColors.secondaryAccent],

    // 3. Mekanlar — adaçayı + koyu çam kulis karışımı: daha "mimari" ve
    // loş bir yeşil, Oyuncular'ın canlı adaçayısından belirgin şekilde
    // koyu/soğuk
    [
      WebColors.secondaryAccent,
      Color.lerp(
          WebColors.secondaryAccent, WebColors.darkBlueAccent, 0.55)!,
    ],

    // 4. Ekipler — mercan + adaçayı karışımı: markanın iki ana rengini
    // birleştiren, ılık-nötr üçüncül bir ton
    [
      Color.lerp(
          WebColors.primaryGoldLight, WebColors.secondaryAccentLight, 0.5)!,
      Color.lerp(WebColors.primaryGold, WebColors.secondaryAccent, 0.5)!,
    ],
  ];

  /// [index] için güvenli erişim (aralık dışı gelirse "Tümü" tonuna düşer).
  static List<Color> tintFor(final int index) =>
      (index >= 0 && index < tints.length) ? tints[index] : tints[all];
}
