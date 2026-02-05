import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/config/seo/seo_service.dart';
import 'package:ticketapp/shared/navigation/widgets/web_nav_bar.dart';
import '../../../../../shared/navigation/providers/navigation_keys.dart';
import '../../providers/home_asset_video_provider.dart';

/// 🏠 App Home Page (Web Landing Page)
///
/// FEATURES:
/// - SEO meta tags (title, description, Open Graph)
/// - Lazy animation loading (after video loads)
/// - Smooth transitions
class AppHomePage extends ConsumerStatefulWidget {
  final bool startAnimations;

  const AppHomePage({super.key, this.startAnimations = false});

  @override
  ConsumerState<AppHomePage> createState() => _AppHomePageState();
}

class _AppHomePageState extends ConsumerState<AppHomePage> {
  // Başlangıçta animasyonlar KAPALI
  bool _animationsStarted = false;
  bool _seoUpdated = false;

  @override
  void initState() {
    super.initState();

    // SEO meta tag'lerini güncelle (ilk kez)
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      _updateSeo();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Route değiştiğinde SEO'yu yeniden güncelle
    if (!_seoUpdated) _updateSeo();
  }

  /// 🔍 SEO Meta Tag Güncelleme
  void _updateSeo() {
    if (_seoUpdated) return;

    SeoService.set(
      title: 'TiyatRol - Sanat Seni Bekliyor',
      description:
          'Türkiye\'nin en kapsamlı tiyatro, konser ve etkinlik platformu. '
          'Binlerce oyun, etkinlik ve sahne arasından seçiminizi yapın, '
          'biletinizi hemen alın!',
      imageUrl: 'https://www.tiyatrol.web.app/assets/og-image.jpg',
      canonicalUrl: 'https://www.tiyatrol.web.app/',
      keywords: 'tiyatro, konser, etkinlik, bilet, sahne, oyun, sanat, kültür, '
          'istanbul tiyatro, ankara tiyatro, izmir tiyatro',
      author: 'TiyatRol',
      type: SeoType.website,
    );

    _seoUpdated = true;
  }

  @override
  Widget build(final BuildContext context) {
    // 1. Videonun (veya sayfanın) yüklenme durumunu izle
    final videoState = ref.watch(homeAssetsProvider);

    // 2. Logic: Video Hazırsa + Animasyon henüz başlamadıysa
    if (!videoState.isLoading && !videoState.hasError && !_animationsStarted) {
      // Splash'in fade-out (kaybolma) süresi yaklaşık 800ms
      // Animasyonların tam splash bittikten sonra başlaması için
      // 1000ms bekliyoruz
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) setState(() => _animationsStarted = true);
      });
    }

    // 🚀 SENKRONİZE ANİMASYON:
    // WebBar (ve içindeki HomePage), veriler yüklenip Splash
    // kalkana kadar "false" sinyali alacak.
    // Splash kalktığı an "true" sinyali gidecek ve animasyonlar başlayacak.
    return Scaffold(
      body: WebBar(
        key: NavigationKeys.webNavKey,
        startAnimations: _animationsStarted,
      ),
    );
  }
}
