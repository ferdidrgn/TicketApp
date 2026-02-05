import 'package:flutter/widgets.dart';
import '../../common/extentions/app_context_ui_extension.dart';
import 'seo_service.dart';

/// 🗺️ SEO Route Mapper
/// Her route için uygun SEO meta tag'lerini ayarlar
final class SeoRoutes {
  const SeoRoutes._();

  /// Route'a göre SEO güncelle
  static void update(final BuildContext context, final String location) {
    final l10n = context.l10n;

    // Debug log
    debugPrint('🔍 SEO updating for: $location');

    // ═══════════════════════════════════════════════════════════════
    // DİNAMİK DETAY SAYFALARI (Parametreli)
    // ═══════════════════════════════════════════════════════════════

    // 🎭 Show Detail: /show/hamlet-123
    if (location.startsWith('/show/')) {
      SeoService.set(
        title: '${l10n.brand} - ${l10n.seoPlayDetailSuffix}',
        description: l10n.seoPlaysDesc,
        type: SeoType.article,
      );
      return;
    }

    // 👤 Player Detail: /player/john-doe-456
    if (location.startsWith('/player/')) {
      SeoService.set(
        title: '${l10n.brand} - Oyuncu Detayı',
        description: 'Yetenekli sanatçılarımız ve performansları',
        type: SeoType.profile,
      );
      return;
    }

    // 🏟️ Stage Detail: /stage/sehir-tiyatrosu-789
    if (location.startsWith('/stage/')) {
      SeoService.set(
        title: '${l10n.brand} - Sahne Detayı',
        description: 'Sahneler, salonlar ve etkinlik mekanları',
        type: SeoType.website,
      );
      return;
    }

    // 👥 Team Detail: /team/istanbul-devlet-tiyatrosu-321
    if (location.startsWith('/team/')) {
      SeoService.set(
        title: l10n.seoTeamTitle,
        description: l10n.seoTeamDesc,
        type: SeoType.website,
      );
      return;
    }

    // 🎟️ Ticket Detail: /my-tickets/abc123
    if (location.startsWith('/my-tickets/')) {
      SeoService.set(
        title: '${l10n.brand} - Biletlerim',
        description: 'Bilet detayları ve QR kod',
        type: SeoType.website,
      );
      return;
    }

    // ═══════════════════════════════════════════════════════════════
    // STATİK SAYFALAR
    // ═══════════════════════════════════════════════════════════════

    switch (location) {
      // 🏠 Ana Sayfa (Web Landing)
      case '/':
        SeoService.set(
          title: l10n.seoHomeTitle,
          description: l10n.seoHomeDesc,
          keywords: 'tiyatro, bilet, etkinlik, sahne, oyun, sanat',
          type: SeoType.website,
        );
        break;

      // 📱 App Ana Sayfa
      case '/app':
        SeoService.set(
          title: '${l10n.brand} - Ana Sayfa',
          description: l10n.seoHomeDesc,
          type: SeoType.website,
        );
        break;

      // 🔍 Keşfet
      case '/discover':
        SeoService.set(
          title: l10n.seoDiscoverTitle,
          description: l10n.seoDiscoverDesc,
          keywords: 'yeni oyunlar, premiyer, etkinlikler',
          type: SeoType.website,
        );
        break;

      // 📍 Yakındakiler
      case '/nearby':
        SeoService.set(
          title: l10n.seoNearbyTitle,
          description: l10n.seoNearbyDesc,
          keywords: 'yakındaki etkinlikler, çevremdeki sahneler',
          type: SeoType.website,
        );
        break;

      // 👤 Profil
      case '/profile':
        SeoService.set(
          title: '${l10n.brand} - Profil',
          description: 'Kullanıcı profili, biletler ve ayarlar',
          type: SeoType.website,
        );
        break;

      // 🔎 Arama
      case '/search':
        SeoService.set(
          title: '${l10n.brand} - Arama',
          description: 'Oyunlar, sanatçılar ve sahnelerde arama yapın',
          type: SeoType.website,
        );
        break;

      // ⚙️ Ayarlar
      case '/settings':
        SeoService.set(
          title: '${l10n.brand} - Ayarlar',
          description: 'Uygulama ayarları ve tercihler',
          type: SeoType.website,
        );
        break;

      // ❤️ Favoriler
      case '/favorites':
        SeoService.set(
          title: '${l10n.brand} - Favorilerim',
          description: 'Favori oyunlar, sanatçılar ve sahneler',
          type: SeoType.website,
        );
        break;

      // 🎯 Kampanyalar
      case '/campaign-details':
        SeoService.set(
          title: '${l10n.brand} - Kampanyalar',
          description: 'Özel indirimler ve kampanyalar',
          type: SeoType.website,
        );
        break;

      // 📄 Sözleşmeler
      case '/contracts':
        SeoService.set(
          title: '${l10n.brand} - Kullanıcı Sözleşmesi',
          description: 'Kullanım koşulları ve gizlilik politikası',
          type: SeoType.website,
        );
        break;

      // 🆘 Yardım
      case '/help-support':
        SeoService.set(
          title: '${l10n.brand} - Yardım & Destek',
          description: 'Sıkça sorulan sorular ve destek',
          type: SeoType.website,
        );
        break;

      // 🚪 Login
      case '/login':
      case '/phone-login':
        SeoService.set(
          title: '${l10n.brand} - Giriş Yap',
          description: 'TiyatRol hesabınıza giriş yapın',
          type: SeoType.website,
        );
        break;

      // 🎓 Onboarding
      case '/onboarding':
        SeoService.set(
          title: '${l10n.brand} - Hoş Geldiniz',
          description: 'TiyatRol\'e hoş geldiniz',
          type: SeoType.website,
        );
        break;

      // 🎫 Koltuk Seçimi
      case final String s when s.startsWith('/seat-selection/'):
        SeoService.set(
          title: '${l10n.brand} - Koltuk Seçimi',
          description: 'Koltuğunuzu seçin ve biletinizi alın',
          type: SeoType.website,
        );
        break;

      // ❓ 404 veya Varsayılan
      default:
        SeoService.set(
          title: l10n.brand,
          description: l10n.seoHomeDesc,
          type: SeoType.website,
        );
    }
  }

  /// Query parametrelerini parse et (örn: /discover?category=music)
  static Map<String, String> _parseQuery(final String location) {
    final uri = Uri.tryParse(location);
    return uri?.queryParameters ?? {};
  }
}
