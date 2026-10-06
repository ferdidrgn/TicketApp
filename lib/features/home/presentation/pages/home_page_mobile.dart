import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ticketapp/shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/admin_test_entry.dart';
import '../widgets/common/home_showcase.dart';

import '../../../../core/base/base_page_wrapper.dart';
import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../campaigns/domain/entities/campaign.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../providers/home_sessions_provider.dart';
import '../providers/home_show_filter_provider.dart';
import '../widgets/common/home_ticket_widgets.dart';
import '../widgets/common/home_ui.dart';
import '../widgets/mobile/home_teams_strip.dart';

/// ANA SAYFA — MOBİL (Android/iOS; tablet dahil). Dikey anlatı, "bilet
/// dili"yle:
///
/// 1. Üst satır: marka + Biletlerim + Bildirimler (telefon).
/// 2. Tek başlık anı (Playfair, soldan sağa açılış) + arama.
/// 3. Sıradaki gerçek seansın DİKEY giriş bileti — birincil aksiyon
///    koçandaki "Bilet al" damgası (başparmak bölgesi); basınca koçan yırtılır.
/// 4. Yaklaşan seanslar: gün şeridi + seans koçanları.
/// 5. Şu an sahnede (aktif oyunlar şeridi) ve 6. Repertuvar (kalan oyunlar).
/// 7. Kampanyalar, 8. Şehrin sahneleri, 9. Sahne toplulukları — veri varsa.
///
/// Tablette (≥768) içerik 760'ta ortalanır, bilet YATAY olur, seanslar 2,
/// repertuvar 3 sütun; arama ve bildirimler üst çubuktadır.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showSearchInAppBar = false;

  late final AnimationController _entrance =
      AnimationController(vsync: this, duration: AppMotion.slow);
  late final Animation<double> _rest = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.35, 1.0, curve: AppMotion.standard));
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (mounted) {
      final bool showSearch = _scrollController.offset > 250;
      if (_showSearchInAppBar != showSearch) {
        setState(() => _showSearchInAppBar = showSearch);
      }
    }
  }

  void _openSearch() => NavigationHandler.goToSearch(context);

  void _openShow(final Show show) =>
      NavigationHandler.goToShow(context, show.id, show.name);

  void _openTickets() {
    if (ref.read(isLoggedInProvider)) {
      NavigationHandler.goToMyTickets(
          context, ref.read(currentUserIdProvider) ?? '');
    } else {
      NavigationHandler.goToLogin(context);
    }
  }

  void _openNotifications() {
    if (ref.read(isLoggedInProvider)) {
      NavigationHandler.goToNotifications(context);
    } else {
      NavigationHandler.goToLogin(context);
    }
  }

  Widget _settle(final Widget child) => AnimatedBuilder(
        animation: _rest,
        builder: (final context, final c) => Opacity(
          opacity: _rest.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _rest.value) * 28),
            child: c,
          ),
        ),
        child: child,
      );

  @override
  Widget build(final BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = context.colors;
    final campaignState = ref.watch(campaignsProvider);
    // Ana sayfa filtresi: SADECE TiyatRol + Ataşehir Tiyatro Topluluğu
    // oyunları (+ harici biletli konuk oyunlar), en yeni eklenen önce (bkz.
    // home_show_filter_provider.dart). Arama/keşfet bu filtreye tabi değil.
    final showState = ref.watch(homeShowsActiveFirstProvider(true));
    // "Şu an sahnede" şeridinin gerçek verisi — takviminde gelecek etkinliği
    // olan oyunlar + harici biletli oyunlar. İkincil: boşsa bölüm gizlenir.
    final activeShowState = ref.watch(homeActiveShowsProvider(true));
    final stageState = ref.watch(stagesProvider(isLimit: true));
    // Gerçek yaklaşan seanslar (öne çıkan bilet + seans panosu). İkincil.
    final sessionsState = ref.watch(homeUpcomingSessionsProvider);
    final bool isLargeScreen = context.isTablet || context.isDesktop;

    final bool isLoading =
        campaignState.isLoading || showState.isLoading || stageState.isLoading;
    final hasError =
        campaignState.hasError || showState.hasError || stageState.hasError;

    final List<Campaign> campaigns = campaignState.value ?? const [];
    final List<Show> shows = showState.value ?? const [];
    final List<Show> activeShows = activeShowState.value ?? const [];
    final List<Stage> stages = stageState.value ?? const [];
    final List<HomeSession> sessions = sessionsState.value ?? const [];
    final bool sessionsPending =
        sessionsState.isLoading && sessionsState.value == null;

    // Repertuvar: "şu an sahnede" şeridinde olmayan ana sayfa oyunları —
    // aynı oyun iki kez gösterilmez.
    final activeIds = activeShows.map((final s) => s.id).toSet();
    final List<Show> repertoire = shows
        .where((final s) => !activeIds.contains(s.id))
        .take(isLargeScreen ? 6 : 4)
        .toList();

    final HomeTicketLayout ticketLayout =
        isLargeScreen ? HomeTicketLayout.medium : HomeTicketLayout.compact;
    final HomeFeatured? featured =
        sessionsPending ? null : pickHomeFeatured(sessions, shows);

    const EdgeInsets gutter = EdgeInsets.symmetric(horizontal: AppSpacing.xl);
    // Vitrin slaytları: kampanyalar önce, sonra sahnedeki oyunlar.
    final List<HomeSlide> slides = HomeSlide.build(
      context,
      campaigns: campaigns,
      shows: activeShows.isNotEmpty ? activeShows : shows,
      onShow: _openShow,
    );

    return BasePageWrapper(
      showBackButton: false,
      showFab: true,
      customScrollController: _scrollController,
      appBar: isLargeScreen ? _buildWebAppBar(context) : _buildDynamicAppBar(),
      isLoading: isLoading && (campaignState.value == null),
      layoutConfig: BasePageLayoutConfig(
        backgroundColor: cs.surface,
        ambientColor: cs.primary.withOpacity(0.05),
        extendBody: true,
      ),
      child: hasError
          ? _buildErrorWidget(context, ref)
          : Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: isLargeScreen ? 760 : double.infinity),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  // Alt gezinme çubuğu (extendBody) içeriğin üstünde yüzüyor.
                  padding: const EdgeInsets.only(bottom: 120),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Geçici: admin panelini rol kontrolü olmadan test
                      // etme girişi (release derlemesinde görünmez).
                      const AdminTestStrip(),
                      if (!isLargeScreen)
                        _MobileTopBar(
                          unreadCount: _unreadCount(),
                          onTickets: _openTickets,
                          onNotifications: _openNotifications,
                        )
                      else
                        const SizedBox(height: AppSpacing.xxl),

                      // Selamlama + arama (sayfanın tek "hoş geldin" anı).
                      Padding(
                        padding: gutter,
                        child: const HomeGreeting(),
                      ),
                      if (!isLargeScreen) ...[
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: gutter,
                          child: _settle(HomeSearchField(
                            onTap: _openSearch,
                            hint: l10n.homeHeroSearchPlaceholder,
                          )),
                        ),
                      ],

                      // Vitrin: kampanyalar + sahnedeki oyunlar, kendiliğinden
                      // kayar; gösterge bir sonraki slayda kalan süreyi dolar.
                      if (slides.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _settle(HomeSpotlightCarousel(
                          slides: slides,
                          height: isLargeScreen ? 300 : 220,
                          padding: gutter,
                        )),
                      ],

                      // Bu hafta: gerçek seanslardan tek satırlık nabız.
                      if (sessions.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        Padding(
                          padding: gutter,
                          child: HomeWeekPulse(
                            sessions: sessions,
                            onTap: () =>
                                NavigationHandler.goToNearby(context),
                          ),
                        ),
                      ],

                      // Sıradaki seans — sayfadaki tek "bilet" anı.
                      if (sessionsPending || featured != null)
                        _MobileSection(
                          title: homeText(
                              context, 'Sıradaki seans', 'Next performance'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg),
                            child: sessionsPending
                                ? HomeFeaturedTicketSkeleton(
                                    layout: ticketLayout)
                                : HomeFeaturedTicket(
                                    key: ValueKey(
                                        featured!.session?.event.id ??
                                            featured!.show.id),
                                    featured: featured!,
                                    layout: ticketLayout,
                                    onOpen: () => _openShow(featured!.show),
                                  ),
                          ),
                        ),

                      // Ruh hâline göre: sahnedeki oyunların gerçek türleri.
                      if (shows.isNotEmpty)
                        _MobileSection(
                          title: homeText(context, 'Bugün ne izlemek istersin?',
                              'What are you in the mood for?'),
                          child: HomeMoodPicker(
                              shows: shows, padding: gutter),
                        ),

                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            gutter.left, AppSpacing.xxl, gutter.right, 0),
                        child: const HomeNearbyInvite(),
                      ),

                      // Şu an sahnede — sinematik afiş kartları.
                      if (activeShows.isNotEmpty)
                        _MobileSection(
                          title: l10n.homeActiveShowsSubtitle,
                          actionLabel: l10n.homeSeeAll,
                          onAction: () =>
                              NavigationHandler.goToDiscover(context),
                          child: HomeRail(
                            itemCount: activeShows.length,
                            itemWidth: 150,
                            height: 262,
                            padding: gutter,
                            itemBuilder: (final context, final i) =>
                                HomePosterCard(
                              show: activeShows[i],
                              onTap: () => _openShow(activeShows[i]),
                            ),
                          ),
                        ),

                      // Günün repliği — sayfaya nefes aldıran tipografi.
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            gutter.left, AppSpacing.section, gutter.right, 0),
                        child: const HomeQuoteOfDay(),
                      ),

                      if (sessions.isNotEmpty)
                        _MobileSection(
                          title: homeText(
                              context, 'Yaklaşan seanslar', 'Upcoming performances'),
                          child: HomeSessionBoard(
                            sessions: sessions,
                            onOpenShow: _openShow,
                            columns: isLargeScreen ? 2 : 1,
                            stripPadding: gutter,
                            listPadding: gutter,
                          ),
                        ),

                      // Sahnenin yüzleri — hikâye biçiminde oyuncular.
                      _MobileSection(
                        title: homeText(
                            context, 'Sahnenin yüzleri', 'Faces of the stage'),
                        actionLabel: l10n.homeSeeAll,
                        onAction: () => context.push('/search'),
                        child: HomePlayerStories(padding: gutter),
                      ),

                      if (repertoire.isNotEmpty)
                        _MobileSection(
                          title: homeText(context, 'Repertuvar', 'Repertoire'),
                          actionLabel: l10n.homeSeeAll,
                          onAction: () =>
                              NavigationHandler.goToDiscover(context),
                          child: Padding(
                            padding: gutter,
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: repertoire.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isLargeScreen ? 3 : 2,
                                mainAxisSpacing: AppSpacing.xl,
                                crossAxisSpacing: AppSpacing.lg,
                                childAspectRatio: 0.64,
                              ),
                              itemBuilder: (final context, final i) =>
                                  HomePosterCard(
                                show: repertoire[i],
                                onTap: () => _openShow(repertoire[i]),
                              ),
                            ),
                          ),
                        ),

                      if (stages.isNotEmpty)
                        _MobileSection(
                          title: l10n.homeVenuesSubtitle,
                          child: HomeRail(
                            itemCount: stages.length,
                            itemWidth: 240,
                            height: 210,
                            padding: gutter,
                            itemBuilder: (final context, final i) =>
                                HomeStageCard(
                              stage: stages[i],
                              onTap: () => NavigationHandler.goToStage(
                                  context, stages[i].id, stages[i].name),
                            ),
                          ),
                        ),

                      _MobileSection(
                        title: l10n.homeTeamsTitle,
                        child: const HomeTeamsStrip(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  int _unreadCount() {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final uid = ref.watch(currentUserIdProvider) ?? '';
    return isLoggedIn ? ref.watch(unreadNotificationCountProvider(uid)) : 0;
  }

  // --- APPBAR ---

  /// Telefon: aşağı kaydırılınca üstte kompakt arama belirir.
  PreferredSizeWidget _buildDynamicAppBar() => AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: _showSearchInAppBar ? 72 : 0,
        flexibleSpace: SafeArea(
          child: AnimatedSwitcher(
            duration: AppMotion.fast,
            child: _showSearchInAppBar
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl, vertical: AppSpacing.sm + 4),
                    child: HomeSearchField(
                      onTap: _openSearch,
                      hint: AppLocalizations.of(context)!
                          .homeHeroSearchPlaceholder,
                      compact: true,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      );

  /// Tablet: sabit üst çubuk — arama + bildirimler + ayarlar.
  PreferredSizeWidget _buildWebAppBar(final BuildContext context) {
    final unreadCount = _unreadCount();
    return AppBar(
      backgroundColor: context.colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: HomeSearchField(
          onTap: _openSearch,
          hint: AppLocalizations.of(context)!.homeHeroSearchPlaceholder,
          compact: true,
        ),
      ),
      actions: [
        IconButton(
          tooltip: homeText(context, 'Biletlerim', 'My tickets'),
          onPressed: _openTickets,
          icon: const Icon(Icons.confirmation_number_outlined),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context)!.homeTooltipNotifications,
          onPressed: _openNotifications,
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
            child: const Icon(Icons.notifications_none_rounded),
          ),
        ),
        IconButton(
            tooltip: AppLocalizations.of(context)!.homeTooltipSettings,
            onPressed: () => NavigationHandler.goToSettings(context),
            icon: const Icon(Icons.person_outline_rounded)),
        const SizedBox(width: AppSpacing.lg),
      ],
    );
  }

  Widget _buildErrorWidget(final BuildContext context, final WidgetRef ref) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.theater_comedy_outlined,
                  size: 80, color: context.colors.outline),
              const SizedBox(height: AppSpacing.xxl),
              Text(AppLocalizations.of(context)!.homeErrorTitleMobile,
                  textAlign: TextAlign.center,
                  style: context.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.xxxl),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(campaignsProvider);
                  ref.invalidate(showsProvider);
                  ref.invalidate(stagesProvider);
                },
                icon: const Icon(Icons.refresh),
                label: Text(AppLocalizations.of(context)!.homeErrorRetryMobile),
              ),
            ],
          ),
        ),
      );
}

