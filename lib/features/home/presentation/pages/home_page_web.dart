import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/util/comminucation_actions.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/global_error_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../discovery/presentation/providers/nearby_events_provider.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../../../tickets/presentation/providers/my_ticket_provider.dart';
import '../../../users/presentation/providers/user_provider.dart';
import '../widgets/web/home_campaign_rail.dart';
import '../widgets/web/home_category_strip.dart';
import '../widgets/web/home_newsletter_band.dart';
import '../widgets/web/home_promo_banner.dart';
import '../widgets/web/home_show_grid.dart';
import '../widgets/web/home_stage_rail.dart';
import '../widgets/web/home_trending_chips.dart';
import '../widgets/web/reveal_on_scroll.dart';

/// 🖥️ ANA SAYFA — MASAÜSTÜ/WEB
///
/// `home_page_mobile.dart`'ın (`HomePage` in `home_page_mobile.dart`) AYNI
/// İÇERİK/BÖLÜM SIRASINI taşır — Vitrin, Kategoriler, Keşfet, Mekanlar,
/// Günün Fırsatı, Hızlı Erişim, Şu An Popüler, Özel Fırsatlar, kapanış
/// alıntısı — sadece piksel piksel büyütülmüş hali değil: her bölüm web'e
/// özgü bir bileşimle (grid/rail, hover durumları, asimetrik köşeler)
/// yeniden çizildi. "Çam & Mercan" (Pine & Coral) tasarım sistemini kullanır.
///
/// KASITLI OLARAK `BasePageWrapper` KULLANMIYOR: o wrapper mobil uygulama
/// çatısı içindir (geri tuşu başlığı, "yukarı kaydır" FAB'ı, pull-to-refresh,
/// parçacık arka planı) — bunların hiçbiri bir web sitesinde olmaz ve
/// sayfayı "Android uygulaması gibi" gösteren asıl sebep buydu. Üst
/// navigasyon zaten `WebTopNavigationBar` tarafından sağlanıyor; bu sayfa
/// sade bir kaydırılabilir içerik alanından ibaret.
///
/// Aynı Riverpod sağlayıcılarını okur (campaignsProvider, showsProvider,
/// stagesProvider) — sahte veri yok. Kategoriler/Günün Fırsatı/Popüler/
/// Bülten bölümleri mobil tarafta da sabit/dekoratif içerik taşıyor (bkz.
/// ilgili widget dosyalarındaki yorumlar) — aynı içerik birebir taşındı.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _openSearch() => NavigationHandler.goToSearch(context);

  void _goToTickets() {
    if (ref.read(isLoggedInProvider)) {
      final uid = ref.read(currentUserIdProvider);
      NavigationHandler.goToMyTickets(context, uid ?? '');
    } else {
      NavigationHandler.goToLogin(context);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final campaignState = ref.watch(campaignsProvider);
    // Hiçbir oyun tamamen gizlenmiyor: önce takviminde gelecek etkinliği
    // olan ("aktif") oyunlar, ardından (yer kaldıysa) aktif olmayanlar —
    // aktif oyun sayısı azsa liste yine de boş/yarım görünmüyor.
    final showState = ref.watch(showsActiveFirstProvider(true));
    final stageState = ref.watch(stagesProvider(isLimit: true));

    final bool isLoading =
        campaignState.isLoading || showState.isLoading || stageState.isLoading;
    final bool hasError =
        campaignState.hasError || showState.hasError || stageState.hasError;

    final campaigns = campaignState.value ?? const [];
    final shows = showState.value ?? const [];
    final stages = stageState.value ?? const [];

    // "Hızlı Erişim" panelinin gerçek verisi — sayfanın geri kalanının
    // loading/error durumunu ETKİLEMEZ (ikincil, kişisel bir panel; hesap
    // verisi geç gelse ya da hata verse bile ana içerik akmaya devam eder).
    final loggedIn = ref.watch(isLoggedInProvider);
    final uid = ref.watch(currentUserIdProvider);
    final ticketsAsync = uid == null
        ? const AsyncValue<List<DetailedTicket>>.data(<DetailedTicket>[])
        : ref.watch(myTicketsProvider(uid));
    final userAsync = ref.watch(userProfileProvider);
    final nearbyAsync = ref.watch(upcomingNearbyEventsProvider);

    final bool showLoadingState = isLoading && showState.value == null;

    return ColoredBox(
      color: WebColors.darkBlueBackground,
      child: hasError
          ? GlobalErrorWidget(
              isFullPage: false,
              title: AppLocalizations.of(context)!.homeErrorTitleWeb,
              message: AppLocalizations.of(context)!.homeErrorMessageWeb,
              onRetry: () {
                ref.invalidate(campaignsProvider);
                ref.invalidate(showsActiveFirstProvider);
                ref.invalidate(stagesProvider);
              },
            )
          : showLoadingState
              ? _WebLoadingState(enabled: showLoadingState)
              : SingleChildScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeroBand(
                        onSearchTap: _openSearch,
                        onDiscoverTap: () =>
                            NavigationHandler.goToDiscover(context),
                        onNearbyTap: () => NavigationHandler.goToNearby(context),
                        onFeaturedShowTap: (final show) =>
                            NavigationHandler.goToShow(
                                context, show.id, show.name),
                        shows: shows,
                        stages: stages,
                      ),
                      // 1. Öne Çıkanlar / Vitrin (mobildeki StoryCircles'ın
                      // web karşılığı — aynı SectionHeader kicker/title)
                      if (campaigns.isNotEmpty)
                        RevealOnScroll(
                          child: _Section(
                            kicker: AppLocalizations.of(context)!
                                .homeFeaturedKicker,
                            title: AppLocalizations.of(context)!
                                .homeFeaturedTitle,
                            child: HomeCampaignRail(
                              campaigns: campaigns,
                              onCampaignTap: (final index) =>
                                  NavigationHandler.goToCampaigns(context,
                                      index: index),
                            ),
                          ),
                        ),
                      // 2. Kategoriler / Sanatın Renkleri (mobildeki
                      // CategoryGrid'in aynısı — /discover?category=... 'a gider)
                      RevealOnScroll(
                        delay: const Duration(milliseconds: 60),
                        child: _Section(
                          kicker:
                              AppLocalizations.of(context)!.homeCategoriesKicker,
                          title:
                              AppLocalizations.of(context)!.homeCategoriesTitle,
                          child: HomeCategoryStrip(
                            onCategoryTap: (final category) =>
                                NavigationHandler.goToDiscoverWithCategory(
                                    context, category),
                          ),
                        ),
                      ),
                      // 3. Keşfet / Sana Özel Seçkiler (mobildeki
                      // ShowCollage'ın web karşılığı)
                      RevealOnScroll(
                        delay: const Duration(milliseconds: 80),
                        child: _Section(
                          kicker: AppLocalizations.of(context)!.homeDiscoverKicker,
                          title: AppLocalizations.of(context)!.homeCuratedForYou,
                          trailingLabel: shows.isEmpty
                              ? null
                              : AppLocalizations.of(context)!.homeSeeAll,
                          onTrailingTap: () =>
                              NavigationHandler.goToDiscover(context),
                          child: shows.isEmpty
                              ? _EmptyHint(
                                  text: AppLocalizations.of(context)!
                                      .homeEmptyShowsHint)
                              : HomeShowGrid(
                                  shows: shows,
                                  onShowTap: (final show) =>
                                      NavigationHandler.goToShow(
                                          context, show.id, show.name),
                                ),
                        ),
                      ),
                      // 4. Mekanlar / Şehrin Sahneleri (mobildeki
                      // StageCarousel'in web karşılığı)
                      if (stages.isNotEmpty)
                        RevealOnScroll(
                          delay: const Duration(milliseconds: 80),
                          child: _Section(
                            kicker:
                                AppLocalizations.of(context)!.homeVenuesKicker,
                            title:
                                AppLocalizations.of(context)!.homeVenuesSubtitle,
                            child: HomeStageRail(
                              stages: stages,
                              onStageTap: (final stage) =>
                                  NavigationHandler.goToStage(
                                      context, stage.id, stage.name),
                            ),
                          ),
                        ),
                      // 5. Günün Fırsatı (mobildeki TicketStubCard'ın
                      // web karşılığı)
                      RevealOnScroll(
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: context.responsive(
                                  mobile: 44.0, tablet: 52.0, desktop: 60.0)),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1400),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: _sectionPad(context)),
                                child: HomePromoBanner(
                                  campaign: campaigns.isNotEmpty
                                      ? campaigns.first
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 6. Hızlı Erişim — gerçek hesap panosu (Biletlerim/
                      // Favorilerim/Yaklaşan Etkinlikler/Ayarlar), gerçek
                      // sayılarla. Eskiden burada sabit metinli 4 kutu vardı
                      // ve "Takvim" kartı hiçbir yere gitmiyordu ("yakında"
                      // etiketiyle tıklanamaz duruyordu) — artık her kart
                      // gerçek veriye bağlı ve gerçekten çalışıyor.
                      RevealOnScroll(
                        child: _Section(
                          kicker: AppLocalizations.of(context)!.homeAccountKicker,
                          title: AppLocalizations.of(context)!
                              .homeAccountSectionTitle,
                          child: _QuickLinksBand(
                            loggedIn: loggedIn,
                            upcomingTicketCount: ticketsAsync.value
                                    ?.where((final t) => !t.isPast)
                                    .length ??
                                0,
                            nextTicketShowName: _firstUpcomingShowName(
                                ticketsAsync.value),
                            favoritesCount: userAsync.value == null
                                ? 0
                                : userAsync.value!.favoriteShows.length +
                                    userAsync.value!.favoriteStages.length +
                                    userAsync.value!.favoritePlayers.length,
                            nearbyEventCount: nearbyAsync.value?.length ?? 0,
                            onTicketsTap: _goToTickets,
                            onFavoritesTap: loggedIn
                                ? () => NavigationHandler.goToFavorites(context)
                                : () => NavigationHandler.goToLogin(context),
                            onNearbyTap: () =>
                                NavigationHandler.goToNearby(context),
                            onSettingsTap: () =>
                                NavigationHandler.goToSettings(context),
                          ),
                        ),
                      ),
                      // 7. Şu An Popüler (mobildeki TrendingNowSection'ın aynısı)
                      RevealOnScroll(
                        child: _Section(
                          kicker: AppLocalizations.of(context)!.homeTrendingKicker,
                          title: AppLocalizations.of(context)!.homeTrendingTitle,
                          child: const HomeTrendingChips(),
                        ),
                      ),
                      // 8. Özel Fırsatlar (mobildeki NewsletterSubscribe'ın
                      // web karşılığı)
                      RevealOnScroll(
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: context.responsive(
                                  mobile: 44.0, tablet: 52.0, desktop: 60.0)),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1400),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: _sectionPad(context)),
                                child: const HomeNewsletterBand(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const RevealOnScroll(child: _ClosingQuoteBand()),
                      const Footer(),
                    ],
                  ),
                ),
    );
  }
}

