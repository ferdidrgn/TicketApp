import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../core/services/deeplink/deeplink_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../../shared/widgets/section_header.dart';
import '../../../domain/entities/campaign.dart';
import '../../providers/campaign_provider.dart';

// =============================================================================
// MASAÜSTÜ (WEB) "AVANTAJLAR" (KAMPANYA VİTRİNİ) SAYFASI
// =============================================================================
//
// Mobildeki dikey `PageView` kaydırıcısı web'de doğal bir etkileşim değil —
// masaüstünde bunun yerine öne çıkan kampanyayı büyük gösteren, yanında
// diğer kampanyaların tıklanabilir bir listesini sunan iki sütunlu bir
// "vitrin" düzeni kullanılıyor. Veri kaynağı mobille BİREBİR aynı:
// `campaignsProvider` — gerçek Firestore kampanyaları. `Campaign` varlığında
// açıklama/istatistik alanı YOK, o yüzden burada da uydurulmuyor; sadece
// gerçek alanlar (başlık, görsel, geçerlilik tarihleri, link) gösteriliyor.
//
// `BasePageWrapper` KASITLI OLARAK KULLANILMIYOR — mobil uygulama çatısıdır.
// Bkz. `nearby_events_page.dart`'taki `_NearbyEventsDesktopPage` — aynı
// gerekçe.
class CampaignShowcaseDesktopPage extends StatefulWidget {
  final int initialIndex;

  const CampaignShowcaseDesktopPage({super.key, this.initialIndex = 0});

  @override
  State<CampaignShowcaseDesktopPage> createState() =>
      _CampaignShowcaseDesktopPageState();
}

class _CampaignShowcaseDesktopPageState
    extends State<CampaignShowcaseDesktopPage> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(final BuildContext context) => ColoredBox(
        // NOT: Gövde kendi `ListView`'ı ile zaten kaydırılabilir — burada
        // ikinci bir SingleChildScrollView SARMAK "unbounded height"
        // hatasına yol açar, bilerek eklenmedi.
        color: WebColors.darkBlueBackground,
        child: Center(
          child: ConstrainedBox(
            constraints:
                BoxConstraints(maxWidth: context.isLargeDesktop ? 1360 : 1180),
            child: Consumer(
              builder: (final context, final ref, final _) {
                final campaignsAsync = ref.watch(campaignsProvider);
                return campaignsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(WebColors.primaryGold),
                    ),
                  ),
                  error: (final err, final stack) => Center(
                    child: Text(
                      'Kampanyalar yüklenemedi: $err',
                      style: TextStyle(
                          color: WebColors.textSecondary, fontSize: 15),
                    ),
                  ),
                  data: (final campaigns) {
                    if (campaigns.isEmpty)
                      return const _CampaignsEmptyState();

                    final int safeIndex =
                        _selectedIndex.clamp(0, campaigns.length - 1);
                    final Campaign selected = campaigns[safeIndex];

                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: SectionHeader(
                            title: 'Avantajlar',
                            subtitle: '${campaigns.length} aktif kampanya',
                            titleColor: Colors.white,
                            accentColor: WebColors.primaryGold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: LayoutBuilder(
                            builder: (final context, final constraints) {
                              final bool stackVertically =
                                  constraints.maxWidth < 760;
                              final featured = _FeaturedCampaignPanel(
                                  campaign: selected);
                              final sideList = _CampaignSideList(
                                campaigns: campaigns,
                                selectedIndex: safeIndex,
                                onSelect: (final index) =>
                                    setState(() => _selectedIndex = index),
                              );

                              if (stackVertically)
                                return Column(
                                  children: [
                                    featured,
                                    const SizedBox(height: 24),
                                    sideList,
                                  ],
                                );

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 3, child: featured),
                                  const SizedBox(width: 28),
                                  Expanded(flex: 2, child: sideList),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      );
}

class _FeaturedCampaignPanel extends StatelessWidget {
  final Campaign campaign;

  const _FeaturedCampaignPanel({required this.campaign});

  @override
  Widget build(final BuildContext context) {
    final bool hasValidity =
        campaign.startDate.isNotEmpty || campaign.endDate.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(32),
        ),
        border: Border.all(color: WebColors.primaryGold.withOpacity(0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(14),
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 420,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  OptimizedCachedImage(
                      imageUrl: campaign.imageUrl,
                      fit: BoxFit.cover,
                      borderRadius: 0),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          WebColors.darkBlueSurface.withOpacity(0.95),
                        ],
                        stops: const [0.45, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.h3Size,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1.15,
                    ),
                  ),
                  if (hasValidity) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.event_available_rounded,
                            size: 16, color: WebColors.primaryGoldLight),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            campaign.startDate.isNotEmpty &&
                                    campaign.endDate.isNotEmpty
                                ? '${campaign.startDate} — ${campaign.endDate}'
                                : (campaign.startDate.isNotEmpty
                                    ? campaign.startDate
                                    : campaign.endDate),
                            style: TextStyle(
                              color: WebColors.textSecondary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              NavigationHandler.globalGoTo(campaign.url),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WebColors.primaryGold,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 6,
                            shadowColor:
                                WebColors.primaryGold.withOpacity(0.4),
                          ),
                          child: const Text('ŞİMDİ İNCELE',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      GestureDetector(
                        onTap: () => TiyatrolDeeplinkService.shareShow(
                            id: campaign.id, name: campaign.title),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.15)),
                          ),
                          child: const Icon(Icons.share_outlined,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignSideList extends StatelessWidget {
  final List<Campaign> campaigns;
  final int selectedIndex;
  final void Function(int index) onSelect;

  const _CampaignSideList({
    required this.campaigns,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < campaigns.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _CampaignSideCard(
                campaign: campaigns[i],
                isSelected: i == selectedIndex,
                onTap: () => onSelect(i),
              ),
            ),
        ],
      );
}

class _CampaignSideCard extends StatelessWidget {
  final Campaign campaign;
  final bool isSelected;
  final VoidCallback onTap;

  const _CampaignSideCard({
    required this.campaign,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? WebColors.primaryGold.withOpacity(0.12)
                : WebColors.darkBlueSurface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(10),
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(20),
            ),
            border: Border.all(
              color: isSelected
                  ? WebColors.primaryGold.withOpacity(0.6)
                  : Colors.white.withOpacity(0.08),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: OptimizedCachedImage(
                  imageUrl: campaign.imageUrl,
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                  borderRadius: 12,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      campaign.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isSelected
                            ? WebColors.primaryGoldLight
                            : Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    if (campaign.endDate.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Son: ${campaign.endDate}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: WebColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.play_arrow_rounded
                    : Icons.arrow_forward_ios_rounded,
                size: isSelected ? 20 : 14,
                color: isSelected
                    ? WebColors.primaryGoldLight
                    : Colors.white38,
              ),
            ],
          ),
        ),
      );
}

class _CampaignsEmptyState extends StatelessWidget {
  const _CampaignsEmptyState();

  @override
  Widget build(final BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_offer_outlined,
                  size: 60, color: WebColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Aktif kampanya bulunamadı.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
}
