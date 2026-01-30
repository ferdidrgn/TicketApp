import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/services/deeplink/deeplink_service.dart';
import '../../../../core/util/comminucation_actions.dart';
import '../../../../core/util/global_scroll_mixin.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/custom_dots_indicator.dart';
import '../../../campaigns/domain/entities/campaign.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';

class CampaignShowcasePage extends ConsumerStatefulWidget {
  final int initialIndex;

  const CampaignShowcasePage({super.key, this.initialIndex = 0});

  @override
  ConsumerState<CampaignShowcasePage> createState() =>
      _CampaignShowcasePageState();
}

class _CampaignShowcasePageState extends ConsumerState<CampaignShowcasePage>
    with GlobalScrollMixin {
  late PageController _pageController;
  late int _currentPage;
  bool _isControllerInitialized = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isControllerInitialized) {
      _pageController = PageController(
        viewportFraction:
            context.responsive(mobile: 0.85, tablet: 0.75, desktop: 0.6),
        initialPage: widget.initialIndex,
      );
      _isControllerInitialized = true;
    }
  }

  @override
  void dispose() {
    if (_isControllerInitialized) _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final campaignsAsync = ref.watch(campaignsProvider);
    final bool isLargeScreen = context.isTablet || context.isDesktop;

    return BasePageWrapper(
      // 🎯 Merkezi Header Yönetimi
      title: "AVANTAJLAR",
      subtitle: "Sanat dolu fırsatları keşfet...",
      showBackButton: true,
      rightIcon: Icons.support_agent_rounded,
      // 💡 Yardım ikonu artık header'da
      showFab: true,
      customScrollController: scrollController,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: context.colors.surface,
        safeAreaTop: true,
      ),
      child: campaignsAsync.when(
        loading: () =>
            const Center(child: ShimmerLoading(height: 500, width: 350)),
        error: (final err, final _) => Center(child: Text("Hata: $err")),
        data: (final campaigns) {
          if (campaigns.isEmpty) return _buildEmptyState();

          // 🖥️ Web'de içeriği ortalamak için kısıt koyuyoruz
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: isLargeScreen ? 1000 : double.infinity),
              child: _buildBody(context, campaigns),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
      final BuildContext context, final List<Campaign> campaigns) {
    final currentCampaign = campaigns[_currentPage];

    return ListView(
      // 💡 ListView kullanarak scrollController'ı buraya bağlıyoruz
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      children: [
        // 1. HERO SECTION (Pager Area)
        Stack(
          children: [
            _buildBackgroundGradientEffect(),
            Column(
              children: [
                SizedBox(
                  height: context.hp(65),
                  // 💡 Header geldiği için yüksekliği biraz daralttık
                  child: _buildCampaignPager(campaigns),
                ),
                _buildCampaignInfoOverlay(currentCampaign, campaigns.length),
              ],
            ),
          ],
        ),

        // 2. DYNAMIC CONTENT SECTION
        _buildDetailedContent(context, currentCampaign),
      ],
    );
  }

  // --- İyileştirilmiş UI Bileşenleri ---

  Widget _buildDetailedContent(
      final BuildContext context, final Campaign campaign) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.info_outline, "KAMPANYA DETAYLARI"),
          const SizedBox(height: 12),
          Text(
            "Seçili sahnelerde geçerli olan bu fırsatı kaçırmayın. Tiyatrol ile sanata bir adım daha yakınlaşın.",
            style: context.textTheme.bodyMedium
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 32),

          // İkonlu Bilgi Kartları (Responsive Düzen)
          Row(
            children: [
              _buildInfoChip(Icons.confirmation_num_outlined, "Hızlı Bilet"),
              _buildInfoChip(Icons.verified_user_outlined, "Güvenli Ödeme"),
              _buildInfoChip(Icons.event_seat_outlined, "Koltuk Seçimi"),
            ],
          ),
          const SizedBox(height: 40),

          _buildSectionHeader(
              Icons.share_location_outlined, "GEÇERLİ SAHNELER"),
          const SizedBox(height: 12),
          Text(
            "Bu kampanya tüm Tiyatrol anlaşmalı sahnelerde ve mobil uygulamada geçerlidir.",
            style: context.textTheme.bodySmall
                ?.copyWith(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCampaignInfoOverlay(final Campaign campaign, final int total) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            DotsIndicator(
              itemCount: total,
              currentIndex: _currentPage,
              onPageSelected: (final page) => _pageController.animateToPage(
                  page,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut),
            ),
            const SizedBox(height: 24),
            Text(
              campaign.title.toUpperCase(),
              style: context.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildActionButtons(campaign),
          ],
        ),
      );

  Widget _buildActionButtons(Campaign campaign) => Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => NavigationHandler.globalGoTo(campaign.url),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: context.colors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 8,
                shadowColor: context.primaryColor.withOpacity(0.4),
              ),
              child: const Text("ŞİMDİ İNCELE",
                  style:
                      TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ),
          const SizedBox(width: 16),
          _buildShareButton(campaign),
        ],
      );

  Widget _buildShareButton(Campaign campaign) => GestureDetector(
        onTap: () => TiyatrolDeeplinkService.shareShow(
            id: campaign.id, name: campaign.title),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.colors.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.outlineVariant),
          ),
          child: Icon(Icons.share_outlined,
              color: context.colors.onSurface, size: 24),
        ),
      );

  // ... (Diğer _build metodların olan _buildSectionHeader, _buildInfoChip, _buildCampaignPager, _buildCampaignCard aynı kalabilir)

  Widget _buildSectionHeader(final IconData icon, final String title) => Row(
        children: [
          Icon(icon, color: context.primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.primaryColor,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ],
      );

  Widget _buildInfoChip(final IconData icon, final String label) => Expanded(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: context.primaryColor, size: 28),
            ),
            const SizedBox(height: 12),
            Text(label,
                style: context.textTheme.labelSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      );

  Widget _buildBackgroundGradientEffect() => Positioned.fill(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              colors: [
                context.primaryColor.withOpacity(0.12),
                Colors.transparent
              ],
              radius: 1.5,
            ),
          ),
        ),
      );

  Widget _buildEmptyState() => Center(
      child: Text("Aktif kampanya bulunamadı.",
          style: context.textTheme.titleMedium));

  Widget _buildCampaignPager(final List<Campaign> campaigns) =>
      PageView.builder(
        controller: _pageController,
        itemCount: campaigns.length,
        onPageChanged: (final index) => setState(() => _currentPage = index),
        itemBuilder: (final context, final index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (final context, final child) {
              double value = 1.0;
              if (_pageController.position.haveDimensions) {
                value = (_pageController.page! - index).abs();
                value = (1 - (value * 0.2)).clamp(0.8, 1.0);
              }
              return Transform.scale(scale: value, child: child);
            },
            child: _buildCampaignCard(campaigns[index]),
          );
        },
      );

  Widget _buildCampaignCard(final Campaign campaign) => Container(
        margin: EdgeInsets.symmetric(vertical: context.hp(5), horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(context.borderRadius(2)),
          boxShadow: [
            BoxShadow(
              color: context.colors.shadow.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.borderRadius(2)),
          child: CachedNetworkImage(
            imageUrl: campaign.imageUrl,
            fit: BoxFit.cover,
            placeholder: (final _, final __) =>
                Container(color: context.colors.surfaceContainer),
          ),
        ),
      );
}
