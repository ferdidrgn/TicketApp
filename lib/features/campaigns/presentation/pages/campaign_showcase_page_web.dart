import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/navigation/widgets/web_account_shell.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../domain/entities/campaign.dart';
import '../providers/campaign_provider.dart';
import '../widgets/campaign_coupon.dart';

enum _Filter { all, active, ended }

/// KAMPANYALAR — WEB. Hesap kabuğu içinde: üstte öne çıkan kupon, altında
/// süzülebilir kampanya kartları ızgarası, sağda yapışkan özet. Mobil
/// `CampaignShowcasePage`'den AYRIDIR. Veri: `campaignsProvider`; geçerlilik
/// `CampaignValidity` ile gerçek tarihlerden türetilir (tarih uydurulmaz).
/// `initialIndex` (URL `?index=`) listeye göre sınırlandırılır.
class CampaignShowcasePageWeb extends ConsumerStatefulWidget {
  final int initialIndex;
  const CampaignShowcasePageWeb({super.key, this.initialIndex = 0});

  @override
  ConsumerState<CampaignShowcasePageWeb> createState() =>
      _CampaignShowcasePageWebState();
}

class _CampaignShowcasePageWebState
    extends ConsumerState<CampaignShowcasePageWeb> {
  String? _selectedId;
  _Filter _filter = _Filter.all;

  @override
  Widget build(final BuildContext context) {
    final async = ref.watch(campaignsProvider);
    final List<Campaign>? campaigns = async.value;

    final Widget body;
    if (async.isLoading && campaigns == null) {
      body = const _Skeleton();
    } else if (campaigns == null) {
      body = WebStatePanel(
        icon: Icons.cloud_off_rounded,
        title: 'Kampanyalar yüklenemedi',
        message: 'Kampanya listesine ulaşamadık. Bağlantını kontrol edip '
            'tekrar dene.',
        actionLabel: 'Tekrar dene',
        onAction: () => ref.invalidate(campaignsProvider),
      );
    } else if (campaigns.isEmpty) {
      body = WebStatePanel(
        icon: Icons.local_offer_outlined,
        title: 'Şu an aktif kampanya yok',
        message: 'Yeni fırsatlar eklendiğinde burada kupon olarak görünür. '
            'Bu arada sahnedeki oyunlara göz atabilirsin.',
        actionLabel: 'Oyunlara göz at',
        onAction: () => NavigationHandler.goToDiscover(context),
      );
    } else {
      body = _Content(
        campaigns: campaigns,
        initialIndex: widget.initialIndex,
        selectedId: _selectedId,
        filter: _filter,
        onSelect: (final c) {
          HapticFeedback.selectionClick();
          setState(() => _selectedId = c.id);
        },
        onFilter: (final f) => setState(() => _filter = f),
      );
    }

    final int? active = campaigns
        ?.where((final c) => !CampaignValidity.of(c).expired)
        .length;

    return WebAccountShell(
      current: WebAccountSection.campaigns,
      title: 'Kampanyalar',
      subtitle: campaigns == null || campaigns.isEmpty
          ? 'Biletlerde ve oyunlarda geçerli fırsatlar.'
          : '${active ?? campaigns.length} geçerli kampanya. Birini seç, '
              'kuponunu incele.',
      aside: campaigns == null || campaigns.isEmpty
          ? null
          : _Summary(campaigns: campaigns),
      child: body,
    );
  }
}

class _Content extends StatelessWidget {
  final List<Campaign> campaigns;
  final int initialIndex;
  final String? selectedId;
  final _Filter filter;
  final ValueChanged<Campaign> onSelect;
  final ValueChanged<_Filter> onFilter;

  const _Content({
    required this.campaigns,
    required this.initialIndex,
    required this.selectedId,
    required this.filter,
    required this.onSelect,
    required this.onFilter,
  });