/// Telefonun üst satırı: marka + Biletlerim + Bildirimler (48dp hedefler).
class _MobileTopBar extends StatelessWidget {
  final int unreadCount;
  final VoidCallback onTickets;
  final VoidCallback onNotifications;

  const _MobileTopBar({
    required this.unreadCount,
    required this.onTickets,
    required this.onNotifications,
  });

  @override
  Widget build(final BuildContext context) {
    final cs = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.sm, AppSpacing.sm, AppSpacing.lg),
      child: Row(
        children: [
          Icon(Icons.theater_comedy_rounded, size: 20, color: cs.primary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'TİYATROL',
            style: GoogleFonts.playfairDisplay(
              color: cs.onSurface,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: homeText(context, 'Biletlerim', 'My tickets'),
            onPressed: onTickets,
            icon: const Icon(Icons.confirmation_number_outlined),
            color: cs.onSurface,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.homeTooltipNotifications,
            onPressed: onNotifications,
            color: cs.onSurface,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(unreadCount > 9 ? '9+' : '$unreadCount'),
              child: const Icon(Icons.notifications_none_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mobil bölüm: başlık (yan boşluklu) + içerik (şeritler kendi iç
/// boşluklarını taşır, ekran kenarına kadar akar).
class _MobileSection extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget child;

  const _MobileSection({
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.huge + AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, 0, AppSpacing.sm, AppSpacing.md),
              child: HomeSectionHeader(
                title: title,
                actionLabel: actionLabel,
                onAction: onAction,
              ),
            ),
            child,
          ],
        ),
      );
}
