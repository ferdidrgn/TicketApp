import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/global_error_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../shows/presentation/providers/show_provider.dart';
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
    final showState = ref.watch(showsProvider(isLimit: true));
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
                ref.invalidate(showsProvider);
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
                        showCount: showState.value?.length,
                        stageCount: stageState.value?.length,
                        campaignCount: campaignState.value?.length,
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
  final int? showCount;
  final int? stageCount;
  final int? campaignCount;

  const _HeroBand({
    required this.onSearchTap,
    required this.onDiscoverTap,
    required this.onNearbyTap,
    required this.showCount,
    required this.stageCount,
    required this.campaignCount,
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
  Widget build(final BuildContext context) => Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: WebColors.backgroundGradient),
        child: Stack(
          children: [
            // Sahne ışığı motifi #1 — sağ üst, ana vurgu
            Positioned(
              top: -140,
              right: -80,
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (final context, final child) => Opacity(
                  opacity: 0.16 + _glowController.value * 0.09,
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
                  opacity: 0.22 - _glowController.value * 0.08,
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
                context.responsive(mobile: 32.0, tablet: 36.0, desktop: 44.0),
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
                          ),
                        ),
                      );
                      final right = FadeTransition(
                        opacity: _fade(0.18),
                        child: SlideTransition(
                          position: _fade(0.18).drive(Tween(
                              begin: const Offset(0, 0.06),
                              end: Offset.zero)),
                          child: _HeroStatsPanel(
                            showCount: widget.showCount,
                            stageCount: widget.stageCount,
                            campaignCount: widget.campaignCount,
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
                          Expanded(flex: 3, child: left),
                          const SizedBox(width: 48),
                          Expanded(flex: 2, child: right),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _HeroCopy extends StatelessWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onDiscoverTap;
  final VoidCallback onNearbyTap;

  const _HeroCopy({
    required this.onSearchTap,
    required this.onDiscoverTap,
    required this.onNearbyTap,
  });

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
          const SizedBox(height: 18),
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
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
              'Şehrin sahnelerinde bu sezon oynayan oyunları keşfet, '
              'yakınındaki etkinliklere göz at ve biletini birkaç '
              'tıkla al.',
              style: TextStyle(
                color: WebColors.textSecondary,
                fontSize: 14.5,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 24),
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

class _HeroStatsPanel extends StatelessWidget {
  final int? showCount;
  final int? stageCount;
  final int? campaignCount;

  const _HeroStatsPanel({
    required this.showCount,
    required this.stageCount,
    required this.campaignCount,
  });

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              WebColors.darkBlueSurface.withOpacity(0.75),
              WebColors.darkBlueSurface.withOpacity(0.5),
            ],
          ),
          borderRadius: _kAsymLg,
          border: Border.all(color: WebColors.primaryGold.withOpacity(0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ŞU AN SAHNEDE',
              style: TextStyle(
                color: WebColors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 18),
            _StatRow(label: 'Oyun', value: showCount),
            const _StatDivider(),
            _StatRow(label: 'Sahne', value: stageCount),
            const _StatDivider(),
            _StatRow(label: 'Aktif kampanya', value: campaignCount),
          ],
        ),
      );
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Container(height: 1, color: WebColors.darkBlueAccent),
      );
}

class _StatRow extends StatelessWidget {
  final String label;
  final int? value;

  const _StatRow({required this.label, required this.value});

  @override
  Widget build(final BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          value == null
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.6,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(WebColors.primaryGoldLight),
                  ),
                )
              : Text(
                  '$value',
                  style: const TextStyle(
                    color: WebColors.whiteText,
                    fontSize: 26,
                    fontWeight: FontWeight.w300,
                    height: 1.0,
                  ),
                ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: WebColors.textSecondary,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      );
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
