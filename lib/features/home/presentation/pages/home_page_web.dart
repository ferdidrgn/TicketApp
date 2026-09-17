import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/global_error_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../events/domain/entities/event.dart';
import '../../../events/presentation/providers/event_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
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
    // Sadece takviminde gelecek etkinliği olan ("aktif") oyunlar — geçmiş
    // sezonlarda kalmış oyunlar ana sayfada/önerilerde görünmemeli.
    final showState = ref.watch(activeShowsProvider(true));
    final stageState = ref.watch(stagesProvider(isLimit: true));

    final bool isLoading =
        campaignState.isLoading || showState.isLoading || stageState.isLoading;
    final bool hasError =
        campaignState.hasError || showState.hasError || stageState.hasError;

    final campaigns = campaignState.value ?? const [];
    final shows = showState.value ?? const [];
    final stages = stageState.value ?? const [];

    final bool showLoadingState = isLoading && showState.value == null;

    return ColoredBox(
      color: WebColors.darkBlueBackground,
      child: hasError
          ? GlobalErrorWidget(
              isFullPage: false,
              title: 'Perdeler Henüz Açılmadı',
              message: 'Sahne verileri yüklenirken bir sorun oluştu.',
              onRetry: () {
                ref.invalidate(campaignsProvider);
                ref.invalidate(activeShowsProvider);
                ref.invalidate(stagesProvider);
              },
            )
          : showLoadingState
              ? const _WebLoadingState()
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
                            kicker: 'VİTRİN',
                            title: 'Öne Çıkanlar',
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
                          kicker: 'SANATIN RENKLERİ',
                          title: 'Kategoriler',
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
                          kicker: 'KEŞFET',
                          title: 'Sana Özel Seçkiler',
                          trailingLabel: shows.isEmpty ? null : 'Tümünü Gör',
                          onTrailingTap: () =>
                              NavigationHandler.goToDiscover(context),
                          child: shows.isEmpty
                              ? const _EmptyHint(
                                  text:
                                      'Şu anda listelenecek bir oyun bulunmuyor. Yakında burada olacak.')
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
                            kicker: 'MEKANLAR',
                            title: 'Şehrin Sahneleri',
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
                                child: const HomePromoBanner(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // 6. Hızlı Erişim (mobildeki QuickActionsGrid'in aynısı:
                      // Bildirimler/Favorilerim/Biletlerim/Takvim)
                      RevealOnScroll(
                        child: _Section(
                          kicker: 'HIZLI ERİŞİM',
                          title: 'Neye İhtiyacın Var?',
                          child: _QuickLinksBand(
                            onNotificationsTap: () =>
                                NavigationHandler.goToSettings(context),
                            onFavoritesTap: () =>
                                NavigationHandler.goToFavorites(context),
                            onTicketsTap: _goToTickets,
                          ),
                        ),
                      ),
                      // 7. Şu An Popüler (mobildeki TrendingNowSection'ın aynısı)
                      RevealOnScroll(
                        child: _Section(
                          kicker: 'GÜNDEM',
                          title: 'Şu An Popüler',
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
                    ],
                  ),
                ),
    );
  }
}

class _WebLoadingState extends StatelessWidget {
  const _WebLoadingState();

  @override
  Widget build(final BuildContext context) => const SizedBox(
        height: 520,
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(WebColors.primaryGoldLight),
            ),
          ),
        ),
      );
}

// ═══════════════════════════════════════════════════════════════
// PAYLAŞILAN KÜÇÜK YARDIMCILAR
// ═══════════════════════════════════════════════════════════════

const BorderRadius _kAsymLg = BorderRadius.only(
  topLeft: Radius.circular(6),
  topRight: Radius.circular(32),
  bottomLeft: Radius.circular(6),
  bottomRight: Radius.circular(32),
);

const BorderRadius _kAsymSm = BorderRadius.only(
  topLeft: Radius.circular(2),
  topRight: Radius.circular(12),
  bottomLeft: Radius.circular(2),
  bottomRight: Radius.circular(12),
);

double _sectionPad(final BuildContext context) => context.responsive(
      mobile: 20.0,
      tablet: 40.0,
      desktop: 64.0,
      largeDesktop: 96.0,
    );

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

class _HeroBand extends StatefulWidget {
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
  State<_HeroBand> createState() => _HeroBandState();
}

