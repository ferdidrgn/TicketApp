import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/theme_context_extension.dart';
import '../../../../shared/widgets/custom_dots_indicator.dart';
import '../../../../shared/widgets/shimmer.dart';
import '../../../campaigns/domain/entities/campaign.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../players/presentation/pages/player_details.dart';
import '../../../shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../stages/presentation/pages/stage_details.dart';

class CampaignShowcasePage extends ConsumerStatefulWidget {
  // ✅ YENİ: Başlangıç sırasını parametre olarak alıyoruz
  final int initialIndex;

  const CampaignShowcasePage(
      {super.key, this.initialIndex = 0 // Varsayılan olarak 0 (ilk eleman)
      });

  @override
  ConsumerState<CampaignShowcasePage> createState() =>
      _CampaignShowcasePageState();
}

class _CampaignShowcasePageState extends ConsumerState<CampaignShowcasePage> {
  late PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    // ✅ YENİ: Gelen index'i başlangıç olarak ayarla
    _currentPage = widget.initialIndex;

    // ✅ YENİ: PageController'ı initialPage ile başlat
    _pageController = PageController(
        viewportFraction: 0.85, initialPage: widget.initialIndex);

    // Verileri tazelemek istersen (Genelde gerekmez çünkü provider cache'ler ama garanti olsun)
    WidgetsBinding.instance.addPostFrameCallback((final _) {
      // Eğer liste boşsa veya güncellenmesi gerekiyorsa:
      ref.read(campaignProvider.notifier).loadCampaigns();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToPage(final Widget page) {
    if (page is SizedBox) return;
    Navigator.push(context, MaterialPageRoute(builder: (final _) => page));
  }

  Widget _resolveDetailPage(final String url) {
    try {
      final id = url.split('/').last;
      if (url.contains('/shows')) return PlayerDetailPage(playerId: id);
      if (url.contains('/show')) return ShowDetailPage(showId: id);
      if (url.contains('/stages')) return StageDetailPage(stageId: id);
      return const SizedBox();
    } catch (e) {
      return const SizedBox();
    }
  }

  @override
  Widget build(final BuildContext context) {
    final state = ref.watch(campaignProvider);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Arka Plan Ambiyansı
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.primaryColor.withOpacity(0.15)),
            ),
          ),

          if (state.isLoading)
            const Center(child: ShimmerLoading(height: 500, width: 350))
          else if (state.hasData && state.dataList!.isNotEmpty)
            _buildContent(state.dataList!)
          else
            const Center(child: Text("Kampanya bulunamadı")),
        ],
      ),
    );
  }

  Widget _buildContent(final List<Campaign> campaigns) {
    // İndex hatası olmaması için kontrol (Liste değişmiş olabilir)
    if (_currentPage >= campaigns.length) _currentPage = 0;

    final Campaign currentCampaign = campaigns[_currentPage];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 100, bottom: 50),
      child: Column(
        children: [
          // Slider
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: PageView.builder(
              controller: _pageController,
              itemCount: campaigns.length,
              onPageChanged: (final index) =>
                  setState(() => _currentPage = index),
              itemBuilder: (final context, final index) {
                final campaign = campaigns[index];
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (final context, final child) {
                    double value = 1.0;
                    if (_pageController.position.haveDimensions) {
                      value = _pageController.page! - index;
                      value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                    }
                    return Transform.scale(
                        scale: value,
                        child: Opacity(opacity: value, child: child));
                  },
                  child: _buildCampaignCard(campaign),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
                color: context.isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20)),
            child: DotsIndicator(
              itemCount: campaigns.length,
              currentIndex: _currentPage,
              onPageSelected: (final page) {
                _pageController.animateToPage(page,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut);
              },
            ),
          ),

          const SizedBox(height: 40),

          // Dinamik Detay Alanı
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Column(
                key: ValueKey<int>(_currentPage),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(currentCampaign.title,
                      style: context.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w900, height: 1.2)),
                  const SizedBox(height: 16),
                  Text(
                    // Eğer API'de açıklama yoksa başlığı tekrarla veya sabit metin koy
                    currentCampaign.url ??
                        "Bu etkinlik için özel fırsatlar seni bekliyor. Detaylar için butona tıkla.",
                    style: context.textTheme.bodyLarge
                        ?.copyWith(color: Colors.grey, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => _navigateToPage(
                              _resolveDetailPage(currentCampaign.url)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 10,
                            shadowColor: context.primaryColor.withOpacity(0.4),
                          ),
                          child: const Text("Fırsatı Yakala",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(
                                  color: Colors.grey.withOpacity(0.3)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16))),
                          child: const Icon(Icons.share_outlined),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignCard(final Campaign campaign) {
    return GestureDetector(
      // Karta tıklayınca da detay sayfasına gitsin (Opsiyonel)
      onTap: () => _navigateToPage(_resolveDetailPage(campaign.url)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
                color: context.primaryColor.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                  imageUrl: campaign.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (final _, final __, final ___) =>
                      Container(color: Colors.grey[900])),
              Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.9)
                  ],
                          stops: const [
                    0.5,
                    1.0
                  ]))),
              Positioned(
                bottom: 40,
                left: 25,
                right: 25,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: context.primaryColor,
                            borderRadius: BorderRadius.circular(12)),
                        child: Text('ÖZEL',
                            style: context.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5))),
                    const SizedBox(height: 12),
                    Text(campaign.title,
                        style: context.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                  color: Colors.black.withOpacity(0.8),
                                  blurRadius: 10)
                            ]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
