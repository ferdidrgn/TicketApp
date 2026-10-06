import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/admin_test_entry.dart';
import '../widgets/common/home_showcase.dart';

import '../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../core/util/responsive_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/background/shimmer_components.dart';
import '../../../../shared/widgets/footers/footer.dart';
import '../../../../shared/widgets/global_error_widget.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../campaigns/domain/entities/campaign.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../../../tickets/presentation/providers/my_ticket_provider.dart';
import '../providers/home_sessions_provider.dart';
import '../providers/home_show_filter_provider.dart';
import '../widgets/common/home_ticket_widgets.dart';
import '../widgets/common/home_ui.dart';

/// ANA SAYFA — WEB. "Gişe": platformun bilet gişesi, giriş ekranındaki
/// onaylı "bilet dili"yle.
///
/// Yapı (tek isim: GİŞE PANOSU) — az ama güçlü bölüm:
/// 1. Gişe: sayfanın TEK başlık anı (Playfair, soldan sağa açılış) + arama
///    + gerçek en yakın seansın büyük giriş bileti (birincil aksiyon: koçan
///    üstündeki "Bilet al" damgası; basınca koçan yırtılır).
/// 2. Yaklaşan seanslar: gün şeridi + seçili günün seans koçanları.
/// 3. Repertuvar: sinematik afiş ızgarası (`HomePosterCard`).
/// 4. Kampanyalar ve 5. Şehrin sahneleri: sürüklenebilir şeritler (veri
///    varsa).
/// Footer.
///
/// Kırılımlar gerçekten farklı kompozisyon: masaüstü (≥1024) başlık solda /
/// arama sağda + tam genişlik YATAY bilet (büyük afiş), seanslar 3 sütun,
/// ızgara; tablet (768–1023) üst üste başlık + yatay bilet (küçük afiş),
/// seanslar 2 sütun, ızgara; dar (<768) DİKEY bilet, seanslar tek sütun,
/// oyunlar yatay şerit.
///
/// `BasePageWrapper` kullanmadığı için kendi `Scaffold`'unu kurar. Renkler
/// temadan (`colorScheme`); bilet kağıdı/mürekkebi `TicketInk`'ten.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  // Sayfanın tek koreografili anı: başlık açılır, ardından bilet yerleşir.
  late final AnimationController _entrance =
      AnimationController(vsync: this, duration: AppMotion.slow);
  late final Animation<double> _headline = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.8, curve: AppMotion.dramatic));
  late final Animation<double> _rest = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.35, 1.0, curve: AppMotion.standard));
  bool _started = false;
  String? _mood;

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

  void _openSearch() => NavigationHandler.goToSearch(context);

  void _openShow(final Show show) =>
      NavigationHandler.goToShow(context, show.id, show.name);

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
    final cs = Theme.of(context).colorScheme;
    final campaignState = ref.watch(campaignsProvider);
    // Ana sayfa filtresi: SADECE TiyatRol + Ataşehir Tiyatro Topluluğu
    // oyunları (+ harici biletli konuk oyunlar), en yeni eklenen önce (bkz.
    // home_show_filter_provider.dart). Arama/keşfet bu filtreye tabi değil.
    final showState = ref.watch(homeShowsActiveFirstProvider(true));
    final stageState = ref.watch(stagesProvider(isLimit: true));
    // Gerçek yaklaşan seanslar (öne çıkan bilet + seans panosu). İkincil:
    // sayfanın genel yükleniyor/hata durumunu etkilemez.
    final sessionsState = ref.watch(homeUpcomingSessionsProvider);

    final bool isLoading =
        campaignState.isLoading || showState.isLoading || stageState.isLoading;
    final bool hasError =
        campaignState.hasError || showState.hasError || stageState.hasError;

    final List<Campaign> campaigns = campaignState.value ?? const [];
    final List<Show> shows = showState.value ?? const [];
    final List<Stage> stages = stageState.value ?? const [];
    final List<HomeSession> sessions = sessionsState.value ?? const [];
    final bool sessionsPending =
        sessionsState.isLoading && sessionsState.value == null;

    // "Sıradaki biletin" bağlantısı — kullanıcının GERÇEK en yakın bileti.
    final loggedIn = ref.watch(isLoggedInProvider);
    final uid = ref.watch(currentUserIdProvider);
    final ticketsAsync = uid == null
        ? const AsyncValue<List<DetailedTicket>>.data(<DetailedTicket>[])
        : ref.watch(myTicketsProvider(uid));

    final bool showLoadingState = isLoading && showState.value == null;
    final List<HomeSlide> slides = HomeSlide.build(
      context,
      campaigns: campaigns,
      shows: shows,
      onShow: _openShow,
    );

    final Widget body;
    if (hasError) {
      body = GlobalErrorWidget(
        isFullPage: false,
        title: AppLocalizations.of(context)!.homeErrorTitleWeb,
        message: AppLocalizations.of(context)!.homeErrorMessageWeb,
        onRetry: () {
          ref.invalidate(campaignsProvider);
          ref.invalidate(showsActiveFirstProvider);
          ref.invalidate(stagesProvider);
        },
      );
    } else if (showLoadingState) {
      body = const _WebLoadingState();
    } else {
      final List<Show> board = _mood == null
          ? shows
          : shows
              .where((final s) =>
                  s.category.trim().toLowerCase() == _mood!.toLowerCase())
              .toList();
      final double sectionGap = homeFluid(context, 28, 56);
      body = SingleChildScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WebHero(
              headline: _headline,
              rest: _rest,
              featured: sessionsPending ? null : pickHomeFeatured(sessions, shows),
              featuredPending: sessionsPending,
              showCount: sessions.map((final s) => s.show.id).toSet().length,
              stageCount: sessions
                  .where((final s) => s.stage != null)
                  .map((final s) => s.stage!.id)
                  .toSet()
                  .length,
              nextTicketShowName: loggedIn
                  ? _firstUpcomingShowName(ticketsAsync.value)
                  : null,
              onSearch: _openSearch,
              onTickets: _goToTickets,
              onOpenShow: _openShow,
            ),
            HomeContinueTicket(
              shows: shows,
              padding: EdgeInsets.fromLTRB(
                  _gutter(context), AppSpacing.xl, _gutter(context), 0),
            ),
            if (shows.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(
                    _gutter(context), AppSpacing.lg, _gutter(context), 0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
                    child: HomePlaybillBoard(
                      shows: shows,
                      onOpen: _openShow,
                    ),
                  ),
                ),
              ),
            if (slides.isNotEmpty)
              _WebSection(
                topGap: sectionGap,
                title: homeText(context, 'Öne çıkanlar', 'Highlights'),
                bleedRail: true,
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: _kMaxContentWidth + 2 * _gutter(context)),
                    child: HomeSpotlightCarousel(
                      slides: slides,
                      height: context.isDesktop ? 420 : 320,
                      padding:
                          EdgeInsets.symmetric(horizontal: _gutter(context)),
                    ),
                  ),
                ),
              ),
            if (shows.isNotEmpty)
              _WebSection(
                topGap: sectionGap,
                title: homeText(context, 'Bugün ne izlemek istersin?',
                    'What are you in the mood for?'),
                bleedRail: true,
                child: HomeMoodPicker(
                  shows: shows,
                  padding: EdgeInsets.symmetric(horizontal: _gutter(context)),
                  selected: _mood,
                  onSelected: (final cat) => setState(() => _mood = cat),
                ),
              ),
            if (sessions.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: sectionGap),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: _kMaxContentWidth + 2 * _gutter(context)),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: _gutter(context)),
                      child: HomeWeekPulse(
                        sessions: sessions,
                        onTap: () => NavigationHandler.goToNearby(context),
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.only(top: sectionGap),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: _kMaxContentWidth + 2 * _gutter(context)),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: _gutter(context)),
                    child: const HomeNearbyInvite(),
                  ),
                ),
              ),
            ),
            if (sessions.isNotEmpty)
              _WebSection(
                topGap: sectionGap,
                title: homeText(context, 'Yaklaşan seanslar', 'Upcoming performances'),
                child: HomeSessionBoard(
                  sessions: sessions,
                  onOpenShow: _openShow,
                  columns: context.isDesktop ? 3 : (context.isTablet ? 2 : 1),
                  dayArrows: context.isDesktop,
                ),
              ),
            _WebSection(
              topGap: sectionGap,
              title: homeText(context, 'Repertuvar', 'Repertoire'),
              actionLabel: shows.isEmpty
                  ? null
                  : AppLocalizations.of(context)!.homeSeeAll,
              onAction: () => NavigationHandler.goToDiscover(context),
              child: board.isEmpty
                  ? _EmptyHint(
                      text: AppLocalizations.of(context)!.homeEmptyShowsHint)
                  : _ShowsGrid(shows: board, onOpenShow: _openShow),
            ),
            Padding(
              padding: EdgeInsets.only(top: sectionGap),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: _gutter(context)),
                    child: const HomeQuoteOfDay(),
                  ),
                ),
              ),
            ),
            _WebSection(
              topGap: sectionGap,
              title: homeText(
                  context, 'Sahnenin yüzleri', 'Faces of the stage'),
              bleedRail: true,
              child: HomePlayerStories(
                padding: EdgeInsets.symmetric(horizontal: _gutter(context)),
              ),
            ),
            if (stages.isNotEmpty)
              _WebSection(
                topGap: sectionGap,
                title: AppLocalizations.of(context)!.homeVenuesSubtitle,
                bleedRail: true,
                child: HomeRail(
                  itemCount: stages.length,
                  itemWidth: context.isMobile ? 240 : 280,
                  height: context.isMobile ? 220 : 240,
                  showArrows: context.isDesktop,
                  padding: EdgeInsets.symmetric(horizontal: _gutter(context)),
                  itemBuilder: (final context, final i) => HomeStageCard(
                    stage: stages[i],
                    onTap: () => NavigationHandler.goToStage(
                        context, stages[i].id, stages[i].name),
                  ),
                ),
              ),
            SizedBox(height: sectionGap),
            const Footer(),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: TicketStage(
        themed: true,
        child: Column(
          children: [
            // Geçici: admin test girişi (release derlemesinde görünmez).
            const AdminTestStrip(),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// YARDIMCILAR
// ═══════════════════════════════════════════════════════════════

/// Sayfa kenar boşluğu: dar 16 · tablet 32 · masaüstü 64.
double _gutter(final BuildContext context) => context.isDesktop
    ? AppSpacing.section
    : (context.isTablet ? AppSpacing.xxxl : AppSpacing.lg);

const double _kMaxContentWidth = 1280;

/// Kullanıcının en yakın GELECEK biletinin oyun adı (varsa) —
/// `myTicketsProvider`'ın getirdiği gerçek `DetailedTicket` listesinden.
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

/// Ortalanmış, en fazla 1280 (+ kenar boşlukları) genişlikte bölüm: başlık +
/// içerik. [bleedRail] açıkken içerik (yatay şerit) kenar boşluğunu kendi
/// `padding`'inde taşır; ilk kart başlıkla hizalı başlar, kaydırılınca kutu
/// kenarına kadar akar.
class _WebSection extends StatelessWidget {
  final double topGap;
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget child;
  final bool bleedRail;

  const _WebSection({
    required this.topGap,
    required this.title,
    required this.child,
    this.actionLabel,
    this.onAction,
    this.bleedRail = false,
  });

  @override
  Widget build(final BuildContext context) {
    final double gutter = _gutter(context);
    final Widget header = Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      child: HomeSectionHeader(
        title: title,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Center(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: _kMaxContentWidth + 2 * gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: AppSpacing.xl),
              if (bleedRail)
                child
              else
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: child,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.huge, horizontal: AppSpacing.xxl),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15, height: 1.5),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GİŞE (HERO)
// ═══════════════════════════════════════════════════════════════

class _WebHero extends StatelessWidget {
  final Animation<double> headline;
  final Animation<double> rest;
  final HomeFeatured? featured;
  final bool featuredPending;
  final int showCount;
  final int stageCount;
  final String? nextTicketShowName;
  final VoidCallback onSearch;
  final VoidCallback onTickets;
  final ValueChanged<Show> onOpenShow;

  const _WebHero({
    required this.headline,
    required this.rest,
    required this.featured,
    required this.featuredPending,
    required this.showCount,
    required this.stageCount,
    required this.nextTicketShowName,
    required this.onSearch,
    required this.onTickets,
    required this.onOpenShow,
  });

  Widget _settle(final Widget child) => AnimatedBuilder(
        animation: rest,
        builder: (final context, final c) => Opacity(
          opacity: rest.value,
          child: Transform.translate(
            offset: Offset(0, (1 - rest.value) * 32),
            child: c,
          ),
        ),
        child: child,
      );

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final double width = MediaQuery.sizeOf(context).width;
    final bool desktop = width >= ResponsiveUtils.tabletBreakpoint;
    final bool tablet = !desktop && width >= ResponsiveUtils.mobileBreakpoint;
    final HomeTicketLayout layout = desktop
        ? HomeTicketLayout.wide
        : (tablet ? HomeTicketLayout.medium : HomeTicketLayout.compact);
    final double gutter = _gutter(context);

    final Widget title = Semantics(
      header: true,
      child: AuthWipeReveal(
        reveal: headline,
        child: Text(
          l10n.homeHeroHeadline,
          style: GoogleFonts.playfairDisplay(
            color: cs.onSurface,
            fontSize: homeFluid(context, 36, 68),
            fontWeight: FontWeight.w800,
            height: 1.04,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );

    final Widget lede = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Text(
        showCount > 0 && stageCount > 0
            ? l10n.homeHeroLedeWithCounts(stageCount, showCount)
            : l10n.homeHeroLedeFallback,
        style: TextStyle(
          color: cs.onSurfaceVariant,
          fontSize: desktop ? 16.5 : 15,
          height: 1.55,
        ),
      ),
    );

    final Widget search = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: HomeSearchField(
        onTap: onSearch,
        hint: l10n.homeHeroSearchPlaceholder,
      ),
    );

    final Widget? myTicket = nextTicketShowName == null
        ? null
        : Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onTickets,
              icon: const Icon(Icons.confirmation_number_outlined, size: 20),
              label: Text(
                l10n.homeTicketsNext(nextTicketShowName!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: TextButton.styleFrom(
                foregroundColor: cs.primary,
                minimumSize: const Size(48, 48),
                textStyle:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          );

    final Widget intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        lede,
        const SizedBox(height: AppSpacing.xl),
        search,
        if (myTicket != null) ...[
          const SizedBox(height: AppSpacing.sm),
          myTicket,
        ],
      ],
    );

    final Widget? ticket = featuredPending
        ? HomeFeaturedTicketSkeleton(layout: layout)
        : (featured == null
            ? null
            : HomeFeaturedTicket(
                key: ValueKey(featured!.session?.event.id ?? featured!.show.id),
                featured: featured!,
                layout: layout,
                onOpen: () => onOpenShow(featured!.show),
              ));

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _kMaxContentWidth + 2 * gutter),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              gutter, homeFluid(context, 32, 72), gutter, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (desktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(flex: 7, child: title),
                    const SizedBox(width: AppSpacing.section),
                    Expanded(flex: 5, child: _settle(intro)),
                  ],
                )
              else ...[
                title,
                const SizedBox(height: AppSpacing.lg),
                _settle(intro),
              ],
              if (ticket != null) ...[
                SizedBox(height: desktop ? AppSpacing.massive : AppSpacing.xxxl),
                _settle(ticket),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// REPERTUVAR
// ═══════════════════════════════════════════════════════════════

/// Masaüstü/tablet: sinematik afiş ızgarası (sütun sayısı genişlikten);
/// dar ekran: fare ile de sürüklenebilen yatay şerit.
class _ShowsGrid extends StatelessWidget {
  final List<Show> shows;
  final ValueChanged<Show> onOpenShow;

  const _ShowsGrid({required this.shows, required this.onOpenShow});

  @override
  Widget build(final BuildContext context) {
    if (context.isMobile)
      return HomeRail(
        itemCount: shows.length,
        itemWidth: 168,
        height: 256,
        itemBuilder: (final context, final i) => HomePosterCard(
          show: shows[i],
          onTap: () => onOpenShow(shows[i]),
        ),
      );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      itemCount: shows.length,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: context.isDesktop ? 248 : 224,
        mainAxisSpacing: AppSpacing.xxl,
        crossAxisSpacing: AppSpacing.xl,
        childAspectRatio: 0.66,
      ),
      itemBuilder: (final context, final i) => HomePosterCard(
        show: shows[i],
        onTap: () => onOpenShow(shows[i]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// YÜKLENİYOR
// ═══════════════════════════════════════════════════════════════

/// İlk veri gelene kadar sayfanın kaba şeklinde parıltılı iskelet (başlık,
/// bilet, kart sırası) — çıplak spinner yok.
class _WebLoadingState extends StatelessWidget {
  const _WebLoadingState();

  @override
  Widget build(final BuildContext context) {
    final double gutter = _gutter(context);
    final bool desktop = context.isDesktop;
    return ExcludeSemantics(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
            gutter, homeFluid(context, 32, 72), gutter, AppSpacing.massive),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLoading(height: 48, width: 420, borderRadius: 8),
                const SizedBox(height: AppSpacing.md),
                const ShimmerLoading(height: 48, width: 300, borderRadius: 8),
                const SizedBox(height: AppSpacing.massive),
                ShimmerLoading(
                  height: desktop ? 330 : 480,
                  width: double.infinity,
                  borderRadius: AppRadius.md,
                ),
                const SizedBox(height: AppSpacing.massive),
                SizedBox(
                  height: 260,
                  child: Row(
                    children: List.generate(
                      desktop ? 5 : 2,
                      (final i) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              right: i == (desktop ? 4 : 1) ? 0 : AppSpacing.xl),
                          child: const ShimmerLoading(
                            height: 260,
                            width: double.infinity,
                            borderRadius: AppRadius.sm,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