class _HeroBandState extends State<_HeroBand>
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

  @override
  Widget build(final BuildContext context) {
    // Editoryal vitrin (gerçek afiş + tarih/sahne) sadece takviminde en az
    // bir gelecek etkinliği olan bir oyun varsa gösterilir. Hiç aktif oyun
    // yoksa metin bloğu tek başına, tam genişlikte kalır — boş bir panel
    // için asla yer ayrılmaz.
    final bool hasFeatured = widget.shows.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: WebColors.backgroundGradient),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              // Sahne ışığı motifi #1 — sağ üst, ana vurgu
              Positioned(
                top: -140,
                right: -80,
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (final context, final child) => Opacity(
                    opacity: 0.14 + _glowController.value * 0.07,
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
              // (referans "Crimson Noir" paletindeki ortalanmış radial glow
              // hissini tüm hero'ya yayıyor, tek nokta yerine)
              Positioned(
                bottom: -120,
                left: -100,
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (final context, final child) => Opacity(
                    opacity: 0.18 - _glowController.value * 0.06,
                    child: child,
                  ),
                  child: Container(
                    width: 340,
                    height: 340,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [WebColors.secondaryAccent, Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  _sectionPad(context),
                  context.responsive(mobile: 32.0, tablet: 44.0, desktop: 56.0),
                  _sectionPad(context),
                  context.responsive(mobile: 36.0, tablet: 40.0, desktop: 48.0),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: LayoutBuilder(
                      builder: (final context, final constraints) {
                        final bool wide = constraints.maxWidth >= 980;
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
                              showCount: widget.shows.length,
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
                              shows: widget.shows,
                              stages: widget.stages,
                              onTap: widget.onFeaturedShowTap,
                            ),
                          ),
                        );

                        if (!wide)
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
            ],
          ),
          // Sahnedeki oyunların isimlerinin sessizce kaydığı ince bir
          // şerit — eski, kutulu istatistik panelinin yerini alan çok daha
          // sakin bir "neler oynuyor" ipucu (bkz. `landing/index.html`'deki
          // `.marquee` bölümü — aynı dil, farklı görsel ağırlık).
          _HeroShowsMarquee(
              names: widget.shows.map((final s) => s.name).toList()),
        ],
      ),
    );
  }
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
  String get _lede {
    if (showCount > 0 && stageCount > 0)
      return 'Şehrin $stageCount sahnesinde bu sezon aktif $showCount '
          'oyunu keşfet; sana en yakın gösterimlere göz at ve birkaç '
          'dokunuşla biletini al.';
    return 'Şehrin sahnelerinde bu sezon oynayan oyunları keşfet, '
        'yakınındaki etkinliklere göz at ve biletini birkaç tıkla al.';
  }

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: WebColors.primaryGold.withOpacity(0.5)),
              borderRadius: _kAsymSm,
            ),
            child: const Text(
              'TİYATROL',
              style: TextStyle(
                color: WebColors.primaryGoldLight,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Bu akşam,\nhangi sahne seni bekliyor?',
            style: (context.textTheme.displaySmall ?? const TextStyle()).copyWith(
              color: WebColors.whiteText,
              fontWeight: FontWeight.w300,
              height: 1.12,
              fontSize: context.responsive(
                  mobile: 30.0, tablet: 36.0, desktop: 42.0, largeDesktop: 46.0),
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(
              _lede,
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
                label: 'Sahneleri Keşfet',
                icon: Icons.explore_rounded,
                filled: true,
                onTap: onDiscoverTap,
              ),
              _PillButton(
                label: 'Yakınımdakiler',
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
                    'Tiyatro, konser, sanatçı ara…',
                    style: TextStyle(
                      color: WebColors.textSecondary.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  'ARA',
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
                      color: WebColors.primaryGold.withOpacity(_hovered ? 0.9 : 0.55),
                      width: 1.4),
              boxShadow: widget.filled && _hovered
                  ? [
                      BoxShadow(
                        color: WebColors.primaryGold.withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
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
/// en yakın GELECEK etkinliği + (varsa) o etkinliğin sahnesi.
class _FeaturedShowInfo {
  final Show show;
  final Event? event;
  final Stage? stage;

  const _FeaturedShowInfo({required this.show, this.event, this.stage});
}

/// `shows` listesindeki oyunlar arasından takviminde en yakın GELECEK
/// tarihli etkinliği olanı seçer — `landing/app.js`'teki
/// `upcomingEvents()` + `renderHero()` ile AYNI mantık (bu Flutter
/// sayfasının kendi statik kardeşi, aynı dilde). Hiçbir oyunun gelecek
/// etkinliği `events` listesinde bulunamazsa (örn. henüz yüklenmemişse)
/// ilk oyuna sessizce düşer — asla sahte bir tarih/sahne uydurmaz.
_FeaturedShowInfo? _pickFeaturedShow(
  final List<Show> shows,
  final List<Event> events,
  final List<Stage> stages,
) {
  if (shows.isEmpty) return null;

  final now = DateTime.now();
  Event? bestEvent;
  DateTime? bestDate;
  for (final event in events) {
    final date = DateFormatter.parseDateString(event.date);
    if (date == null || !date.isAfter(now)) continue;
    if (bestDate == null || date.isBefore(bestDate)) {
      bestDate = date;
      bestEvent = event;
    }
  }

  Show featured = shows.first;
  if (bestEvent != null)
    for (final s in shows)
      if (s.id == bestEvent.showId) {
        featured = s;
        break;
      }

  Stage? stage;
  if (bestEvent != null)
    for (final st in stages)
      if (st.id == bestEvent.stageId) {
        stage = st;
        break;
      }

  return _FeaturedShowInfo(show: featured, event: bestEvent, stage: stage);
}

/// Büyük format editoryal vitrin — gerçek bir afiş görseli üzerinde,
/// gerçek tarih/sahne bilgisiyle "sıradaki oyun". Eski `_HeroStatsPanel`
/// (Oyun/Sahne/Kampanya sayaçlı kutu) burada YOK — sayılar artık
/// `_HeroCopy._lede` içinde metne örülü, ikinci planda.
class _HeroFeaturedPanel extends ConsumerWidget {
  final List<Show> shows;
  final List<Stage> stages;
  final ValueChanged<Show> onTap;

  const _HeroFeaturedPanel({
    required this.shows,
    required this.stages,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    // Firestore okumasını sınırlı tutmak için en fazla ilk 12 aktif oyunun
    // etkinliklerine bakılır — `activeShowsProvider` zaten `isLimit: true`
    // ile üst sınırlı bir listeden geliyor.
    final candidates = shows.length > 12 ? shows.sublist(0, 12) : shows;
    final eventIds = candidates
        .expand((final s) => s.eventsId)
        .where((final id) => id.isNotEmpty)
        .toSet()
        .toList();

    final eventsAsync = eventIds.isEmpty
        ? const AsyncValue<List<Event>>.data(<Event>[])
        : ref.watch(eventsByIdsProvider(eventIds));

    final info =
        _pickFeaturedShow(candidates, eventsAsync.value ?? const [], stages);
    if (info == null) return const SizedBox.shrink();

    return _FeaturedShowCard(info: info, onTap: () => onTap(info.show));
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

  String? get _dateLabel {
    final event = widget.info.event;
    if (event == null) return null;
    final parts = DateFormatter.parseFormattedDateTime(event.date,
        formatWithMonthName: true);
    final date = parts['date'];
    final time = parts['time'];
    if (date == null || time == null) return null;
    return '$date, $time';
  }

  @override
  Widget build(final BuildContext context) {
    final show = widget.info.show;
    final stageName = widget.info.stage?.name;
    final dateLabel = _dateLabel;
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
                  child: const Text(
                    'SIRADAKİ OYUN',
                    style: TextStyle(
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
                          const Text(
                            'Detayları Gör',
                            style: TextStyle(
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

/// Mobildeki `QuickActionsGrid` ile aynı 4 aksiyon (Bildirimler/
/// Favorilerim/Biletlerim/Takvim) — Takvim'in `onTap`'ı mobil tarafta da
/// boş (`() {}`), burada da öyle bırakıldı, yeni bir sahte davranış
/// eklenmedi.
class _QuickLinksBand extends StatelessWidget {
  final VoidCallback onNotificationsTap;
  final VoidCallback onFavoritesTap;
  final VoidCallback onTicketsTap;

  const _QuickLinksBand({
    required this.onNotificationsTap,
    required this.onFavoritesTap,
    required this.onTicketsTap,
  });

  @override
  Widget build(final BuildContext context) => Wrap(
        spacing: 18,
        runSpacing: 18,
        children: [
          _QuickLinkCard(
            icon: Icons.notifications_outlined,
            title: 'Bildirimler',
            subtitle: 'Fırsat ve hatırlatmaları yönet',
            onTap: onNotificationsTap,
          ),
          _QuickLinkCard(
            icon: Icons.favorite_outline,
            title: 'Favorilerim',
            subtitle: 'Kaydettiğin oyunlar',
            onTap: onFavoritesTap,
          ),
          _QuickLinkCard(
            icon: Icons.confirmation_number_outlined,
            title: 'Biletlerim',
            subtitle: 'Aldığın biletleri görüntüle',
            onTap: onTicketsTap,
          ),
          _QuickLinkCard(
            icon: Icons.calendar_today_outlined,
            title: 'Takvim',
            subtitle: 'Etkinlik takvimin (yakında)',
            onTap: () {},
          ),
        ],
      );
}

class _QuickLinkCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickLinkCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_QuickLinkCard> createState() => _QuickLinkCardState();
}

class _QuickLinkCardState extends State<_QuickLinkCard> {
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
            width: 270,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            transform:
                Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: _kAsymSm,
              border: Border.all(
                color: _hovered
                    ? WebColors.primaryGold.withOpacity(0.5)
                    : WebColors.darkBlueAccent,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(widget.icon,
                    size: 18,
                    color: _hovered
                        ? WebColors.primaryGoldLight
                        : WebColors.textTertiary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: WebColors.whiteText,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: WebColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
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
                    // Mobildeki BottomQuote ile birebir aynı metin
                    // (decorative_elements.dart) — iki platformda da aynı
                    // kapanış alıntısı görünsün diye.
                    '"Sanat, hayatın kendisidir."',
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
                  const SizedBox(height: 16),
                  const Text(
                    'HER GÜN YENİ BİR KEŞİF',
                    style: TextStyle(
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
