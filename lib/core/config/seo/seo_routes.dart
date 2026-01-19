import 'package:flutter/widgets.dart';
import '../../common/extentions/app_context_ui_extension.dart';
import 'seo_service.dart';

final class SeoRoutes {
  const SeoRoutes._();

  static void update(final BuildContext context, final String location) {
    final l10n = context.l10n;

    // --- Dinamik Oyun Detay SEO ---
    // Örnek: /show/oyun-id
    if (location.startsWith('/show/')) {
      // Detay sayfasında özel başlık takısı eklenir
      SeoService.set(
        title: l10n.seoPlayDetailSuffix,
        description: l10n.seoPlaysDesc,
      );
      return;
    }

    // --- Statik Sayfa SEO Yönetimi ---
    switch (location) {
      case '/':
        SeoService.set(
          title: l10n.seoHomeTitle,
          description: l10n.seoHomeDesc,
        );
        break;
      case '/plays': // /discover yerine oyunlar
        SeoService.set(
          title: l10n.seoPlaysTitle,
          description: l10n.seoPlaysDesc,
        );
        break;
      case '/discover': // Yeni oyunların ve prömiyerlerin olduğu sayfa
        SeoService.set(
            title: l10n.seoDiscoverTitle, description: l10n.seoDiscoverDesc);
        break;
      case '/nearby': // Yakındaki sahnelerin veya turne duraklarının olduğu sayfa
        SeoService.set(
            title: l10n.seoNearbyTitle, description: l10n.seoNearbyDesc);
        break;
      case '/team': // /nearby yerine ekip
        SeoService.set(
          title: l10n.seoTeamTitle,
          description: l10n.seoTeamDesc,
        );
        break;
      case '/about': // /profile yerine hakkımızda
        SeoService.set(
          title: l10n.seoAboutTitle,
          description: l10n.seoAboutDesc,
        );
        break;
      default:
        SeoService.set(
          title: l10n.brand,
          description: l10n.seoHomeDesc,
        );
    }
  }
}
