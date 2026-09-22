import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../core/services/deeplink/deeplink_service.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/button/back_button_glassmorphism.dart';
import '../../../../../shared/widgets/footers/footer.dart';
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
// gerekçe. Bu yüzden geri/kapatma butonu da `BasePageWrapper`'ın header'ından
// gelmiyor — kullanıcı önceden bu sayfada gerçekten sıkışıp kalıyordu (hiçbir
// kapatma/geri kontrolü yoktu), aşağıda sağ üstte SABİT (scroll ile
// kaybolmayan) bir kapatma butonu eklendi.
//
// Kırık görsel kök nedeni: kod tarafında bir hata YOK. `campaignsProvider`
// zaten başlığı/görseli tamamen boş taslak kayıtları eleye (bkz.
// `campaign_provider.dart`), `CampaignModel`/mapper alanları birebir
// doğru taşıyor, ve buradaki her görsel zaten `OptimizedCachedImage`
// üzerinden gösteriliyor — o widget geçersiz/boş bir `imageUrl` veya ağ
// hatası durumunda ZATEN ham `Colors.grey` DEĞİL, aktif temadan
// (`Theme.of(context).colorScheme`) türetilmiş şık bir yer tutucu gösteriyor
// (bkz. `optimized_cached_image.dart`). Web'de bu tema `WebTheme.darkTheme`
// olduğu için (`main.dart`), o yer tutucu zaten bu sayfanın lacivert/altın
// paletiyle uyumlu çıkıyor — ayrıca bir düzeltme gerekmiyor. Ekran
// görüntüsündeki kırık kartlar, geçilen filtreden sağ çıkmış ama Firestore'da
// GEÇERSİZ/ölü bir `imageUrl` değeri taşıyan (boş değil, ama çalışmayan bir
// bağlantıya sahip) kampanya kayıtlarından kaynaklanıyor — bu bir VERİ
// sorunu, kodda düzeltilecek bir şey yok; sahte bir görsel de eklenmedi.
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
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: context.isLargeDesktop ? 1360 : 1180),
                child: Consumer(
                  builder: (final context, final ref, final _) {
                    final campaignsAsync = ref.watch(campaignsProvider);
                    return campaignsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              WebColors.primaryGold),
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
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.huge),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xxl),
                              child: SectionHeader(
                                title: 'Avantajlar',
                                subtitle: '${campaigns.length} aktif kampanya',
                                titleColor: Colors.white,
                                accentColor: WebColors.primaryGold,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.xxl),
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
                                        const SizedBox(
                                            height: AppSpacing.xxl),
                                        sideList,
                                      ],
                                    );

                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(flex: 3, child: featured),
                                      const SizedBox(width: AppSpacing.xxl),
                                      Expanded(flex: 2, child: sideList),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: AppSpacing.massive),
                            const Footer(),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // 🚪 Sabit kapatma butonu — scroll pozisyonundan bağımsız,
            // her zaman sağ üstte. Kullanıcının bu sayfada sıkışıp kalmasını
            // önleyen tek gerçek çıkış kontrolü.
            Positioned(
              top: AppSpacing.xl,
              right: AppSpacing.xl,
              child: Semantics(
                label: 'Kapat',
                button: true,
                child: GlassmorphismIconButton(
                  icon: Icons.close_rounded,
                  backgroundColor: WebColors.primaryGold,
                  iconColor: WebColors.whiteText,
                  onPressed: () => NavigationHandler.smartGoBack(context),
                ),
              ),
            ),
          ],
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
        borderRadius: AppRadius.asymLg,
        border: Border.all(color: WebColors.primaryGold.withOpacity(0.22)),
        boxShadow: AppShadows.level4(Colors.black),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.asymLg,
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
              padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, AppSpacing.sm,
                  AppSpacing.xxl, AppSpacing.xxl),
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
                    const SizedBox(height: AppSpacing.sm + 2),
                    Row(
                      children: [
                        Icon(Icons.event_available_rounded,
                            size: 16, color: WebColors.primaryGoldLight),
                        const SizedBox(width: AppSpacing.sm),
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
                  const SizedBox(height: AppSpacing.xxl),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              NavigationHandler.globalGoTo(campaign.url),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: WebColors.primaryGold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.xl),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm)),
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
                      const SizedBox(width: AppSpacing.md),
                      GestureDetector(
                        onTap: () => TiyatrolDeeplinkService.shareShow(
                            id: campaign.id, name: campaign.title),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius:
                                BorderRadius.circular(AppRadius.sm),
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
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: _CampaignSideCard(
                campaign: campaigns[i],
                isSelected: i == selectedIndex,
                onTap: () => onSelect(i),
              ),
            ),
        ],
      );
}

/// Tıklanabilir yan liste kartı. Öncesinde sadece seçili durumda renk
/// değiştiriyordu, hover'da hiçbir geri bildirim yoktu. Artık
/// `theatre_show_card.dart`'taki teknikle aynı ailede — hover'da hafif
/// kalkma (`translationValues`) + gölge seviyesi artışı — gerçek bir
/// mikro-etkileşim var.
class _CampaignSideCard extends StatefulWidget {
  final Campaign campaign;
  final bool isSelected;
  final VoidCallback onTap;

  const _CampaignSideCard({
    required this.campaign,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CampaignSideCard> createState() => _CampaignSideCardState();
}

class _CampaignSideCardState extends State<_CampaignSideCard> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) {
    final campaign = widget.campaign;
    final isSelected = widget.isSelected;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (final _) => setState(() => _hovered = true),
      onExit: (final _) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          transform:
              Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? WebColors.primaryGold.withOpacity(0.12)
                : WebColors.darkBlueSurface,
            borderRadius: AppRadius.asymSm,
            border: Border.all(
              color: isSelected
                  ? WebColors.primaryGold.withOpacity(0.6)
                  : (_hovered
                      ? WebColors.primaryGold.withOpacity(0.3)
                      : Colors.white.withOpacity(0.08)),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: _hovered || isSelected
                ? AppShadows.level3(WebColors.primaryGold)
                : AppShadows.level1(Colors.black),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                child: OptimizedCachedImage(
                  imageUrl: campaign.imageUrl,
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                  borderRadius: AppRadius.sm,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
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
                      const SizedBox(height: AppSpacing.xs),
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
      ),
    );
  }
}

class _CampaignsEmptyState extends StatelessWidget {
  const _CampaignsEmptyState();

  @override
  Widget build(final BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.massive),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_offer_outlined,
                  size: 60, color: WebColors.textSecondary),
              const SizedBox(height: AppSpacing.lg),
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
