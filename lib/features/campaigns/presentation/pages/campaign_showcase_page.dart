import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/custom_dots_indicator.dart';
import '../../../campaigns/domain/entities/campaign.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../players/presentation/pages/player_details.dart';
import '../../../shows/presentation/pages/show_detail_page_mobil.dart';
import '../../../stages/presentation/pages/stage_details.dart';

class CampaignShowcasePage extends ConsumerStatefulWidget {
  final int initialIndex;

  const CampaignShowcasePage({super.key, this.initialIndex = 0});

  @override
  ConsumerState<CampaignShowcasePage> createState() =>
      _CampaignShowcasePageState();
}

class _CampaignShowcasePageState extends ConsumerState<CampaignShowcasePage> {
  late PageController _pageController;
  late int _currentPage;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(
      viewportFraction: 0.92,
      initialPage: widget.initialIndex,
    );

    WidgetsBinding.instance.addPostFrameCallback((final _) {
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.close,
              color: Colors.white.withOpacity(0.9),
              size: 22,
            ),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              if (state.hasData && _currentPage < state.dataList!.length) {
                final campaign = state.dataList![_currentPage];
                // Paylaşma işlevi
              }
            },
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.share_outlined,
                color: Colors.white.withOpacity(0.9),
                size: 22,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Arka Plan Parlama Efekti
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.3),
                  radius: 1.5,
                  colors: [
                    Colors.purple.withOpacity(0.15),
                    Colors.blue.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
            ),
          ),

          if (state.isLoading)
            const Center(
              child: ShimmerLoading(height: 500, width: 350),
            )
          else if (state.hasData && state.dataList!.isNotEmpty)
            _buildHeroContent(state.dataList!)
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 60,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Kampanya bulunamadı",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

          // Alt gölge efekti
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroContent(final List<Campaign> campaigns) {
    if (_currentPage >= campaigns.length) _currentPage = 0;
    final Campaign currentCampaign = campaigns[_currentPage];

    return Column(
      children: [
        // Ana Slider Bölümü
        Expanded(
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
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: _buildHeroCampaignCard(campaign),
              );
            },
          ),
        ),

        // İçerik Detay Bölümü
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
          child: Column(
            children: [
              // Dots Indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: DotsIndicator(
                  itemCount: campaigns.length,
                  currentIndex: _currentPage,
                  onPageSelected: (final page) {
                    _pageController.animateToPage(
                      page,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOutCubic,
                    );
                  },
                ),
              ),

              const SizedBox(height: 30),

              // Dinamik Detay Alanı
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                child: Column(
                  key: ValueKey<int>(_currentPage),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık
                    Text(
                      currentCampaign.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Açıklama
                    Text(
                      currentCampaign.url ??
                          "Bu özel etkinlik için sınırlı sayıda bilet mevcut. Kaçırma şansını yakala ve unutulmaz bir deneyimin parçası ol!",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Butonlar
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.white.withOpacity(0.9),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _navigateToPage(
                                    _resolveDetailPage(currentCampaign.url)),
                                borderRadius: BorderRadius.circular(30),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 18,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Hemen Bilet Al',
                                        style: TextStyle(
                                          color: context.primaryColor,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: context.primaryColor,
                                        size: 22,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // Paylaşma işlevi
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Center(
                                  child: Icon(
                                    Icons.share_outlined,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCampaignCard(final Campaign campaign) {
    return GestureDetector(
      onTap: () => _navigateToPage(_resolveDetailPage(campaign.url)),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: context.primaryColor.withOpacity(0.3),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Arkaplan Resmi
              CachedNetworkImage(
                imageUrl: campaign.imageUrl,
                fit: BoxFit.cover,
                placeholder: (final _, final __) => Container(
                  color: Colors.grey[900],
                ),
                errorWidget: (final _, final __, final ___) => Container(
                  color: context.colors.surface,
                  child: Center(
                    child: Icon(
                      Icons.campaign_outlined,
                      size: 80,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),

              // Gradyan Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.9),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // İçerik
              Positioned(
                bottom: 40,
                left: 25,
                right: 25,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kampanya Etiketi
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            context.primaryColor,
                            context.primaryColor.withOpacity(0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: context.primaryColor.withOpacity(0.5),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: Text(
                        'ÖZEL KAMPANYA',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Kampanya Başlığı
                    Text(
                      campaign.title,
                      style: context.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                        fontSize: 28,
                        shadows: [
                          const Shadow(
                            color: Colors.black45,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Üst Köşe Vinyet Efekti
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
