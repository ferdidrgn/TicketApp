import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/util/responsive_utils.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../../shared/widgets/footers/footer.dart';
import '../../../../../shared/widgets/ticket/ticket_listing.dart';
import '../../../../discovery/presentation/widgets/browse_controls.dart';
import '../../../../settings/presentation/widgets/preference_widgets.dart';
import '../../../domain/entities/campaign.dart';
import '../../providers/campaign_provider.dart';
import '../campaign_coupon.dart';
import '../campaign_spotlight_carousel.dart';

// =============================================================================
// MASAÜSTÜ (WEB) KAMPANYALAR
// =============================================================================
//
// Yapı: solda öne çıkan kampanya — yatay KUPON (gövdede gerçek görsel +
// başlık + tek birincil aksiyon, koçanda geçerlilik + barkod); sağda diğer
// kampanyaları öne çıkaran sade seçici satırlar. Sayfa kayar → sonunda
// site geneli Footer.
//
// `BasePageWrapper` kullanılmıyor ve rota bir kabuğun içinde değil → kendi
// `Scaffold`'u (önceden yoktu: metinler Material atası olmadan çiziliyordu)
// ve sayfa başlığının solunda 48dp geri butonu (önceki sağ üstte yüzen buzlu
// cam "kapat" butonunun yerine). Sabit lacivert/altın `WebColors` ve "D
// harfi" asimetrik köşeler kaldırıldı; renkler temadan, kağıt/mürekkep
// `TicketInk`'ten.
//
// Veri mobille birebir aynı: `campaignsProvider`; `initialIndex` listeye
// göre sınırlandırılır.
class CampaignShowcaseDesktopPage extends ConsumerStatefulWidget {
  final int initialIndex;

  const CampaignShowcaseDesktopPage({super.key, this.initialIndex = 0});

  @override
  ConsumerState<CampaignShowcaseDesktopPage> createState() =>
      _CampaignShowcaseDesktopPageState();
}

class _CampaignShowcaseDesktopPageState
    extends ConsumerState<CampaignShowcaseDesktopPage> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex < 0 ? 0 : widget.initialIndex;
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final campaignsAsync = ref.watch(campaignsProvider);
    final List<Campaign>? campaigns = campaignsAsync.value;

    final String? lede = campaigns == null || campaigns.isEmpty
        ? null
        : (campaigns.length == 1
            ? 'Şu an 1 aktif kampanya var.'
            : 'Şu an ${campaigns.length} aktif kampanya var. Birini seç, '
                'detayına bak.');

    final Widget content;
    if (campaignsAsync.isLoading && campaigns == null) {
      content = const _DesktopSkeleton();
    } else if (campaigns == null) {
      content = Align(
        alignment: Alignment.topLeft,
        child: TicketNotice(
          label: 'BAĞLANTI',
          title: 'Kampanyalar yüklenemedi',
          message: 'Kampanya listesine ulaşamadık. İnternet bağlantını '
              'kontrol edip tekrar dene.',
          actionLabel: 'Tekrar dene',
          actionIcon: Icons.refresh_rounded,
          onAction: () => ref.invalidate(campaignsProvider),
        ),
      );
    } else if (campaigns.isEmpty) {
      content = Align(
        alignment: Alignment.topLeft,
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
      final int safeIndex = _selectedIndex.clamp(0, campaigns.length - 1);
      final Campaign selected = campaigns[safeIndex];
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: CampaignEditorialHero(
              key: ValueKey('featured-${selected.id}'),
              campaign: selected,
            ),
          ),
          if (campaigns.length > 1) ...[
            const SizedBox(width: AppSpacing.huge),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BrowseSectionTitle(
                      title: 'Tüm kampanyalar', count: campaigns.length),
                  for (int i = 0; i < campaigns.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.sm),
                    CampaignPickerRow(
                      key: ValueKey('pick-${campaigns[i].id}'),
                      campaign: campaigns[i],
                      selected: i == safeIndex,
                      onTap: () => setState(() => _selectedIndex = i),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (final context, final constraints) {
            final double gutter = math.max(
              context.pagePadding.left,
              (constraints.maxWidth - 1240) / 2,
            );
            return ListView(
              padding: const EdgeInsets.only(top: AppSpacing.massive),
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: PreferencePageHeading(
                    title: 'Kampanyalar',
                    lede: lede,
                    onBack: () => NavigationHandler.smartGoBack(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.huge),
                ResponsiveUtils.maxWidthContainer(
                  maxWidth: 1240,
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: content,
                ),
                const SizedBox(height: AppSpacing.section),
                const Footer(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DesktopSkeleton extends StatelessWidget {
  const _DesktopSkeleton();

  @override
  Widget build(final BuildContext context) => const ExcludeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ShimmerLoading(
                  width: double.infinity,
                  height: 520,
                  borderRadius: AppRadius.md),
            ),
            SizedBox(width: AppSpacing.huge),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  ShimmerLoading(
                      width: double.infinity,
                      height: 80,
                      borderRadius: AppRadius.sm),
                  SizedBox(height: AppSpacing.sm),
                  ShimmerLoading(
                      width: double.infinity,
                      height: 80,
                      borderRadius: AppRadius.sm),
                  SizedBox(height: AppSpacing.sm),
                  ShimmerLoading(
                      width: double.infinity,
                      height: 80,
                      borderRadius: AppRadius.sm),
                ],
              ),
            ),
          ],
        ),
      );
}
