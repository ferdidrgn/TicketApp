import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../../shared/widgets/ticket/ticket_listing.dart';
import '../../../campaigns/domain/entities/campaign.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../discovery/presentation/widgets/browse_controls.dart';
import '../widgets/campaign_coupon.dart';
import '../widgets/web/campaign_showcase_desktop_view.dart';

/// KAMPANYALAR — her kampanya bir kupon (bkz. `campaign_coupon.dart`).
///
/// - Mobil (<768): kuponlar arasında yatay kaydırıcı; tek birincil aksiyon
///   ("Kampanyayı incele") başparmak bölgesinde, alt çubukta.
/// - Tablet (768–1023): öne çıkan kupon yatay (koçan sağda), altında diğer
///   kampanyalar iki sütunlu seçici satırlar; web'de sonunda Footer.
/// - Masaüstü (≥1024): `CampaignShowcaseDesktopPage`.
///
/// `initialIndex` (URL `?index=`) korunur ve her zaman listeye göre
/// sınırlandırılır. Önceki sürümdeki "Hızlı Bilet / Güvenli Ödeme / Koltuk
/// Seçimi" ikonları ve "tüm anlaşmalı sahnelerde geçerli" gibi metinler
/// kampanya verisinde olmayan, uydurma iddialardı — kaldırıldı.
class CampaignShowcasePage extends ConsumerStatefulWidget {
  final int initialIndex;

  const CampaignShowcasePage({super.key, this.initialIndex = 0});

  @override
  ConsumerState<CampaignShowcasePage> createState() =>
      _CampaignShowcasePageState();
}

class _CampaignShowcasePageState extends ConsumerState<CampaignShowcasePage> {
  PageController? _pageController;
  late int _currentPage;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex < 0 ? 0 : widget.initialIndex;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  PageController _controllerFor(final int count) =>
      _pageController ??= PageController(
        viewportFraction: 0.86,
        initialPage: _currentPage.clamp(0, count - 1),
      );

  void _goTo(final int page) {
    final c = _pageController;
    if (c == null || !c.hasClients) return;
    if (_reduceMotion) {
      c.jumpToPage(page);
    } else {
      c.animateToPage(page,
          duration: AppMotion.normal, curve: AppMotion.standard);
    }
  }

  void _retry() => ref.invalidate(campaignsProvider);