  @override
  Widget build(final BuildContext context) {
    final Campaign featured = selectedId != null
        ? campaigns.firstWhere((final c) => c.id == selectedId,
            orElse: () => campaigns.first)
        : campaigns[initialIndex.clamp(0, campaigns.length - 1)];

    bool ended(final Campaign c) => CampaignValidity.of(c).expired;
    final int endedCount = campaigns.where(ended).length;
    final List<Campaign> list = campaigns.where((final c) {
      return switch (filter) {
        _Filter.all => true,
        _Filter.active => !ended(c),
        _Filter.ended => ended(c),
      };
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampaignFeaturedCoupon(
          key: ValueKey('featured-${featured.id}'),
          campaign: featured,
        ),
        const SizedBox(height: AppSpacing.section),
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Tüm kampanyalar',
                    style: Sk.display(context, size: 26)),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            SkChip(
              label: 'Tümü',
              count: campaigns.length,
              selected: filter == _Filter.all,
              onTap: () => onFilter(_Filter.all),
            ),
            SkChip(
              label: 'Devam eden',
              count: campaigns.length - endedCount,
              selected: filter == _Filter.active,
              onTap: () => onFilter(_Filter.active),
            ),
            if (endedCount > 0)
              SkChip(
                label: 'Süresi dolan',
                count: endedCount,
                selected: filter == _Filter.ended,
                onTap: () => onFilter(_Filter.ended),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        if (list.isEmpty)
          const WebStatePanel(
            icon: Icons.local_offer_outlined,
            title: 'Bu süzgeçte kampanya yok',
            message: 'Başka bir süzgeç seçerek tüm kampanyaları görebilirsin.',
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 340,
              mainAxisSpacing: AppSpacing.xl,
              crossAxisSpacing: AppSpacing.xl,
              mainAxisExtent: 330,
            ),
            itemCount: list.length,
            itemBuilder: (final context, final i) => _CampaignCard(
              key: ValueKey('camp-${list[i].id}'),
              campaign: list[i],
              selected: list[i].id == featured.id,
              onSelect: () => onSelect(list[i]),
            ),
          ),
      ],
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final bool selected;
  final VoidCallback onSelect;

  const _CampaignCard({
    super.key,
    required this.campaign,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final CampaignValidity v = CampaignValidity.of(campaign);
    final VoidCallback? open = campaignOpenAction(campaign);
    final String validity = v.until != null
        ? 'Son gün ${v.until}'
        : (v.from != null ? 'Başlangıç ${v.from}' : 'Tiyatrol kampanyası');

    return Opacity(
      opacity: v.expired ? 0.65 : 1,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 2 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              label: '${campaign.title}, öne çıkar',
              excludeSemantics: true,
              child: InkWell(
                onTap: onSelect,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      SkImage(url: campaign.imageUrl),
                      if (v.status != null)
                        Positioned(
                            left: 10,
                            top: 10,
                            child: SkBadge(label: v.status!)),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(campaign.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Sk.display(context, size: 18, height: 1.15)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(validity,
                        style: Sk.ui(context,
                            size: 12.5,
                            color: cs.onSurfaceVariant,
                            weight: FontWeight.w600)),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: WebTextAction(
                            label: 'Kampanyayı incele',
                            icon: Icons.arrow_outward_rounded,
                            onTap: open,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Paylaş',
                          onPressed: () => shareCampaign(campaign),
                          constraints: const BoxConstraints(
                              minWidth: 44, minHeight: 44),
                          icon: Icon(Icons.ios_share_rounded,
                              size: 20, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final List<Campaign> campaigns;
  const _Summary({required this.campaigns});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<Campaign> live = campaigns
        .where((final c) => !CampaignValidity.of(c).expired)
        .toList();
    Campaign? soon;
    int? soonDays;
    for (final Campaign c in live) {
      final int? d = CampaignValidity.of(c).daysLeft;
      if (d == null) continue;
      if (soonDays == null || d < soonDays) {
        soon = c;
        soonDays = d;
      }
    }
    return WebPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('ÖZET',
              style: Sk.ui(context,
                  size: 11,
                  color: cs.onSurfaceVariant,
                  weight: FontWeight.w800,
                  letterSpacing: 1.8)),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${live.length}',
                  style: Sk.display(context, size: 44, color: cs.primary)),
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('geçerli kampanya',
                    style: Sk.ui(context,
                        size: 14,
                        color: cs.onSurfaceVariant,
                        weight: FontWeight.w600)),
              ),
            ],
          ),
          if (soon != null && soonDays != null) ...[
            Divider(height: AppSpacing.xxxl, color: cs.outlineVariant),
            Text('En yakın bitiş',
                style: Sk.ui(context, size: 13, weight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.xs),
            Text(soon.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Sk.ui(context, size: 14.5, weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
                soonDays == 0
                    ? 'Bugün son gün'
                    : '$soonDays gün kaldı',
                style: Sk.ui(context,
                    size: 13.5, color: cs.primary, weight: FontWeight.w800)),
          ],
          Divider(height: AppSpacing.xxxl, color: cs.outlineVariant),
          WebTextAction(
            label: 'Oyunlara göz at',
            icon: Icons.explore_outlined,
            onTap: () => NavigationHandler.goToDiscover(context),
          ),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(final BuildContext context) => const ExcludeSemantics(
        child: Column(
          children: [
            SkBone(height: 420, radius: AppRadius.md),
            SizedBox(height: AppSpacing.xxl),
            Row(
              children: [
                Expanded(child: SkBone(height: 300, radius: AppRadius.md)),
                SizedBox(width: AppSpacing.xl),
                Expanded(child: SkBone(height: 300, radius: AppRadius.md)),
              ],
            ),
          ],
        ),
      );
}