/// Gerçek içerik (hero bandı + bölüm listesi) yüklenene kadar gösterilen
/// iskelet — `skeletonizer` gerçek widget ağacını otomatik olarak
/// parıldayan (shimmer) bir yer tutucuya çevirir, bu yüzden burada gerçek
/// bölümleri birebir kopyalamıyoruz: yalnızca hero + birkaç bölüm satırının
/// kaba oranlarında birkaç köşeleri yuvarlatılmış `Container` yeterli.
class _WebLoadingState extends StatelessWidget {
  final bool enabled;

  const _WebLoadingState({this.enabled = true});

  @override
  Widget build(final BuildContext context) => Skeletonizer(
        enabled: enabled,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero bandı yaklaşıklaması — gerçek `_HeroBand` ile aynı
              // kaba yerleşim: solda metin bloğu, sağda vitrin kartı.
              Container(
                width: double.infinity,
                height: context.responsive(
                    mobile: 480.0, tablet: 520.0, desktop: 560.0),
                color: WebColors.veryDarkBlue,
                padding: EdgeInsets.fromLTRB(
                    _sectionPad(context), 100, _sectionPad(context), 40),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _bar(width: 160, height: 14),
                          const SizedBox(height: 20),
                          _bar(width: 320, height: 34),
                          const SizedBox(height: 10),
                          _bar(width: 260, height: 34),
                          const SizedBox(height: 20),
                          _bar(width: 380, height: 16),
                          const SizedBox(height: 6),
                          _bar(width: 300, height: 16),
                          const SizedBox(height: 26),
                          _bar(width: 340, height: 52, radius: 12),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              _bar(width: 150, height: 46, radius: 18),
                              const SizedBox(width: 16),
                              _bar(width: 150, height: 46, radius: 18),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 56),
                    Expanded(
                      flex: 4,
                      child:
                          _bar(width: double.infinity, height: 380, radius: 24),
                    ),
                  ],
                ),
              ),
              // Bölüm yaklaşıklamaları — kicker + başlık + kart sırası
              // (gerçek `_Section` + `HomeShowGrid`/`HomeStageRail` gibi
              // grid/rail bölümlerinin kaba biçimi).
              _sectionPlaceholder(context, cardCount: 4),
              _sectionPlaceholder(context, cardCount: 3),
            ],
          ),
        ),
      );

  Widget _sectionPlaceholder(final BuildContext context,
          {final int cardCount = 4}) =>
      Padding(
        padding: EdgeInsets.fromLTRB(
            _sectionPad(context), 48, _sectionPad(context), 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _bar(width: 100, height: 12),
            const SizedBox(height: 10),
            _bar(width: 220, height: 26),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: Row(
                children: List.generate(
                  cardCount,
                  (final i) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: i == cardCount - 1 ? 0 : 16),
                      child: _bar(
                          width: double.infinity,
                          height: double.infinity,
                          radius: 20),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _bar(
          {required final double width,
          required final double height,
          final double radius = 8}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: WebColors.darkBlueSurface,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// PAYLAŞILAN KÜÇÜK YARDIMCILAR
// ═══════════════════════════════════════════════════════════════

const BorderRadius _kAsymLg = AppRadius.asymLg;

const BorderRadius _kAsymSm = AppRadius.asymSm;

double _sectionPad(final BuildContext context) => context.responsive(
      mobile: 20.0,
      tablet: 40.0,
      desktop: 64.0,
      largeDesktop: 96.0,
    );

/// "Hızlı Erişim" panosundaki Biletlerim kartı için: kullanıcının en yakın
/// GELECEK biletinin oyun adı (varsa) — sahte bir tarih/oyun uydurmak
/// yerine, `myTicketsProvider`'ın zaten getirdiği gerçek `DetailedTicket`
/// listesinden tarihe göre en yakın olanı bulur.
String? _firstUpcomingShowName(final List<DetailedTicket>? tickets) {
  if (tickets == null) return null;
  DetailedTicket? soonest;
  DateTime? soonestDate;
  for (final ticket in tickets) {
    if (ticket.isPast || ticket.show == null || ticket.event == null)
      continue;
    final date = DateFormatter.parseDateString(ticket.event!.date);
    if (date == null) continue;
    if (soonestDate == null || date.isBefore(soonestDate)) {
      soonest = ticket;
      soonestDate = date;
    }
  }
  return soonest?.show?.name;
}

// ═══════════════════════════════════════════════════════════════
// BÖLÜM (SECTION) ÇATISI
// ═══════════════════════════════════════════════════════════════

class _Section extends StatelessWidget {
  final String kicker;
  final String title;
  final Widget child;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  const _Section({
    required this.kicker,
    required this.title,
    required this.child,
    this.trailingLabel,
    this.onTrailingTap,
  });

  @override
  Widget build(final BuildContext context) => Padding(
        padding: EdgeInsets.only(
            top: context.responsive(mobile: 44.0, tablet: 52.0, desktop: 60.0)),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: _sectionPad(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              kicker,
                              style: const TextStyle(
                                color: WebColors.secondaryAccentLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: context.textTheme.headlineMedium?.copyWith(
                                color: WebColors.whiteText,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (trailingLabel != null)
                        _TextLink(label: trailingLabel!, onTap: onTrailingTap),
                    ],
                  ),
                  SizedBox(
                      height: context.responsive(
                          mobile: 20.0, tablet: 26.0, desktop: 30.0)),
                  child,
                ],
              ),
            ),
          ),
        ),
      );
}