  @override
  Widget build(final BuildContext context) {
    if (context.isDesktop)
      return CampaignShowcaseDesktopPage(initialIndex: widget.initialIndex);

    final bool tablet = context.isTablet;
    final campaignsAsync = ref.watch(campaignsProvider);
    final List<Campaign>? campaigns = campaignsAsync.value;
    final double gutter = tablet ? AppSpacing.xxxl : AppSpacing.lg;

    final Widget content;
    if (campaignsAsync.isLoading && campaigns == null) {
      content = _Skeleton(tablet: tablet, gutter: gutter);
    } else if (campaigns == null) {
      content = _Notice(
        gutter: gutter,
        child: TicketNotice(
          label: 'BAĞLANTI',
          title: 'Kampanyalar yüklenemedi',
          message: 'Kampanya listesine ulaşamadık. İnternet bağlantını '
              'kontrol edip tekrar dene.',
          actionLabel: 'Tekrar dene',
          actionIcon: Icons.refresh_rounded,
          onAction: _retry,
        ),
      );
    } else if (campaigns.isEmpty) {
      content = _Notice(
        gutter: gutter,
        child: TicketNotice(
          label: 'KAMPANYA',
          title: 'Şu an aktif kampanya yok',
          message: 'Yeni fırsatlar eklendiğinde burada kupon olarak '
              'görünür. Bu arada sahnedeki oyunlara göz atabilirsin.',
          actionLabel: 'Oyunlara göz at',
          actionIcon: Icons.explore_outlined,
          onAction: () => NavigationHandler.goToDiscover(context),
        ),
      );
    } else {
      final int safeIndex = _currentPage.clamp(0, campaigns.length - 1);
      content = tablet
          ? _TabletShowcase(
              campaigns: campaigns,
              selectedIndex: safeIndex,
              gutter: gutter,
              onSelect: (final i) => setState(() => _currentPage = i),
            )
          : _MobileShowcase(
              campaigns: campaigns,
              currentIndex: safeIndex,
              controller: _controllerFor(campaigns.length),
              reduceMotion: _reduceMotion,
              onPageChanged: (final i) => setState(() => _currentPage = i),
              onDotTap: _goTo,
            );
    }

    return BasePageWrapper(
      title: 'Kampanyalar',
      subtitle: campaigns == null || campaigns.isEmpty
          ? null
          : (campaigns.length == 1
              ? '1 aktif kampanya'
              : '${campaigns.length} aktif kampanya'),
      showBackButton: true,
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: context.colors.surface,
        ambientColor: Colors.transparent,
        particleColor: Colors.transparent,
        safeAreaTop: true,
      ),
      child: content,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Mobil: kupon kaydırıcı + alt aksiyon çubuğu
// ─────────────────────────────────────────────────────────────────────────

class _MobileShowcase extends StatelessWidget {
  final List<Campaign> campaigns;
  final int currentIndex;
  final PageController controller;
  final bool reduceMotion;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onDotTap;

  const _MobileShowcase({
    required this.campaigns,
    required this.currentIndex,
    required this.controller,
    required this.reduceMotion,
    required this.onPageChanged,
    required this.onDotTap,
  });

  @override
  Widget build(final BuildContext context) {
    final Campaign current = campaigns[currentIndex];
    final VoidCallback? open = campaignOpenAction(current);
    final bool expired = CampaignValidity.of(current).expired;
    final cs = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Semantics(
            label: 'Kampanya ${currentIndex + 1} / ${campaigns.length}',
            child: PageView.builder(
              controller: controller,
              itemCount: campaigns.length,
              onPageChanged: onPageChanged,
              itemBuilder: (final context, final index) {
                final Widget coupon = Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.sm,
                      AppSpacing.md, AppSpacing.sm, AppSpacing.xl),
                  child: CampaignCoupon(
                    key: ValueKey('campaign-${campaigns[index].id}'),
                    campaign: campaigns[index],
                  ),
                );
                if (reduceMotion) return coupon;
                // Yandaki kuponlar hafifçe geride: kaydırmanın yönünü söyler.
                return AnimatedBuilder(
                  animation: controller,
                  builder: (final context, final child) {
                    double scale = 1;
                    if (controller.position.haveDimensions &&
                        controller.page != null) {
                      final double d = (controller.page! - index).abs();
                      scale = (1 - d * 0.06).clamp(0.94, 1.0);
                    }
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: coupon,
                );
              },
            ),
          ),
        ),
        if (campaigns.length > 1)
          _PageDots(
            count: campaigns.length,
            current: currentIndex,
            onTap: onDotTap,
          ),
        // Başparmak bölgesi: tek birincil aksiyon + ikincil paylaş.
        Container(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(top: BorderSide(color: cs.outlineVariant)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TicketStampButton(
                  label: expired ? 'Kampanyayı gör' : 'Kampanyayı incele',
                  leading: const Icon(Icons.local_offer_outlined),
                  onTap: open,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Semantics(
                button: true,
                label: 'Kampanyayı paylaş',
                excludeSemantics: true,
                child: IconButton(
                  tooltip: 'Paylaş',
                  onPressed: () => shareCampaign(current),
                  icon: Icon(Icons.ios_share_rounded, color: cs.onSurface),
                  constraints:
                      const BoxConstraints(minWidth: 56, minHeight: 56),
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Konum noktaları; her nokta 48dp dokunma alanında (kaydırmanın buton
/// karşılığı).
class _PageDots extends StatelessWidget {
  final int count;
  final int current;
  final ValueChanged<int> onTap;

  const _PageDots({
    required this.count,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    // Çok sayıda kampanyada noktalar sığmaz → "3 / 12" yazısı.
    if (count > 7) {
      return SizedBox(
        height: 32,
        child: Center(
          child: Text(
            '${current + 1} / $count',
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          Semantics(
            button: true,
            selected: i == current,
            label: 'Kampanya ${i + 1}',
            excludeSemantics: true,
            child: InkResponse(
              onTap: () => onTap(i),
              radius: 20,
              child: SizedBox(
                width: 36,
                height: 40,
                child: Center(
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    curve: AppMotion.standard,
                    width: i == current ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == current ? cs.primary : cs.outlineVariant,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Tablet: öne çıkan yatay kupon + seçici satırlar
// ─────────────────────────────────────────────────────────────────────────

class _TabletShowcase extends StatelessWidget {
  final List<Campaign> campaigns;
  final int selectedIndex;
  final double gutter;
  final ValueChanged<int> onSelect;

  const _TabletShowcase({
    required this.campaigns,
    required this.selectedIndex,
    required this.gutter,
    required this.onSelect,
  });

  @override
  Widget build(final BuildContext context) => ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(gutter, AppSpacing.lg, gutter, 0),
        children: [
          CampaignFeaturedCoupon(
            key: ValueKey('featured-${campaigns[selectedIndex].id}'),
            campaign: campaigns[selectedIndex],
          ),
          if (campaigns.length > 1) ...[
            const SizedBox(height: AppSpacing.huge),
            BrowseSectionTitle(
                title: 'Tüm kampanyalar', count: campaigns.length),
            BrowseColumns(
              minItemWidth: 320,
              runSpacing: AppSpacing.md,
              children: [
                for (int i = 0; i < campaigns.length; i++)
                  CampaignPickerRow(
                    key: ValueKey('pick-${campaigns[i].id}'),
                    campaign: campaigns[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelect(i),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.section),
          if (kIsWeb) const Footer(),
          const SizedBox(height: AppSpacing.xxl),
        ],
      );
}

// ─────────────────────────────────────────────────────────────────────────
// Durumlar
// ─────────────────────────────────────────────────────────────────────────

class _Notice extends StatelessWidget {
  final double gutter;
  final Widget child;
  const _Notice({required this.gutter, required this.child});

  @override
  Widget build(final BuildContext context) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            gutter, AppSpacing.xxl, gutter, AppSpacing.xxxl),
        child: Align(alignment: Alignment.topLeft, child: child),
      );
}

class _Skeleton extends StatelessWidget {
  final bool tablet;
  final double gutter;
  const _Skeleton({required this.tablet, required this.gutter});

  @override
  Widget build(final BuildContext context) => ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              tablet ? gutter : AppSpacing.xxl,
              AppSpacing.md,
              tablet ? gutter : AppSpacing.xxl,
              AppSpacing.xxl),
          child: tablet
              ? const Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ShimmerLoading(
                        width: double.infinity,
                        height: 420,
                        borderRadius: AppRadius.md),
                    SizedBox(height: AppSpacing.huge),
                    ShimmerLoading(
                        width: double.infinity,
                        height: 80,
                        borderRadius: AppRadius.sm),
                  ],
                )
              : LayoutBuilder(
                  builder: (final context, final c) => ShimmerLoading(
                    width: c.maxWidth,
                    height: c.maxHeight,
                    borderRadius: AppRadius.md,
                  ),
                ),
        ),
      );
}
