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

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
    _pageController = PageController(
      viewportFraction: 0.92,
      initialPage: widget.initialIndex,
    );
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
    final campaignsAsync = ref.watch(campaignsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, campaignsAsync),
      body: Stack(
        children: [
          _buildBackgroundGradient(),

          campaignsAsync.when(
            loading: () => const Center(
              child: ShimmerLoading(height: 500, width: 350),
            ),
            error: (final err, final stack) => Center(
              child: Text("Hata: $err",
                  style: const TextStyle(color: Colors.white)),
            ),
            data: (final campaigns) {
              if (campaigns.isEmpty) return _buildEmptyState();
              return _buildHeroContent(campaigns);
            },
          ),

          _buildBottomOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      final BuildContext context, final AsyncValue<List<Campaign>> state) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: _buildCircleButton(Icons.close, () => Navigator.pop(context)),
      actions: [
        state.maybeWhen(
          data: (final list) => _buildCircleButton(Icons.share_outlined, () {
            if (_currentPage < list.length) {}
          }),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildCircleButton(final IconData icon, final VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.9), size: 22),
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    return Positioned.fill(
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined,
              size: 60, color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 20),
          Text("Kampanya bulunamadı",
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildBottomOverlay() {
    return Positioned(
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
              Colors.black
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroContent(final List<Campaign> campaigns) {
    if (_currentPage >= campaigns.length) _currentPage = 0;
    final Campaign currentCampaign = campaigns[_currentPage];

    return Column(
      children: [
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
                      child: Opacity(opacity: value, child: child));
                },
                child: _buildHeroCampaignCard(campaign),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              _buildDotsIndicator(campaigns.length),
              const SizedBox(height: 30),
              _buildCampaignDetails(currentCampaign),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDotsIndicator(final int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: DotsIndicator(
        itemCount: count,
        currentIndex: _currentPage,
        onPageSelected: (final page) => _pageController.animateToPage(page,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic),
      ),
    );
  }

  Widget _buildCampaignDetails(final Campaign campaign) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Column(
        key: ValueKey<int>(_currentPage),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(campaign.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Text(campaign.url,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                  height: 1.5)),
          const SizedBox(height: 30),
          _buildActionButtons(campaign),
        ],
      ),
    );
  }

  Widget _buildActionButtons(final Campaign campaign) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ElevatedButton(
            onPressed: () => _navigateToPage(_resolveDetailPage(campaign.url)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: context.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Hemen Bilet Al',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 12),
                Icon(Icons.arrow_forward_rounded),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        _buildIconButton(Icons.share_outlined, () {}),
      ],
    );
  }

  Widget _buildIconButton(final IconData icon, final VoidCallback onTap) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Icon(icon, color: Colors.white.withOpacity(0.9)),
      ),
    );
  }

  Widget _buildHeroCampaignCard(final Campaign campaign) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: context.primaryColor.withOpacity(0.3), blurRadius: 30)
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
              placeholder: (final _, final __) =>
                  Container(color: Colors.grey[900]),
            ),
            _buildCardGradient(),
            _buildCardContent(campaign),
          ],
        ),
      ),
    );
  }

  Widget _buildCardGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
        ),
      ),
    );
  }

  Widget _buildCardContent(final Campaign campaign) {
    return Positioned(
      bottom: 40,
      left: 25,
      right: 25,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTag('ÖZEL KAMPANYA'),
          const SizedBox(height: 16),
          Text(campaign.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28)),
        ],
      ),
    );
  }

  Widget _buildTag(final String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