class _TextLink extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;

  const _TextLink({required this.label, this.onTap});

  @override
  State<_TextLink> createState() => _TextLinkState();
}

class _TextLinkState extends State<_TextLink> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (final _) => setState(() => _hovered = true),
        onExit: (final _) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: _hovered ? 1 : 0.75,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: WebColors.primaryGoldLight,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedSlide(
                  duration: const Duration(milliseconds: 180),
                  offset: Offset(_hovered ? 0.2 : 0, 0),
                  child: const Icon(Icons.arrow_forward_rounded,
                      size: 15, color: WebColors.primaryGoldLight),
                ),
              ],
            ),
          ),
        ),
      );
}

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(final BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: WebColors.darkBlueSurface,
          borderRadius: _kAsymLg,
          border: Border.all(color: WebColors.darkBlueAccent),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: WebColors.textSecondary, fontSize: 15),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// HERO BANDI
// ═══════════════════════════════════════════════════════════════
//
// Kompozisyon dili bir referans ekran görüntüsünden (lüks bir emlak
// mikrositesinin hero'su) ödünç alındı: tam kare gerçek bir fotoğraf
// zemini, sol üstte marka rozeti, solda editoryal başlık + CTA, sağda
// gerçek "sıradaki oyun" vitrini, fotoğrafın üzerine iğnelenmiş bir
// "hotspot" işaretleyici, kenarlarda ince sayfalama noktaları/sosyal
// ikonlar/mini navigasyon. RENK PALETİ değişmedi — hâlâ saf "Kırmızı &
// Siyah" (Crimson Noir), referansın kendi renklerini KOPYALAMADIK.
//
// ÖNEMLİ: hotspot işaretleyici ve sayfalama noktaları SÜS DEĞİL —
// hotspot açıldığında `_pickFeaturedShows` ile hesaplanan GERÇEK
// "sıradaki oyun" adı/tarihi/sahnesini gösterir (uydurma bir başlık/
// özellik yok); noktalar da yalnızca takvimde birden fazla gerçek
// yaklaşan oyun varsa görünür ve dokunulduğunda o oyunu seçer.
class _HeroBand extends ConsumerStatefulWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onDiscoverTap;
  final VoidCallback onNearbyTap;
  final ValueChanged<Show> onFeaturedShowTap;
  final List<Show> shows;
  final List<Stage> stages;

  const _HeroBand({
    required this.onSearchTap,
    required this.onDiscoverTap,
    required this.onNearbyTap,
    required this.onFeaturedShowTap,
    required this.shows,
    required this.stages,
  });

  @override
  ConsumerState<_HeroBand> createState() => _HeroBandState();
}

