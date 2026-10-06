import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/ticket/ticket_listing.dart';
import '../../../campaigns/domain/entities/campaign.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../discovery/presentation/widgets/browse_controls.dart';
import '../widgets/campaign_coupon.dart';
import '../widgets/campaign_spotlight_carousel.dart';
import '../widgets/web/campaign_showcase_desktop_view.dart';

/// KAMPANYALAR — editöryal keşif: afiş vitrini + gerçek Firestore kampanyası.
///
/// Kırılımlar: mobil (dikey vitrin + alt çubuk), tablet (yan yana vitrin +
/// liste), masaüstü (kendi `Scaffold` + Footer).
class CampaignShowcasePage extends ConsumerStatefulWidget {
  final int initialIndex;

  const CampaignShowcasePage({super.key, this.initialIndex = 0});

  @override
  ConsumerState<CampaignShowcasePage> createState() =>
      _CampaignShowcasePageState();
}

class _CampaignShowcasePageState extends ConsumerState<CampaignShowcasePage> {
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialIndex < 0 ? 0 : widget.initialIndex;
  }

  void _retry() => ref.invalidate(campaignsProvider);

  @override
  Widget build(final BuildContext context) {
    if (context.isDesktop) {
      return CampaignShowcaseDesktopPage(initialIndex: widget.initialIndex);
    }

    final campaignsAsync = ref.watch(campaignsProvider);
    final List<Campaign>? campaigns = campaignsAsync.value;
    final EdgeInsets pageInset = context.pagePadding;

    final Widget content;
    if (campaignsAsync.isLoading && campaigns == null) {
      content = _Skeleton(pageInset: pageInset);
    } else if (campaigns == null) {
      content = _Notice(
        pageInset: pageInset,
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
        pageInset: pageInset,
        child: TicketNotice(
          label: 'KAMPANYA',
          title: 'Şu an aktif kampanya yok',
          message: 'Yeni fırsatlar eklendiğinde burada görünür. '
              'Bu arada sahnedeki oyunlara göz atabilirsin.',
          actionLabel: 'Oyunlara göz at',
          actionIcon: Icons.explore_outlined,
          onAction: () => NavigationHandler.goToDiscover(context),
        ),
      );
    } else {
      final int safeIndex = _currentPage.clamp(0, campaigns.length - 1);
      content = context.isTablet
          ? _TabletShowcase(
              campaigns: campaigns,
              selectedIndex: safeIndex,
              pageInset: pageInset,
              onSelect: (final i) => setState(() => _currentPage = i),
            )
          : _MobileShowcase(
              campaigns: campaigns,
              currentIndex: safeIndex,
              initialIndex: safeIndex,
              pageInset: pageInset,
              onIndexChanged: (final i) => setState(() => _currentPage = i),
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

class _MobileShowcase extends StatelessWidget {
  final List<Campaign> campaigns;
  final int currentIndex;
  final int initialIndex;
  final EdgeInsets pageInset;
  final ValueChanged<int> onIndexChanged;

  const _MobileShowcase({
    required this.campaigns,
    required this.currentIndex,
    required this.initialIndex,
    required this.pageInset,
    required this.onIndexChanged,
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
          child: CampaignSpotlightCarousel(
            campaigns: campaigns,
            initialIndex: initialIndex,
            onIndexChanged: onIndexChanged,
            padding: EdgeInsets.fromLTRB(
              pageInset.left,
              AppSpacing.md,
              pageInset.right,
              0,
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              pageInset.left,
              AppSpacing.md,
              pageInset.right,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(top: BorderSide(color: cs.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: open,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.sm)),
                    ),
                    icon: const Icon(Icons.local_offer_outlined),
                    label: Text(
                        expired ? 'Kampanyayı gör' : 'Kampanyayı incele'),
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
                        const BoxConstraints(minWidth: 48, minHeight: 48),
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
        ),
      ],
    );
  }
}

class _TabletShowcase extends StatelessWidget {
  final List<Campaign> campaigns;
  final int selectedIndex;
  final EdgeInsets pageInset;
  final ValueChanged<int> onSelect;

  const _TabletShowcase({
    required this.campaigns,
    required this.selectedIndex,
    required this.pageInset,
    required this.onSelect,
  });

  @override
  Widget build(final BuildContext context) {
    final int safe = selectedIndex.clamp(0, campaigns.length - 1);
    final double carouselHeight = context.responsive(
      mobile: 280,
      tablet: 340,
      desktop: 400,
    );
    const double maxContent = 960;

    final Widget featured = campaigns.length == 1
        ? CampaignEditorialHero(
            key: ValueKey('hero-${campaigns.first.id}'),
            campaign: campaigns.first,
          )
        : CampaignSpotlightCarousel(
            campaigns: campaigns,
            initialIndex: safe,
            activeIndex: safe,
            height: carouselHeight,
            onIndexChanged: onSelect,
            padding: EdgeInsets.zero,
          );

    final Widget? picker = campaigns.length > 1
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BrowseSectionTitle(
                  title: 'Tüm kampanyalar', count: campaigns.length),
              const SizedBox(height: AppSpacing.md),
              for (int i = 0; i < campaigns.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                CampaignPickerRow(
                  key: ValueKey('pick-${campaigns[i].id}'),
                  campaign: campaigns[i],
                  selected: i == safe,
                  onTap: () => onSelect(i),
                ),
              ],
            ],
          )
        : null;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        pageInset.left,
        AppSpacing.lg,
        pageInset.right,
        AppSpacing.xxl,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContent),
            child: campaigns.length == 1
                ? featured
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: featured),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(flex: 2, child: picker!),
                    ],
                  ),
          ),
        ),
        if (kIsWeb) ...[
          const SizedBox(height: AppSpacing.section),
          const Footer(),
        ],
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  final EdgeInsets pageInset;
  final Widget child;
  const _Notice({required this.pageInset, required this.child});

  @override
  Widget build(final BuildContext context) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          pageInset.left,
          AppSpacing.xxl,
          pageInset.right,
          AppSpacing.xxxl,
        ),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.isTablet ? 720 : double.infinity,
            ),
            child: child,
          ),
        ),
      );
}

class _Skeleton extends StatelessWidget {
  final EdgeInsets pageInset;
  const _Skeleton({required this.pageInset});

  @override
  Widget build(final BuildContext context) {
    final double carouselHeight = context.responsive(
      mobile: 280,
      tablet: 340,
      desktop: 400,
    );
    return ExcludeSemantics(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          pageInset.left,
          AppSpacing.md,
          pageInset.right,
          AppSpacing.xxl,
        ),
        child: context.isTablet
            ? ShimmerLoading(
                width: double.infinity,
                height: carouselHeight,
                borderRadius: AppRadius.lg,
              )
            : LayoutBuilder(
                builder: (final context, final c) => ShimmerLoading(
                  width: c.maxWidth,
                  height: c.maxHeight * 0.72,
                  borderRadius: AppRadius.lg,
                ),
              ),
      ),
    );
  }
}