class _HeroBandState extends ConsumerState<_HeroBand>
    with TickerProviderStateMixin {
  late final AnimationController _glowController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);

  // Sayfa ilk açıldığında bir kereye mahsus çalışan giriş animasyonu —
  // hero içeriği önceden statikti, artık sol/sağ panel hafif kademeli
  // (staggered) fade+slide ile beliriyor.
  late final AnimationController _entranceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  // Sayfalama noktalarıyla seçilen "sıradaki oyun" — hem sağdaki gerçek
  // vitrin kartı hem de fotoğraf üzerindeki hotspot AYNI seçimi paylaşır.
  int _selectedFeaturedIndex = 0;

  @override
  void dispose() {
    _glowController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Animation<double> _fade(final double start) => CurvedAnimation(
        parent: _entranceController,
        curve: Interval(start, 1.0, curve: Curves.easeOut),
      );

  void _selectFeatured(final int index) {
    if (index != _selectedFeaturedIndex)
      setState(() => _selectedFeaturedIndex = index);
  }

  @override
  Widget build(final BuildContext context) {
    // Firestore okumasını sınırlı tutmak için en fazla ilk 12 oyunun
    // etkinliklerine bakılır — `widget.shows` zaten `showsActiveFirstProvider`
    // ile aktif oyunlar önde olacak şekilde sıralı ve `isLimit: true` ile
    // üst sınırlı bir listeden geliyor. Bu hesap eskiden ayrı bir
    // `_HeroFeaturedPanel` (ConsumerWidget) içindeydi; artık burada,
    // çünkü sayfalama noktaları ile öne çıkan panel/hotspot AYNI seçili
    // oyunu paylaşmak zorunda.
    final candidates =
        widget.shows.length > 12 ? widget.shows.sublist(0, 12) : widget.shows;
    // Show <-> Event ilişkisi iki bağımsız yönde tutuluyor (`Show.eventsId`
    // ve `Event.showId`) — bu panel önceden SADECE `Show.eventsId` dizisini
    // kullanıyordu, `Event.showId` üzerinden doğrudan bağlı (ama dizide
    // listelenmeyen) gerçek bir etkinliği asla göremiyordu. Sonuç: hiçbir
    // adayın dizisi dolu değilse, gerçek bir gelecek etkinliği olan bir
    // oyun varken bile "sıradaki oyun" sessizce ilk (etkinliksiz) oyuna
    // düşüyordu. Artık `show_provider.dart`'taki
    // `_activeShowIdsFromEvents` ile AYNI mantıkla iki kaynak birleştirilir.
    final candidateIds = candidates.map((final s) => s.id).toList();
    final eventIdsFromArrays = candidates
        .expand((final s) => s.eventsId)
        .where((final id) => id.isNotEmpty)
        .toSet()
        .toList();
    final eventsByShowIdAsync = ref.watch(eventsByShowIdsProvider(candidateIds));
    final eventsByArrayIdAsync = eventIdsFromArrays.isEmpty
        ? const AsyncValue<List<Event>>.data(<Event>[])
        : ref.watch(eventsByIdsProvider(eventIdsFromArrays));
    // Riverpod 3'te `AsyncValue.valueOrNull` yok — nullable `.value` kullan.
    final mergedEventsById = <String, Event>{
      for (final e in eventsByArrayIdAsync.value ?? const <Event>[]) e.id: e,
      for (final e in eventsByShowIdAsync.value ?? const <Event>[]) e.id: e,
    };
    final featuredEntries = _pickFeaturedShows(
        candidates, mergedEventsById.values.toList(), widget.stages);
    final bool hasFeatured = featuredEntries.isNotEmpty;
    // Gerçek "aktif oyun" sayısı: takviminde gelecek tarihli en az bir
    // etkinliği olan DİSTİNCT oyun sayısı — `_pickFeaturedShows`'un
    // `earliestByShow` ile aynı mantık, sadece burada sayıya indirgeniyor.
    final DateTime _now = DateTime.now();
    final Set<String> candidateIdSet = candidateIds.toSet();
    final int activeShowCount = mergedEventsById.values
        .where((final e) =>
            e.showId.isNotEmpty && candidateIdSet.contains(e.showId))
        .where((final e) {
          final date = DateFormatter.parseDateString(e.date);
          return date != null && date.isAfter(_now);
        })
        .map((final e) => e.showId)
        .toSet()
        .length;
    final int selectedIndex = featuredEntries.isEmpty
        ? 0
        : _selectedFeaturedIndex.clamp(0, featuredEntries.length - 1);

    // Kenar süslemeleri (sayfalama noktaları / sosyal ikonlar / mini nav
    // şeridi) yalnızca geniş masaüstü genişliğinde gösterilir — dar/mobil
    // düzende sol/sağ panel zaten tek sütuna dönüyor, kenar unsurları
    // için yer yok.
    final bool wide = context.screenWidth >= 980;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(color: WebColors.veryDarkBlue),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Tam kare, gerçek bir fotoğraf zemini — düz gradyan yerine
              // gerçek bir sahne/perde fotoğrafı; üzerine metnin her
              // zaman okunur kalmasını sağlayan koyu bir "scrim"
              // bindirilmiş (bkz. `_HeroBackdropPhoto`).
              const Positioned.fill(child: _HeroBackdropPhoto()),
              // Sahne ışığı motifi #1 — sağ üst, ana vurgu
              Positioned(
                top: -140,
                right: -80,
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (final context, final child) => Opacity(
                    opacity: 0.10 + _glowController.value * 0.05,
                    child: child,
                  ),
                  child: Container(
                    width: 420,
                    height: 420,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [WebColors.primaryGold, Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
              // Sahne ışığı motifi #2 — sol alt, daha soluk ikincil vurgu
              Positioned(
                bottom: -120,
                left: -100,
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (final context, final child) => Opacity(
                    opacity: 0.13 - _glowController.value * 0.04,
                    child: child,
                  ),
                  child: Container(
                    width: 340,
                    height: 340,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          WebColors.secondaryAccent,
                          Colors.transparent
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Sol üst: dairesel logo rozeti + serif kelime işareti —
              // referans mikrositenin kalıcı marka köşesi. Her genişlikte
              // görünür (kenar süslemelerinin aksine).
              Positioned(
                top: context.responsive(
                    mobile: 24.0, tablet: 28.0, desktop: 32.0),
                left: _sectionPad(context),
                child: const _HeroBrandMark(),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  _sectionPad(context),
                  context.responsive(
                      mobile: 84.0,
                      tablet: 100.0,
                      desktop: 112.0,
                      largeDesktop: 120.0),
                  _sectionPad(context),
                  context.responsive(
                      mobile: 36.0, tablet: 40.0, desktop: 48.0),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: LayoutBuilder(
                      builder: (final context, final constraints) {
                        final bool innerWide = constraints.maxWidth >= 980;
                        final left = FadeTransition(
                          opacity: _fade(0.0),
                          child: SlideTransition(
                            position: _fade(0.0).drive(Tween(
                                begin: const Offset(0, 0.06),
                                end: Offset.zero)),
                            child: _HeroCopy(
                              onSearchTap: widget.onSearchTap,
                              onDiscoverTap: widget.onDiscoverTap,
                              onNearbyTap: widget.onNearbyTap,
                              // `widget.shows.length`, discovery_page.dart'taki
                              // aynı hatanın bir başka örneğiydi: TÜM (aktif +
                              // aktif olmayan) oyun sayısını "aktif" diye
                              // etiketliyordu. Gerçek aktif sayı aşağıda.
                              showCount: activeShowCount,
                              stageCount: widget.stages.length,
                            ),
                          ),
                        );

                        if (!hasFeatured) return left;

                        final right = FadeTransition(
                          opacity: _fade(0.18),
                          child: SlideTransition(
                            position: _fade(0.18).drive(Tween(
                                begin: const Offset(0, 0.06),
                                end: Offset.zero)),
                            child: _HeroFeaturedPanel(
                              entries: featuredEntries,
                              selectedIndex: selectedIndex,
                              onTap: widget.onFeaturedShowTap,
                            ),
                          ),
                        );

                        if (!innerWide)
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              left,
                              const SizedBox(height: 28),
                              right,
                            ],
                          );

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: left),
                            const SizedBox(width: 56),
                            Expanded(flex: 4, child: right),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Sol kenar: sayfalama noktaları — YALNIZCA takvimde birden
              // fazla gerçek "sıradaki oyun" varsa görünür; dokunulunca o
              // oyunu hem sağdaki karta hem hotspot'a yansıtır. Tek oyun
              // varsa (ya da hiç yoksa) noktalar tamamen gizlenir — asla
              // "tıklanabilir gibi duran ama hiçbir şey yapmayan" süs
              // olarak gösterilmez.
              if (wide && featuredEntries.length > 1)
                Positioned(
                  left: _sectionPad(context) * 0.32,
                  top: 0,
                  bottom: 56,
                  child: Center(
                    child: _HeroPagerDots(
                      count: featuredEntries.length,
                      selectedIndex: selectedIndex,
                      onSelect: _selectFeatured,
                    ),
                  ),
                ),
              // Sol alt: gerçek sosyal medya hesaplarını açan küçük
              // ikonlar (`TiyatrolCommunicationActions` — uygulamanın
              // başka yerlerde de kullandığı gerçek Instagram/Facebook
              // bağlantıları, burada uydurulmuş bir şey yok).
              if (wide)
                Positioned(
                  left: _sectionPad(context),
                  bottom: 22,
                  child: const _HeroSocialRail(),
                ),
              // Sağ kenar: gerçek sayfalara giden dikey mini navigasyon
              // şeridi — arama/keşfet/yakınımdakiler, üçü de zaten çalışan
              // gerçek aksiyonlar (aynı callback'ler `_HeroCopy`'nin CTA
              // düğmelerinde de kullanılıyor).
              if (wide)
                Positioned(
                  right: _sectionPad(context) * 0.28,
                  top: 0,
                  bottom: 56,
                  child: Center(
                    child: _HeroSideNavRail(
                      onSearchTap: widget.onSearchTap,
                      onDiscoverTap: widget.onDiscoverTap,
                      onNearbyTap: widget.onNearbyTap,
                    ),
                  ),
                ),
            ],
          ),
          // Sahnedeki oyunların isimlerinin sessizce kaydığı ince bir
          // şerit — kutulu istatistik panelinin yerini alan çok daha
          // sakin bir "neler oynuyor" ipucu (bkz. `landing/index.html`'deki
          // `.marquee` bölümü — aynı dil, farklı görsel ağırlık).
          _HeroShowsMarquee(
              names: widget.shows.map((final s) => s.name).toList()),
        ],
      ),
    );
  }
}

/// Hero fotoğraf zemini — tema/atmosfer için gerçek bir stok fotoğraf
/// (Unsplash direkt görsel bağlantısı, `home_promo_banner.dart`'taki
/// hotlink deseniyle AYNI). Görsel yüklenemezse (ağ engeli, ölü bağlantı
/// vb.) sessizce markanın koyu zemin rengine düşer — hero hiçbir zaman
/// kırık bir görselle bozuk görünmez. Üzerine, metnin her genişlikte
/// okunur kalmasını garanti eden çift yönlü (yatay + dikey) koyu bir
/// "scrim" gradyanı bindirilmiş; fotoğraf sadece atmosferdir, metinle asla
/// yarışmaz.
class _HeroBackdropPhoto extends StatelessWidget {
  const _HeroBackdropPhoto();

  static const String _imageUrl =
      'https://images.unsplash.com/photo-1503095396549-807759245b35'
      '?auto=format&fit=crop&w=1920&q=80';

  @override
  Widget build(final BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (final _, final __, final ___) =>
                const ColoredBox(color: WebColors.darkBlueSurface),
            loadingBuilder: (final _, final child, final progress) =>
                progress == null
                    ? child
                    : const ColoredBox(color: WebColors.darkBlueSurface),
          ),
          // Yatay scrim: metnin durduğu sol taraf koyu, sağ taraf
          // fotoğrafın nefes almasına izin verecek kadar açık.
          // (WebColors.withOpacity(...) const olmadığı için bu DecoratedBox
          // const DEĞİL — ham hex yerine hâlâ sadece WebColors sabitleri
          // kullanılıyor.)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  WebColors.veryDarkBlue.withOpacity(0.96),
                  WebColors.darkBlueBackground.withOpacity(0.82),
                  WebColors.darkBlueBackground.withOpacity(0.42),
                  WebColors.darkBlueBackground.withOpacity(0.6),
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
          ),
          // Dikey scrim: üstte marka rozeti, altta noktalar/marquee için
          // ek okunurluk.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  WebColors.veryDarkBlue.withOpacity(0.55),
                  Colors.transparent,
                  WebColors.veryDarkBlue.withOpacity(0.22),
                  WebColors.veryDarkBlue.withOpacity(0.82),
                ],
                stops: const [0.0, 0.3, 0.62, 1.0],
              ),
            ),
          ),
        ],
      );
}

/// Sol üst marka rozeti — dairesel logo işareti + serif büyük harf kelime
/// işareti + ince alt başlık. `_HeroCopy` içindeki eski kenarlıklı
/// "TİYATROL" rozetinin yerini alıyor (o artık sade bir eyebrow satırına
/// dönüştü) — marka kimliği artık her zaman aynı köşede, sabit.
class _HeroBrandMark extends StatelessWidget {
  const _HeroBrandMark();

  @override
  Widget build(final BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: WebColors.primaryGold.withOpacity(0.85), width: 1.2),
            ),
            child: const Icon(Icons.theater_comedy_rounded,
                size: 16, color: WebColors.primaryGoldLight),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.homeHeroBrandMark,
                style: GoogleFonts.playfairDisplay(
                  color: WebColors.whiteText,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(context)!.homeHeroBrandSubtitle,
                style: TextStyle(
                  color: WebColors.textTertiary.withOpacity(0.85),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.4,
                ),
              ),
            ],
          ),
        ],
      );
}

class _HeroCopy extends StatelessWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onDiscoverTap;
  final VoidCallback onNearbyTap;
  final int showCount;
  final int stageCount;

  const _HeroCopy({
    required this.onSearchTap,
    required this.onDiscoverTap,
    required this.onNearbyTap,
    required this.showCount,
    required this.stageCount,
  });

  /// Eski kutulu istatistik panelinin ("Oyun" / "Sahne" / "Aktif kampanya")
  /// yerini alan, sayıları metne örülü tutan tanıtım cümlesi — ikinci
  /// planda ama hâlâ gerçek. Sayılar 0 ya da henüz bilinmiyorsa (yükleme
  /// sırasında geçici olarak `0` gelebilir) jenerik ama doğru bir cümleye
  /// düşer; asla uydurma bir rakam göstermez.
  String _lede(final BuildContext context) {
    if (showCount > 0 && stageCount > 0)
      return AppLocalizations.of(context)!
          .homeHeroLedeWithCounts(stageCount, showCount);
    return AppLocalizations.of(context)!.homeHeroLedeFallback;
  }

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Eyebrow: referanstaki "küçük büyük harf tanıtım satırı" —
          // marka kimliği artık `_HeroBrandMark`'ta olduğu için burası
          // kenarlıklı bir rozet değil, ince bir çizgi + etiket.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(height: 2, width: 34, color: WebColors.primaryGold),
              const SizedBox(width: 14),
              Text(
                AppLocalizations.of(context)!.homeHeroEyebrow,
                style: const TextStyle(
                  color: WebColors.primaryGoldLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context)!.homeHeroHeadline,
            style: GoogleFonts.playfairDisplay(
              textStyle:
                  (context.textTheme.displaySmall ?? const TextStyle())
                      .copyWith(
                color: WebColors.whiteText,
                fontWeight: FontWeight.w500,
                height: 1.12,
                fontSize: context.responsive(
                    mobile: 30.0,
                    tablet: 36.0,
                    desktop: 42.0,
                    largeDesktop: 46.0),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(
              _lede(context),
              style: const TextStyle(
                color: WebColors.textSecondary,
                fontSize: 14.5,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 26),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: _WebSearchField(onTap: onSearchTap),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _PillButton(
                label: AppLocalizations.of(context)!.homeHeroDiscoverButton,
                icon: Icons.explore_rounded,
                filled: true,
                onTap: onDiscoverTap,
              ),
              _PillButton(
                label: AppLocalizations.of(context)!.homeHeroNearbyButton,
                icon: Icons.near_me_rounded,
                filled: false,
                onTap: onNearbyTap,
              ),
            ],
          ),
        ],
      );
}

/// Sade, "gerçek bir web formu" gibi davranan arama alanı.
///
/// Mobildeki `CustomSearchbar` (parlayan, nabız gibi atan, bulanıklaştırılmış
/// cam pill) buraya BİLEREK taşınmadı — o bileşen mobil uygulama estetiğine
/// ait. `landing/style.css`'teki `.newsletter__form input` ile aynı dilde:
/// düz kenarlık, küçük asimetrik köşe, gölgesiz/parıltısız.
class _WebSearchField extends StatefulWidget {
  final VoidCallback onTap;

  const _WebSearchField({required this.onTap});

  @override
  State<_WebSearchField> createState() => _WebSearchFieldState();
}

class _WebSearchFieldState extends State<_WebSearchField> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (final _) => setState(() => _hovered = true),
        onExit: (final _) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: WebColors.darkBlueSurface,
              borderRadius: _kAsymSm,
              border: Border.all(
                color: WebColors.primaryGold
                    .withOpacity(_hovered ? 0.55 : 0.28),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded,
                    size: 18,
                    color: _hovered
                        ? WebColors.primaryGoldLight
                        : WebColors.textTertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.homeHeroSearchPlaceholder,
                    style: TextStyle(
                      color: WebColors.textSecondary.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.homeHeroSearchLabel,
                  style: TextStyle(
                    color: WebColors.textTertiary
                        .withOpacity(_hovered ? 0.9 : 0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _PillButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> {
  bool _hovered = false;

  static const BorderRadius _radius = BorderRadius.only(
    topLeft: Radius.circular(2),
    topRight: Radius.circular(18),
    bottomLeft: Radius.circular(2),
    bottomRight: Radius.circular(18),
  );

  @override
  Widget build(final BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (final _) => setState(() => _hovered = true),
        onExit: (final _) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            decoration: BoxDecoration(
              gradient: widget.filled ? WebColors.goldButtonGradient : null,
              color: widget.filled ? null : Colors.transparent,
              borderRadius: _radius,
              border: widget.filled
                  ? null
                  : Border.all(
                      color: WebColors.primaryGold
                          .withOpacity(_hovered ? 0.9 : 0.55),
                      width: 1.4),
              // Referanstaki "CTA çevresinde yumuşak sıcak parıltı" —
              // artık sadece hover'da değil, dolu (filled) buton için
              // her zaman hafifçe var; hover'da yoğunlaşıyor.
              boxShadow: widget.filled
                  ? [
                      BoxShadow(
                        color: WebColors.primaryGold
                            .withOpacity(_hovered ? 0.4 : 0.22),
                        blurRadius: _hovered ? 26 : 16,
                        offset: Offset(0, _hovered ? 10 : 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon,
                    size: 18,
                    color: widget.filled
                        ? WebColors.veryDarkBlue
                        : WebColors.primaryGoldLight),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.filled
                        ? WebColors.veryDarkBlue
                        : WebColors.whiteText,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// "Sıradaki oyun" olarak öne çıkarılacak gösterim + (varsa) takvimindeki
/// GELECEK etkinliği + (varsa) o etkinliğin sahnesi.
class _FeaturedShowInfo {
  final Show show;
  final Event? event;
  final Stage? stage;

  const _FeaturedShowInfo({required this.show, this.event, this.stage});
}

/// Bir etkinliğin tarihini `_FeaturedShowCard` / hotspot popover'ının
/// kullandığı ortak "27 Haziran, 20:00" biçimine çevirir. Etkinlik yoksa
/// ya da tarih ayrıştırılamıyorsa `null` döner — asla uydurma bir tarih
/// göstermez.
String? _formatEventDateLabel(final Event? event) {
  if (event == null) return null;
  final parts = DateFormatter.parseFormattedDateTime(event.date,
      formatWithMonthName: true);
  final date = parts['date'];
  final time = parts['time'];
  if (date == null || time == null) return null;
  return '$date, $time';
}

/// `shows` listesindeki oyunlar arasından takviminde GELECEK tarihli
/// etkinliği olanları, en yakın tarihten başlayarak en fazla [max] tanesini
/// seçer — `landing/app.js`'teki `upcomingEvents()` + `renderHero()` ile
/// AYNI mantığın çoğullu hali (bu Flutter sayfasının kendi statik kardeşi,
/// aynı dilde).
///
/// Sayfalama noktaları ve hotspot popover'ı BURADAN dönen listeyle
/// beslenir: hiçbir oyunun gelecek bir etkinliği yoksa (henüz
/// yüklenmemişse) tek elemanlı, tarihsiz bir listeye sessizce düşer —
/// bu durumda sayfalama noktaları da otomatik olarak gizlenir (liste
/// uzunluğu 1 olduğu için). Asla sahte bir tarih/sahne/"sıradaki oyun"
/// uydurmaz.
List<_FeaturedShowInfo> _pickFeaturedShows(
  final List<Show> shows,
  final List<Event> events,
  final List<Stage> stages, {
  final int max = 3,
}) {
  if (shows.isEmpty) return const [];

  final now = DateTime.now();
  final Map<String, Event> earliestByShow = {};
  for (final event in events) {
    final date = DateFormatter.parseDateString(event.date);
    if (date == null || !date.isAfter(now)) continue;
    final existing = earliestByShow[event.showId];
    if (existing == null) {
      earliestByShow[event.showId] = event;
      continue;
    }
    final existingDate = DateFormatter.parseDateString(existing.date);
    if (existingDate == null || date.isBefore(existingDate))
      earliestByShow[event.showId] = event;
  }

  final showById = {for (final s in shows) s.id: s};
  final stageById = {for (final st in stages) st.id: st};

  final withEvent = earliestByShow.entries
      .where((final e) => showById.containsKey(e.key))
      .toList()
    ..sort((final a, final b) {
      final da = DateFormatter.parseDateString(a.value.date)!;
      final db = DateFormatter.parseDateString(b.value.date)!;
      return da.compareTo(db);
    });

  if (withEvent.isNotEmpty)
    return withEvent
        .take(max)
        .map((final e) => _FeaturedShowInfo(
              show: showById[e.key]!,
              event: e.value,
              stage: stageById[e.value.stageId],
            ))
        .toList();

  // Hiçbir oyunun takvimde gelecek bir etkinliği yoksa ilk oyuna sessizce
  // düş — tek kart, sayfalama noktası yok.
  return [_FeaturedShowInfo(show: shows.first)];
}

/// Büyük format editoryal vitrin — gerçek bir afiş görseli üzerinde,
/// gerçek tarih/sahne bilgisiyle "sıradaki oyun" kartı + fotoğrafın
/// üzerine iğnelenmiş, AYNI gerçek veriyle beslenen bir hotspot
/// işaretleyici. Seçili oyun `_HeroBandState` içinde tutuluyor (sayfalama
/// noktalarıyla paylaşılabilsin diye) — bu widget artık kendi Firestore
/// okumasını yapmıyor, sadece hazır `entries` listesini çiziyor.
class _HeroFeaturedPanel extends StatelessWidget {
  final List<_FeaturedShowInfo> entries;
  final int selectedIndex;
  final ValueChanged<Show> onTap;

  const _HeroFeaturedPanel({
    required this.entries,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final info = entries[selectedIndex.clamp(0, entries.length - 1)];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _FeaturedShowCard(info: info, onTap: () => onTap(info.show)),
        // Fotoğrafın/afişin üzerine iğnelenmiş "+" hotspot — kartın sol
        // üst köşesine hafifçe taşarak referanstaki "fotoğraf üzerinde
        // duran nokta işaretleyici" hissini verir. Hover/dokunuşta AYNI
        // kartın kullandığı gerçek show/tarih/sahne bilgisini açar.
        Positioned(
          top: -16,
          left: -16,
          child: _HeroHotspotMarker(
            info: info,
            onOpenShow: () => onTap(info.show),
          ),
        ),
      ],
    );
  }
}

class _FeaturedShowCard extends StatefulWidget {
  final _FeaturedShowInfo info;
  final VoidCallback onTap;

  const _FeaturedShowCard({required this.info, required this.onTap});

  @override
  State<_FeaturedShowCard> createState() => _FeaturedShowCardState();
}

class _FeaturedShowCardState extends State<_FeaturedShowCard> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) {
    final show = widget.info.show;
    final stageName = widget.info.stage?.name;
    final dateLabel = _formatEventDateLabel(widget.info.event);
    final metaLine =
        [if (dateLabel != null) dateLabel, if (stageName != null) stageName]
            .join('  ·  ');

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (final _) => setState(() => _hovered = true),
      onExit: (final _) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height:
              context.responsive(mobile: 300.0, tablet: 360.0, desktop: 440.0),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: _kAsymLg,
            border: Border.all(
                color:
                    WebColors.primaryGold.withOpacity(_hovered ? 0.5 : 0.18)),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: WebColors.veryDarkBlue.withOpacity(0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ]
                : null,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 260),
                scale: _hovered ? 1.04 : 1.0,
                child: show.imageUrl.isEmpty
                    ? const ColoredBox(color: WebColors.darkBlueSurface)
                    : Image.network(
                        show.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (final _, final __, final ___) =>
                            const ColoredBox(
                          color: WebColors.darkBlueSurface,
                          child: Icon(Icons.theater_comedy_rounded,
                              color: WebColors.textTertiary, size: 40),
                        ),
                        loadingBuilder:
                            (final _, final child, final progress) =>
                                progress == null
                                    ? child
                                    : const ColoredBox(
                                        color: WebColors.darkBlueSurface),
                      ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      WebColors.veryDarkBlue.withOpacity(0.18),
                      WebColors.veryDarkBlue.withOpacity(0.94),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 22,
                top: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: WebColors.veryDarkBlue.withOpacity(0.55),
                    borderRadius: _kAsymSm,
                    border: Border.all(
                        color: WebColors.primaryGold.withOpacity(0.4)),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.homeNextShowLabel,
                    style: const TextStyle(
                      color: WebColors.primaryGoldLight,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 22,
                right: 22,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      show.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.headlineSmall?.copyWith(
                        color: WebColors.whiteText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (metaLine.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        metaLine,
                        style: const TextStyle(
                          color: WebColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: _hovered ? 1 : 0.75,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.homeSeeDetails,
                            style: const TextStyle(
                              color: WebColors.primaryGoldLight,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(width: 6),
                          AnimatedSlide(
                            duration: const Duration(milliseconds: 180),
                            offset: Offset(_hovered ? 0.2 : 0, 0),
                            child: const Icon(Icons.arrow_forward_rounded,
                                size: 14, color: WebColors.primaryGoldLight),
                          ),
                        ],
                      ),
                    ),
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

/// Fotoğrafın üzerine iğnelenmiş, GERÇEK "sıradaki oyun" verisine bağlı
/// animasyonlu "+" hotspot işaretleyici. Referanstaki dairesel nokta-
/// işaretleyici dilini ödünç alır ama İÇERİK TAMAMEN GERÇEKTİR: kapalı
/// haldeyken sadece nabız gibi atan noktalı bir halka + "+" ikonu var,
/// hiçbir uydurma başlık göstermez; hover'da (masaüstü) ya da dokunuşta
/// (dokunmatik) açılınca `_FeaturedShowCard`'ın kullandığı AYNI gerçek
/// oyun adı/tarih/sahne bilgisini bir popover kartında gösterir.
class _HeroHotspotMarker extends StatefulWidget {
  final _FeaturedShowInfo info;
  final VoidCallback onOpenShow;

  const _HeroHotspotMarker(
      {required this.info, required this.onOpenShow});

  @override
  State<_HeroHotspotMarker> createState() => _HeroHotspotMarkerState();
}

class _HeroHotspotMarkerState extends State<_HeroHotspotMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  bool _hovered = false;
  bool _tapped = false;

  bool get _expanded => _hovered || _tapped;

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final dateLabel = _formatEventDateLabel(widget.info.event);
    final stageName = widget.info.stage?.name;

    return MouseRegion(
      onEnter: (final _) => setState(() => _hovered = true),
      onExit: (final _) => setState(() => _hovered = false),
      child: SizedBox(
        width: 236,
        height: _expanded ? 250 : 60,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: 0,
              left: 0,
              child: GestureDetector(
                onTap: () => setState(() => _tapped = !_tapped),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: _HotspotRing(
                    pulse: _pulseController,
                    expanded: _expanded,
                  ),
                ),
              ),
            ),
            if (_expanded)
              Positioned(
                top: 62,
                left: 0,
                child: _HotspotCard(
                  show: widget.info.show,
                  dateLabel: dateLabel,
                  stageName: stageName,
                  onOpenShow: widget.onOpenShow,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HotspotRing extends StatelessWidget {
  final Animation<double> pulse;
  final bool expanded;

  const _HotspotRing({required this.pulse, required this.expanded});

  @override
  Widget build(final BuildContext context) => AnimatedBuilder(
        animation: pulse,
        builder: (final context, final child) {
          final t = pulse.value;
          return SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: 1.0 + t * 0.07,
                  child: CustomPaint(
                    size: const Size(52, 52),
                    painter: _DashedRingPainter(
                      color: WebColors.primaryGoldLight,
                      opacity: expanded ? 0.85 : 0.32 + t * 0.28,
                    ),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: WebColors.veryDarkBlue.withOpacity(0.88),
                    border: Border.all(
                        color: WebColors.primaryGoldLight, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: WebColors.primaryGold
                            .withOpacity(0.35 + t * 0.3),
                        blurRadius: 8 + t * 6,
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      expanded ? Icons.close_rounded : Icons.add_rounded,
                      key: ValueKey(expanded),
                      size: 13,
                      color: WebColors.primaryGoldLight,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}

/// İnce, noktalı/kesik çizgili halka — referanstaki hotspot çemberinin
/// çizim dili.
class _DashedRingPainter extends CustomPainter {
  final Color color;
  final double opacity;

  const _DashedRingPainter({required this.color, required this.opacity});

  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1;
    const dashCount = 22;
    const gapFraction = 0.55;
    final sweepPerDash = (2 * math.pi / dashCount) * gapFraction;
    for (var i = 0; i < dashCount; i++) {
      final startAngle = (2 * math.pi / dashCount) * i;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepPerDash,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant final _DashedRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.opacity != opacity;
}

/// Hotspot açıldığında görünen gerçek veri kartı — `_FeaturedShowCard` ile
/// AYNI show/tarih/sahne bilgisini taşır, uydurma hiçbir içerik yok.
class _HotspotCard extends StatelessWidget {
  final Show show;
  final String? dateLabel;
  final String? stageName;
  final VoidCallback onOpenShow;

  const _HotspotCard({
    required this.show,
    required this.dateLabel,
    required this.stageName,
    required this.onOpenShow,
  });

  @override
  Widget build(final BuildContext context) => Container(
        width: 224,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: WebColors.veryDarkBlue.withOpacity(0.94),
          borderRadius: _kAsymSm,
          border: Border.all(color: WebColors.primaryGold.withOpacity(0.45)),
          boxShadow: [
            BoxShadow(
              color: WebColors.veryDarkBlue.withOpacity(0.6),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.homeNextShowLabel,
              style: const TextStyle(
                color: WebColors.primaryGoldLight,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              show.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: WebColors.whiteText,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (dateLabel != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 12, color: WebColors.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      dateLabel!,
                      style: const TextStyle(
                          color: WebColors.textSecondary, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ],
            if (stageName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 12, color: WebColors.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      stageName!,
                      style: const TextStyle(
                          color: WebColors.textSecondary, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onOpenShow,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.homeSeeDetails,
                    style: const TextStyle(
                      color: WebColors.primaryGoldLight,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 12, color: WebColors.primaryGoldLight),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Sol kenardaki sayfalama noktaları — `_pickFeaturedShows`'tan dönen
/// GERÇEK, birden fazla yaklaşan oyun varsa görünür; dokunulunca o oyunu
/// seçer (bkz. `_HeroBandState._selectFeatured`). Dekoratif değil.
class _HeroPagerDots extends StatelessWidget {
  final int count;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _HeroPagerDots({
    required this.count,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(final BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _HeroDot(active: i == selectedIndex, onTap: () => onSelect(i)),
          ],
        ],
      );
}

class _HeroDot extends StatefulWidget {
  final bool active;
  final VoidCallback onTap;

  const _HeroDot({required this.active, required this.onTap});

  @override
  State<_HeroDot> createState() => _HeroDotState();
}

class _HeroDotState extends State<_HeroDot> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (final _) => setState(() => _hovered = true),
        onExit: (final _) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 6,
            height: widget.active ? 22 : 6,
            decoration: BoxDecoration(
              color: widget.active
                  ? WebColors.primaryGoldLight
                  : WebColors.textTertiary.withOpacity(_hovered ? 0.7 : 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      );
}

/// Sol alttaki dikey sosyal ikon şeridi — GERÇEK hesaplara açılır
/// (`TiyatrolCommunicationActions`, uygulamanın başka yerlerinde de
/// kullandığı aynı Instagram/Facebook bağlantıları). Süs amaçlı,
/// tıklanınca hiçbir şey yapmayan ikonlar DEĞİL.
class _HeroSocialRail extends StatelessWidget {
  const _HeroSocialRail();

  @override
  Widget build(final BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _HeroIconButton(
            icon: Icons.camera_alt_outlined,
            onTap: TiyatrolCommunicationActions.openInstagram,
          ),
          const SizedBox(height: 14),
          _HeroIconButton(
            icon: Icons.facebook_outlined,
            onTap: TiyatrolCommunicationActions.openFacebook,
          ),
        ],
      );
}

/// Sağ kenardaki dikey mini navigasyon şeridi — üç etiket de zaten var
/// olan gerçek aksiyonlara (`_HeroCopy` CTA'larıyla AYNI callback'ler)
/// bağlı; referanstaki "sağ kenar navigasyon" dilini ödünç alır ama sahte
/// bağlantı eklemez.
class _HeroSideNavRail extends StatelessWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onDiscoverTap;
  final VoidCallback onNearbyTap;

  const _HeroSideNavRail({
    required this.onSearchTap,
    required this.onDiscoverTap,
    required this.onNearbyTap,
  });

  @override
  Widget build(final BuildContext context) => RotatedBox(
        quarterTurns: 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HeroRailLabel(
                label: AppLocalizations.of(context)!.homeHeroSearchLabel,
                onTap: onSearchTap),
            _railDivider(),
            _HeroRailLabel(
                label: AppLocalizations.of(context)!.homeDiscoverKicker,
                onTap: onDiscoverTap),
            _railDivider(),
            _HeroRailLabel(
                label: AppLocalizations.of(context)!.homeNearMeLabel,
                onTap: onNearbyTap),
          ],
        ),
      );

  Widget _railDivider() => Container(
        width: 22,
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 14),
        color: WebColors.darkBlueAccent,
      );
}

class _HeroRailLabel extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _HeroRailLabel({required this.label, required this.onTap});

  @override
  State<_HeroRailLabel> createState() => _HeroRailLabelState();
}

class _HeroRailLabelState extends State<_HeroRailLabel> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (final _) => setState(() => _hovered = true),
        onExit: (final _) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 160),
            style: TextStyle(
              color: _hovered
                  ? WebColors.primaryGoldLight
                  : WebColors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
            child: Text(widget.label),
          ),
        ),
      );
}

/// `_HeroSocialRail`'deki tek bir dairesel ikon düğmesi.
class _HeroIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeroIconButton({required this.icon, required this.onTap});

  @override
  State<_HeroIconButton> createState() => _HeroIconButtonState();
}

class _HeroIconButtonState extends State<_HeroIconButton> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (final _) => setState(() => _hovered = true),
        onExit: (final _) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    WebColors.primaryGold.withOpacity(_hovered ? 0.7 : 0.32),
              ),
              color: _hovered
                  ? WebColors.primaryGold.withOpacity(0.12)
                  : Colors.transparent,
            ),
            child: Icon(widget.icon,
                size: 15,
                color: _hovered
                    ? WebColors.primaryGoldLight
                    : WebColors.textTertiary),
          ),
        ),
      );
}

/// Sahnedeki oyun isimlerinin sürekli kaydığı ince, sessiz bir şerit —
/// `landing/index.html`'deki `.marquee` bölümüyle AYNI DİL (sonsuz döngü,
/// isimler arası ayraç), ama çok daha sakin bir görsel ağırlıkla: dolgu
/// renk yok, sadece ince üst/alt çizgi + soluk metin. Eski kutulu
/// istatistik panelinin yerini alan ikinci bir "neler oynuyor" ipucu.
class _HeroShowsMarquee extends StatefulWidget {
  final List<String> names;

  const _HeroShowsMarquee({required this.names});

  @override
  State<_HeroShowsMarquee> createState() => _HeroShowsMarqueeState();
}

class _HeroShowsMarqueeState extends State<_HeroShowsMarquee>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 34),
  )..repeat();
  final GlobalKey _setKey = GlobalKey();
  double _setWidth = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((final _) => _measure());
  }

  @override
  void didUpdateWidget(covariant final _HeroShowsMarquee oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.names, widget.names)) {
      _setWidth = 0;
      WidgetsBinding.instance.addPostFrameCallback((final _) => _measure());
    }
  }

  void _measure() {
    if (!mounted) return;
    final renderObject = _setKey.currentContext?.findRenderObject();
    if (renderObject is RenderBox) {
      final width = renderObject.size.width;
      if (width > 0) setState(() => _setWidth = width);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildSet({final Key? key}) => Row(
        key: key,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final name in widget.names) ...[
            Text(
              name,
              style: const TextStyle(
                color: WebColors.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Text('✦',
                  style: TextStyle(
                      color: WebColors.primaryGold.withOpacity(0.55),
                      fontSize: 11)),
            ),
          ],
        ],
      );

  @override
  Widget build(final BuildContext context) {
    if (widget.names.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 52,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: WebColors.darkBlueAccent),
          bottom: BorderSide(color: WebColors.darkBlueAccent),
        ),
      ),
      child: ClipRect(
        child: _setWidth == 0
            ? Opacity(
                opacity: 0, child: Center(child: _buildSet(key: _setKey)))
            : AnimatedBuilder(
                animation: _controller,
                builder: (final context, final child) {
                  final dx = -_controller.value * _setWidth;
                  return Stack(
                    children: [
                      Positioned(
                        left: dx,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [_buildSet(), _buildSet()]),
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HIZLI BAĞLANTILAR
// ═══════════════════════════════════════════════════════════════

/// Gerçek hesap verisiyle çalışan bir "panom" bandı: Biletlerim/
/// Favorilerim/Yaklaşan Etkinlikler/Hesap Ayarları — her kart gerçek bir
/// sayı taşır (yaklaşan bilet adedi, favori adedi, önümüzdeki gerçek
/// etkinlik adedi) ve gerçekten bir yere gider. Eskiden buradaki "Takvim"
/// kartı `onTap: () {}` ile hiçbir şey yapmıyordu ve "Bildirimler" kartı
/// aslında Ayarlar'a gidiyordu (yanlış etiketliydi) — ikisi de düzeltildi.
class _QuickLinksBand extends StatelessWidget {
  final bool loggedIn;
  final int upcomingTicketCount;
  final String? nextTicketShowName;
  final int favoritesCount;
  final int nearbyEventCount;
  final VoidCallback onTicketsTap;
  final VoidCallback onFavoritesTap;
  final VoidCallback onNearbyTap;
  final VoidCallback onSettingsTap;

  const _QuickLinksBand({
    required this.loggedIn,
    required this.upcomingTicketCount,
    required this.nextTicketShowName,
    required this.favoritesCount,
    required this.nearbyEventCount,
    required this.onTicketsTap,
    required this.onFavoritesTap,
    required this.onNearbyTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(final BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String ticketsSubtitle = !loggedIn
        ? l10n.homeTicketsLoginPrompt
        : upcomingTicketCount == 0
            ? l10n.homeTicketsNoneYet
            : nextTicketShowName == null
                ? l10n.homeTicketsSeeDetails
                : l10n.homeTicketsNext(nextTicketShowName!);
    final String favoritesSubtitle = !loggedIn
        ? l10n.homeFavoritesLoginPrompt
        : favoritesCount == 0
            ? l10n.homeFavoritesNoneYet
            : l10n.homeFavoritesView;
    final String nearbySubtitle = nearbyEventCount == 0
        ? l10n.homeNearbyNoneYet
        : l10n.homeNearbyView;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: WebColors.darkBlueSurface.withOpacity(0.5),
        borderRadius: _kAsymLg,
        border: Border.all(color: WebColors.darkBlueAccent, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _DashboardCard(
              icon: Icons.confirmation_number_outlined,
              statValue: loggedIn ? '$upcomingTicketCount' : '—',
              statLabel: l10n.homeStatUpcomingTicket,
              subtitle: ticketsSubtitle,
              onTap: onTicketsTap,
            ),
            _DashboardCard(
              icon: Icons.favorite_outline,
              statValue: loggedIn ? '$favoritesCount' : '—',
              statLabel: l10n.homeStatFavorite,
              subtitle: favoritesSubtitle,
              onTap: onFavoritesTap,
            ),
            _DashboardCard(
              icon: Icons.event_available_outlined,
              statValue: '$nearbyEventCount',
              statLabel: l10n.homeStatNearby,
              subtitle: nearbySubtitle,
              onTap: onNearbyTap,
            ),
            _DashboardCard(
              icon: Icons.settings_outlined,
              statValue: null,
              statLabel: null,
              title: l10n.homeAccountSettingsTitle,
              subtitle: l10n.homeAccountSettingsSubtitle,
              onTap: onSettingsTap,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatefulWidget {
  final IconData icon;
  final String? statValue;
  final String? statLabel;
  final String? title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.statValue,
    required this.statLabel,
    this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<_DashboardCard> {
  bool _hovered = false;

  @override
  Widget build(final BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (final _) => setState(() => _hovered = true),
        onExit: (final _) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 258,
            padding: const EdgeInsets.all(18),
            transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
            decoration: BoxDecoration(
              color: _hovered
                  ? WebColors.darkBlueAccent.withOpacity(0.4)
                  : WebColors.darkBlueBackground.withOpacity(0.5),
              borderRadius: _kAsymSm,
              border: Border.all(
                color: _hovered
                    ? WebColors.primaryGold.withOpacity(0.55)
                    : WebColors.darkBlueAccent,
                width: 1,
              ),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: WebColors.primaryGold.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _hovered
                            ? WebColors.primaryGold.withOpacity(0.18)
                            : WebColors.darkBlueAccent.withOpacity(0.6),
                      ),
                      child: Icon(widget.icon,
                          size: 18,
                          color: _hovered
                              ? WebColors.primaryGoldLight
                              : WebColors.textTertiary),
                    ),
                    if (widget.statValue != null) ...[
                      const Spacer(),
                      Text(
                        widget.statValue!,
                        style: const TextStyle(
                          color: WebColors.whiteText,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title ?? widget.statLabel ?? '',
                  style: const TextStyle(
                    color: WebColors.whiteText,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: WebColors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// KAPANIŞ ALIN TIYATI
// ═══════════════════════════════════════════════════════════════

class _ClosingQuoteBand extends StatelessWidget {
  const _ClosingQuoteBand();

  @override
  Widget build(final BuildContext context) => Padding(
        padding: EdgeInsets.only(
          top: context.responsive(mobile: 56.0, tablet: 68.0, desktop: 84.0),
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: _sectionPad(context),
            vertical: context.responsive(
                mobile: 48.0, tablet: 60.0, desktop: 76.0),
          ),
          decoration: const BoxDecoration(color: WebColors.veryDarkBlue),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                children: [
                  Container(
                    width: 46,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        WebColors.primaryGold.withOpacity(0.9),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    // Hippokrates'in tam aforizması, orijinal Latincesiyle
                    // önce, altında tam Türkçe çevirisi daha küçük
                    // puntoyla (bkz. mobildeki BottomQuote,
                    // decorative_elements.dart — aynı metin).
                    AppLocalizations.of(context)!.homeQuoteLatin,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: WebColors.lightWhite,
                      fontStyle: FontStyle.italic,
                      fontSize: context.responsive(
                          mobile: 18.0, tablet: 21.0, desktop: 24.0),
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.homeQuoteTranslation,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: WebColors.textSecondary,
                      fontStyle: FontStyle.italic,
                      fontSize: context.responsive(
                          mobile: 13.0, tablet: 14.0, desktop: 15.0),
                      height: 1.4,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.homeDailyDiscoveryTag,
                    style: const TextStyle(
                      color: WebColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
