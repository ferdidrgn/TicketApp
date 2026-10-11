import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/util/date_formatter.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/admin_test_entry.dart';
import '../../../../../shared/widgets/motion/stage_entrance.dart';
import '../../../../../shared/widgets/rive/tiyatrol_rive.dart';
import '../../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../../../shared/widgets/sahne/petal_chart.dart';
import '../../../../../shared/widgets/tiyatrol_hero.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../campaigns/domain/entities/campaign.dart';
import '../../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../../discovery/presentation/widgets/browse_controls.dart';
import '../../../../notifications/presentation/providers/notification_provider.dart';
import '../../../../players/presentation/providers/player_provider.dart';
import '../../../../shows/domain/entities/show.dart';
import '../../../../shows/presentation/providers/recommended_shows_provider.dart';
import '../../../../stages/domain/entities/stage.dart';
import '../../../../stages/presentation/providers/stage_provider.dart';
import '../../../../teams/domain/entities/team.dart';
import '../../../../teams/presentation/providers/team_provider.dart';
import '../../../../tickets/presentation/providers/my_ticket_provider.dart';
import '../../../../users/presentation/providers/user_provider.dart';
import '../../providers/home_sessions_provider.dart';
import '../../providers/home_show_filter_provider.dart';
import '../common/home_showcase.dart';
import '../common/home_ui.dart';

/// ANA SAYFA — "Sahne". Telefon, tablet ve web için tek duyarlı yüzey.
class HomeExperience extends ConsumerStatefulWidget {
  final ScrollController controller;

  /// Başlıktaki bilet/bildirim kısayolları (web'de üst menü zaten var).
  final bool showActions;
  final Widget? footer;
  final Future<void> Function()? onRefresh;

  const HomeExperience({
    super.key,
    required this.controller,
    this.showActions = true,
    this.footer,
    this.onRefresh,
  });

  @override
  ConsumerState<HomeExperience> createState() => _HomeExperienceState();
}

enum _Range { tonight, tomorrow, weekend, week }

class _HomeExperienceState extends ConsumerState<HomeExperience> {
  DateTime? _day; // takvimde seçili gün
  _Range? _range; // hızlı tarih çipi
  String? _genre;
  double? _budget; // bütçe kadranı süzgeci (₺)
  final GlobalKey _programmeKey = GlobalKey();
  final GlobalKey _searchKey = GlobalKey();
  bool _searchPinned = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScrollForSearch);
  }

  @override
  void didUpdateWidget(covariant final HomeExperience oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScrollForSearch);
      widget.controller.addListener(_onScrollForSearch);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScrollForSearch);
    super.dispose();
  }

  void _onScrollForSearch() {
    final BuildContext? ctx = _searchKey.currentContext;
    if (ctx == null) return;
    final RenderObject? ro = ctx.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize) return;
    final double top = ro.localToGlobal(Offset.zero).dy;
    final double pinBelow = MediaQuery.paddingOf(context).top + 8;
    final bool pin = top < pinBelow - 4;
    if (pin != _searchPinned) setState(() => _searchPinned = pin);
  }

  void _openShow(final Show show, {final String from = 'home'}) =>
      NavigationHandler.goToShow(
        context,
        show.id,
        show.name,
        heroTag: TiyatrolHeroTags.show(show.id, from),
        imageUrl: show.imageUrl,
        title: show.name,
      );

  void _refresh() {
    ref.invalidate(campaignsProvider);
    ref.invalidate(homeShowsActiveFirstProvider(true));
    ref.invalidate(homeActiveShowsProvider(true));
    ref.invalidate(stagesProvider(isLimit: true));
    ref.invalidate(homeUpcomingSessionsProvider);
    ref.invalidate(playersProvider());
    ref.invalidate(teamsProvider(isLimit: true));
  }

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

  void _scrollToProgramme() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final BuildContext? c = _programmeKey.currentContext;
      if (c == null) return;
      Scrollable.ensureVisible(
        c,
        duration: Sk.reduceMotion(context)
            ? Duration.zero
            : const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        alignment: 0.02,
      );
    });
  }

  bool _inRange(final DateTime d, final _Range r) {
    final DateTime now = DateTime.now();
    final DateTime today = skDay(now);
    final DateTime day = skDay(d);
    switch (r) {
      case _Range.tonight:
        return day == today && !d.isBefore(now);
      case _Range.tomorrow:
        return day == today.add(const Duration(days: 1));
      case _Range.weekend:
        // Geçmiş hafta sonlarını dahil etme (negatif fark < 14 tuzağı).
        return !day.isBefore(today) &&
            day.difference(today).inDays < 14 &&
            (d.weekday == DateTime.saturday || d.weekday == DateTime.sunday);
      case _Range.week:
        return !d.isBefore(now) && day.difference(today).inDays < 7;
    }
  }

  /// Hızlı Seans & Koltuk Seçim Çekmecesi
  void _openQuickSessionSheet(
      final Show show, final List<HomeSession> showSessions) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (final ctx) => _QuickBookingSheet(
        show: show,
        sessions: showSessions,
        onSessionTap: (final s) {
          Navigator.pop(ctx);
          _openShow(show, from: 'quick-booking');
        },
      ),
    );
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final showState = ref.watch(homeShowsActiveFirstProvider(true));
    final activeShowState = ref.watch(homeActiveShowsProvider(true));
    final sessionsState = ref.watch(homeUpcomingSessionsProvider);
    final stageState = ref.watch(stagesProvider(isLimit: true));
    final campaignState = ref.watch(campaignsProvider);
    final teamState = ref.watch(teamsProvider(isLimit: true));
    final profile = ref.watch(userProfileProvider).value;
    final bool loggedIn = ref.watch(isLoggedInProvider);
    final String uid = ref.watch(currentUserIdProvider) ?? '';
    final List<DetailedTicket> tickets = loggedIn && uid.isNotEmpty
        ? (ref.watch(myTicketsProvider(uid)).value ?? const <DetailedTicket>[])
        : const <DetailedTicket>[];

    final List<Show> shows = showState.value ?? const [];
    final List<Show> activeShows = activeShowState.value ?? const [];
    final List<HomeSession> sessions = sessionsState.value ?? const [];
    final List<Stage> stages = stageState.value ?? const [];
    final List<Campaign> campaigns = campaignState.value ?? const [];
    final List<Team> teams = teamState.value ?? const [];

    final bool loading = (showState.isLoading && shows.isEmpty) ||
        (sessionsState.isLoading && sessions.isEmpty && shows.isEmpty);
    final bool failed = showState.hasError && shows.isEmpty;

    final List<BrowseCategory> genres = browseCategoriesOf(shows);

    // Banner slaytları
    final Set<String> seen = {};
    final List<HomeFeatured> slides = [];
    for (final HomeSession s in sessions) {
      if (seen.add(s.show.id)) {
        slides.add(HomeFeatured(show: s.show, session: s));
      }
      if (slides.length >= 6) break;
    }
    if (slides.length < 3) {
      for (final Show s in [...activeShows, ...shows]) {
        if (seen.add(s.id)) slides.add(HomeFeatured(show: s));
        if (slides.length >= 6) break;
      }
    }

    double? priceOf(final HomeSession s) =>
        double.tryParse(s.event.price.trim().replaceAll(',', '.'));

    // Takvim: gün / hızlı çip / bütçe + tür süzgeci
    final List<HomeSession> programme = sessions.where((final s) {
      if (_day != null && s.day != _day) return false;
      if (_range != null && !_inRange(s.date, _range!)) return false;
      if (_genre != null && browseCategoryKey(s.show.category) != _genre) {
        return false;
      }
      if (_budget != null && (priceOf(s) ?? double.infinity) > _budget!) {
        return false;
      }
      return true;
    }).toList();

    // Bütçe kadranı için seansların gerçek bilet fiyatları.
    final List<double> prices = [
      for (final HomeSession s in sessions)
        if ((priceOf(s) ?? 0) > 0) priceOf(s)!,
    ];

    int count(final _Range r) =>
        sessions.where((final s) => _inRange(s.date, r)).length;
    final Map<_Range, int> rangeCounts = {
      for (final _Range r in _Range.values) r: count(r),
    };

    final List<Show> fresh =
        shows.where((final s) => s.isRecentlyAdded).take(12).toList();
    final Set<String> cheapSeen = {};
    final List<HomeSession> cheap = ([
      for (final HomeSession s in sessions)
        if ((priceOf(s) ?? 0) > 0) s,
    ]..sort((final a, final b) => priceOf(a)!.compareTo(priceOf(b)!)))
        .where((final s) => cheapSeen.add(s.show.id))
        .take(12)
        .toList();


    DetailedTicket? nextTicket;
    DateTime? nextTicketDate;
    for (final DetailedTicket t in tickets) {
      if (t.isPast || t.show == null || t.event == null) continue;
      final DateTime? d = DateFormatter.parseDateString(t.event!.date);
      if (d == null || d.isBefore(DateTime.now())) continue;
      if (nextTicketDate == null || d.isBefore(nextTicketDate)) {
        nextTicket = t;
        nextTicketDate = d;
      }
    }

    final List<HomeSession> tonight =
        sessions.where((final s) => _inRange(s.date, _Range.tonight)).toList();

    final Set<String> favIds =
        (profile?.favoriteShows ?? const <String>[]).toSet();
    final List<Show> favoriteShows = [
      for (final Show s in [...activeShows, ...shows])
        if (favIds.contains(s.id)) s,
    ].take(12).toList();

    final List<Show> guestShows = [
      for (final Show s in [...activeShows, ...shows])
        if (s.hasExternalTicketing) s,
    ].take(12).toList();


    final List<Show> forYou =
        ref.watch(recommendedShowsProvider).value ?? const <Show>[];

    final String firstName = (profile?.firstName ?? '').trim();

    return LayoutBuilder(builder: (final context, final box) {
      final double w = box.maxWidth;
      final double gutter = Sk.gutter(w);
      final bool wide = w >= 900;

      Widget pad(final Widget child) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Sk.maxWidth),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: child,
              ),
            ),
          );

      Widget rail(final Widget child) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Sk.maxWidth),
              child: child,
            ),
          );

      Widget gap(final Widget child, [final double top = 40]) =>
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: top),
              child: StageEntrance.bounce(child: child),
            ),
          );

      Widget sessionRail(
        final String key,
        final String title,
        final String subtitle,
        final IconData icon,
        final List<HomeSession> items,
      ) =>
          SkRail<HomeSession>(
            key: ValueKey<String>(key),
            title: title,
            subtitle: subtitle,
            icon: icon,
            items: items,
            gutter: gutter,
            railW: 308,
            railH: 154,
            minCell: 308,
            builder: (final s, final cw) => _SessionCard(
              session: s,
              width: cw,
              heroFrom: 'home-$key',
              onTap: () => _openShow(s.show, from: 'home-$key'),
              onQuickBook: () => _openQuickSessionSheet(
                s.show,
                sessions.where((final x) => x.show.id == s.show.id).toList(),
              ),
            ),
          );

      Widget showRail(
        final String key,
        final String title,
        final String subtitle,
        final IconData icon,
        final List<Show> items,
      ) {
        final double pw = wide ? 210 : 158;
        return SkRail<Show>(
          key: ValueKey<String>(key),
          title: title,
          subtitle: subtitle,
          icon: icon,
          items: items,
          gutter: gutter,
          railW: pw,
          railH: pw * 1.5,
          minCell: pw,
          builder: (final s, final cw) => _PosterCard(
            show: s,
            width: cw,
            heroFrom: 'home-$key',
            onTap: () => _openShow(s, from: 'home-$key'),
          ),
        );
      }

      final Widget scroll = ScrollConfiguration(
        behavior: const SkScrollBehavior(),
        child: CustomScrollView(
          controller: widget.controller,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            const SliverToBoxAdapter(child: AdminTestStrip()),
            SliverToBoxAdapter(
              child: SafeArea(
                bottom: false,
                child: pad(_AppBar(
                  loggedIn: loggedIn,
                  name: firstName,
                  imageUrl: profile?.imageUrl ?? '',
                  tonight: sessions
                      .where((final s) => _inRange(s.date, _Range.tonight))
                      .length,
                  showActions: widget.showActions,
                  unread: loggedIn
                      ? ref.watch(unreadNotificationCountProvider(uid))
                      : 0,
                  onTickets: _openTickets,
                  onNotifications: _openNotifications,
                  onAvatarTap: () {
                    HapticFeedback.selectionClick();
                    if (loggedIn) {
                      NavigationHandler.goToProfile(context);
                    } else {
                      NavigationHandler.goToLogin(context);
                    }
                  },
                )),
              ),
            ),

            // Işıyan kenar + daktilo ipucu — dokununca arama sayfası
            SliverToBoxAdapter(
              child: pad(Padding(
                key: _searchKey,
                padding: const EdgeInsets.only(top: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HomeSearchField(
                      onTap: () => NavigationHandler.goToSearch(context),
                      hint: 'Oyun, oyuncu veya sahne ara',
                    ),
                    if (sessions.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _RangeChips(
                        gutter: 0,
                        selected: _range,
                        counts: rangeCounts,
                        onPick: (final r) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _range = _range == r ? null : r;
                            _day = null;
                          });
                          if (_range != null) _scrollToProgramme();
                        },
                      ),
                    ],
                  ],
                ),
              )),
            ),

            if (failed) ...[
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 420,
                  child: SkEmpty(
                    icon: Icons.cloud_off_rounded,
                    title: 'Program yüklenemedi',
                    message:
                        'Bağlantını kontrol edip tekrar dene; perde birazdan açılır.',
                    actionLabel: 'Tekrar dene',
                    onAction: _refresh,
                  ),
                ),
              )
            ] else if (loading) ...[
              SliverToBoxAdapter(child: pad(const _HomeSkeleton()))
            ] else ...[
              // 1. Hareketli vitrin (Spotlight Carousel)
              Builder(builder: (final context) {
                final List<HomeSlide> spotlight = HomeSlide.build(
                  context,
                  campaigns: campaigns,
                  shows: [
                    for (final HomeFeatured f in slides) f.show,
                    ...activeShows,
                    ...shows,
                  ],
                  onShow: (final s) => _openShow(s, from: 'home-spotlight'),
                );
                if (spotlight.isEmpty) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return gap(
                  HomeSpotlightCarousel(
                    slides: spotlight,
                    height: wide ? 310 : 240,
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                  ),
                  20,
                );
              }),

              // Sıradaki Bilet
              if (nextTicket != null)
                gap(
                  pad(_NextTicket(
                    ticket: nextTicket,
                    date: nextTicketDate!,
                    onTap: _openTickets,
                  )),
                  22,
                ),

              // Seyirci karnem (gerçek biletlerden) — Smart_home'daki özet kartı
              if (loggedIn && uid.isNotEmpty)
                gap(
                  pad(_StatsCard(tickets: tickets, onTap: _openTickets)),
                  14,
                ),

              // Bütçe kadranı — Smart_home'daki daire kaydırıcı
              if (prices.length >= 2)
                gap(
                  pad(_BudgetCard(
                    key: ValueKey<double?>(_budget),
                    prices: prices,
                    applied: _budget,
                    onApply: (final b) {
                      HapticFeedback.mediumImpact();
                      setState(() {
                        _budget = b;
                        _day = null;
                        _range = null;
                      });
                      if (b != null) _scrollToProgramme();
                    },
                  )),
                  22,
                ),

              // Zevk çiçeği — kullanıcının izlediği türlerin payı (gerçek biletler)
              if (_tasteCounts(tickets).length >= 2)
                gap(
                  pad(_TasteFlower(
                    counts: _tasteCounts(tickets),
                    imageUrl: profile?.imageUrl ?? '',
                  )),
                  30,
                ),

              // 9. Tür Halkaları
              if (genres.length > 1)
                gap(
                  rail(_Genres(
                    genres: genres,
                    selected: _genre,
                    gutter: gutter,
                    onPick: (final g) {
                      HapticFeedback.selectionClick();
                      setState(() => _genre = _genre == g ? null : g);
                      _scrollToProgramme();
                    },
                  )),
                  32,
                ),

              // 10. Program & Gün Takvimi
              if (sessions.isNotEmpty)
                gap(
                  KeyedSubtree(
                    key: _programmeKey,
                    child: rail(_ProgrammeSection(
                      gutter: gutter,
                      sessions: sessions,
                      programme: programme,
                      selectedDay: _day,
                      hasFilter: _genre != null || _range != null || _budget != null,
                      wide: wide,
                      onDay: (final d) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _day = d;
                          _range = null;
                        });
                      },
                      onOpen: (final s) =>
                          _openShow(s.show, from: 'home-programme'),
                      onQuickBook: (final s) => _openQuickSessionSheet(
                        s.show,
                        sessions
                            .where((final x) => x.show.id == s.show.id)
                            .toList(),
                      ),
                      onClear: () => setState(() {
                        _day = null;
                        _range = null;
                        _genre = null;
                        _budget = null;
                      }),
                    )),
                  ),
                  36,
                ),

              // 11. Sana Özel ve Favoriler
              if (forYou.isNotEmpty)
                gap(
                  rail(showRail(
                    'foryou',
                    'Sana özel',
                    'Favorilerin ve biletlerine yakın oyunlar',
                    Icons.auto_awesome_rounded,
                    forYou.take(12).toList(),
                  )),
                ),
              if (favoriteShows.isNotEmpty)
                gap(
                  rail(showRail(
                    'favorites',
                    'Favorilerin',
                    'Kayıtlı oyunlarına hızlı dönüş',
                    Icons.favorite_rounded,
                    favoriteShows,
                  )),
                ),

              // 12. Hafta Sonu & Yeni Eklenenler
              if (fresh.isNotEmpty)
                gap(
                  rail(showRail(
                      'fresh',
                      'Yeni eklenenler',
                      'Programa yeni giren oyunlar',
                      Icons.auto_awesome_rounded,
                      fresh)),
                ),

              // 13. Uygun Fiyatlı Seanslar
              if (cheap.length >= 2)
                gap(
                  rail(sessionRail(
                      'cheap',
                      'Uygun fiyatlı seanslar',
                      'En düşük bilet fiyatından başlayarak',
                      Icons.savings_rounded,
                      cheap)),
                ),

              // 17. Günün Repliği
              gap(pad(const HomeQuoteOfDay()), 36),

              // 18. Sahnenin Yüzleri
              if ((ref.watch(playersProvider()).value ?? const [])
                  .any((final p) => p.firstName.trim().isNotEmpty)) ...[
                gap(
                  pad(const HomeSectionHeader(title: 'Sahnenin yüzleri')),
                  28,
                ),
                gap(
                  HomePlayerStories(
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                  ),
                  12,
                ),
              ],

              // 19. Başka Platformlar, Mekânlar ve Ekipler
              if (guestShows.isNotEmpty)
                gap(
                  rail(showRail(
                    'guest',
                    'Başka platformda',
                    'Biletleri dışarıda satılan oyunlar',
                    Icons.open_in_new_rounded,
                    guestShows,
                  )),
                ),
              if (stages.isNotEmpty)
                gap(rail(_Venues(stages: stages, gutter: gutter, wide: wide))),
              if (teams.isNotEmpty)
                gap(rail(_Troupes(teams: teams, gutter: gutter))),

              gap(
                HomeClosingInvite(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                ),
                36,
              ),
            ],
            SliverToBoxAdapter(
              child: widget.footer ?? const SizedBox(height: 130),
            ),
          ],
        ),
      );

      final Widget scroller = widget.onRefresh == null
          ? scroll
          : RefreshIndicator(onRefresh: widget.onRefresh!, child: scroll);

      return ColoredBox(
        color: cs.surface,
        child: Stack(
          children: [
            scroller,
            // Sabit Üst Arama Barı
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_searchPinned,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  offset: _searchPinned ? Offset.zero : const Offset(0, -1.2),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _searchPinned ? 1 : 0,
                    child: Material(
                      elevation: _searchPinned ? 6 : 0,
                      color: cs.surface.withValues(alpha: 0.94),
                      child: SafeArea(
                        bottom: false,
                        child: pad(Padding(
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
                          child: HomeSearchField(
                            onTap: () =>
                                NavigationHandler.goToSearch(context),
                            hint: 'Oyun, oyuncu veya sahne ara',
                            compact: true,
                          ),
                        )),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HIZLI BİLET / SEANS SEÇİM SHEET'İ
// ═════════════════════════════════════════════════════════════════════════════

class _QuickBookingSheet extends StatelessWidget {
  final Show show;
  final List<HomeSession> sessions;
  final ValueChanged<HomeSession> onSessionTap;

  const _QuickBookingSheet({
    required this.show,
    required this.sessions,
    required this.onSessionTap,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.paddingOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SkImage(url: show.imageUrl, width: 50, height: 70, radius: 12),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      show.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.display(context, size: 18, height: 1.15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${show.category} · ${sessions.length} aktif seans',
                      style:
                          Sk.ui(context, size: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Seans Seç ve Koltuğa İlerle',
            style: Sk.ui(context,
                size: 13, weight: FontWeight.w800, color: cs.primary),
          ),
          const SizedBox(height: 10),
          if (sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Bu oyun için henüz listelenmiş seans bulunmuyor.',
                  style: Sk.ui(context, size: 13, color: cs.onSurfaceVariant),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sessions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final s = sessions[i];
                  return Container(
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 2),
                      title: Text(
                        '${skDayPhrase(s.date)} · ${skClock(s.date)}',
                        style:
                            Sk.ui(context, size: 13.5, weight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        s.stage?.name ?? 'Sahne Belirtilmemiş',
                        style: Sk.ui(context,
                            size: 12, color: cs.onSurfaceVariant),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (s.priceLabel != null)
                            Text(
                              s.priceLabel!,
                              style: Sk.ui(context,
                                  size: 14,
                                  weight: FontWeight.w900,
                                  color: cs.primary),
                            ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: cs.onSurfaceVariant),
                        ],
                      ),
                      onTap: () => onSessionTap(s),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// UYGULAMA ÇUBUĞU
// ═════════════════════════════════════════════════════════════════════════════

class _AppBar extends StatelessWidget {
  final bool loggedIn;
  final String name;
  final String imageUrl;
  final int tonight;
  final bool showActions;
  final int unread;
  final VoidCallback onTickets;
  final VoidCallback onNotifications;
  final VoidCallback onAvatarTap;

  const _AppBar({
    required this.loggedIn,
    required this.name,
    required this.imageUrl,
    required this.tonight,
    required this.showActions,
    required this.unread,
    required this.onTickets,
    required this.onNotifications,
    required this.onAvatarTap,
  });

  String get _greeting {
    final int h = DateTime.now().hour;
    return h < 6
        ? 'İyi geceler'
        : (h < 12 ? 'Günaydın' : (h < 18 ? 'İyi günler' : 'İyi akşamlar'));
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool guest = !loggedIn;
    // Misafir: sahte "Hoş geldin / Merhaba misafir" yok — saat dilimine göre
    // selam + kısa program ipucu. Girişli: ad + bilet/bildirim.
    final String title = guest
        ? _greeting
        : (name.isEmpty ? _greeting : name);
    final String subtitle = tonight > 0
        ? 'Bu akşam $tonight perde'
        : (guest ? 'Programı keşfet' : _greeting);
    final String initial =
        name.isEmpty ? '' : name.characters.first.toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          PressScale(
            onTap: onAvatarTap,
            semanticLabel: guest ? 'Giriş yap' : 'Profil',
            child: Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [cs.primary, cs.tertiary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
              ),
              child: Container(
                decoration:
                    BoxDecoration(color: cs.surface, shape: BoxShape.circle),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: !guest && imageUrl.trim().startsWith('http')
                      ? SkImage(
                          url: imageUrl, fallbackIcon: Icons.person_rounded)
                      : Container(
                          color: cs.primaryContainer,
                          alignment: Alignment.center,
                          child: guest
                              ? Icon(Icons.person_outline_rounded,
                                  color: cs.onPrimaryContainer, size: 24)
                              : (initial.isEmpty
                                  ? Icon(Icons.person_rounded,
                                      color: cs.onPrimaryContainer, size: 24)
                                  : Text(initial,
                                      style: Sk.display(context,
                                          size: 20,
                                          color: cs.onPrimaryContainer,
                                          height: 1.0))),
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Sk.display(context, size: 22, height: 1.1),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Sk.ui(context,
                      size: 13,
                      color: cs.onSurfaceVariant,
                      weight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (showActions) ...[
            if (guest)
              PressScale(
                onTap: onAvatarTap,
                semanticLabel: 'Giriş yap',
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    'Giriş',
                    style: Sk.ui(context,
                        size: 14,
                        color: cs.onPrimary,
                        weight: FontWeight.w800),
                  ),
                ),
              )
            else ...[
              _RoundBtn(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Biletlerim',
                  onTap: onTickets),
              const SizedBox(width: 8),
              _RoundBtn(
                  icon: Icons.notifications_none_rounded,
                  label: 'Bildirimler',
                  onTap: onNotifications,
                  badge: unread),
            ],
          ],
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  const _RoundBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return PressScale(
      onTap: onTap,
      semanticLabel: label,
      child: Tooltip(
        message: label,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh, shape: BoxShape.circle),
                child: SkSpinIn(
                    child: Icon(icon, size: 22, color: cs.onSurface)),
              ),
              if (badge > 0)
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(badge > 9 ? '9+' : '$badge',
                        style: Sk.ui(context,
                            size: 10,
                            color: cs.onPrimary,
                            weight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HIZLI TARİH ÇİPLERİ
// ═════════════════════════════════════════════════════════════════════════════

class _RangeChips extends StatelessWidget {
  final double gutter;
  final _Range? selected;
  final Map<_Range, int> counts;
  final ValueChanged<_Range> onPick;

  const _RangeChips({
    required this.gutter,
    required this.selected,
    required this.counts,
    required this.onPick,
  });

  static const List<(_Range, String, IconData)> _items = [
    (_Range.tonight, 'Bu akşam', Icons.nights_stay_rounded),
    (_Range.tomorrow, 'Yarın', Icons.wb_twilight_rounded),
    (_Range.weekend, 'Hafta sonu', Icons.weekend_rounded),
    (_Range.week, 'Bu hafta', Icons.date_range_rounded),
  ];

  @override
  Widget build(final BuildContext context) {
    final List<(_Range, String, IconData)> items = [
      for (final it in _items)
        if ((counts[it.$1] ?? 0) > 0) it,
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: gutter),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (final context, final i) {
          final (_Range r, String label, IconData icon) = items[i];
          return SkChip(
            label: label,
            icon: icon,
            count: counts[r],
            selected: selected == r,
            onTap: () => onPick(r),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SIRADAKİ BİLETİN
// ═════════════════════════════════════════════════════════════════════════════

class _NextTicket extends StatelessWidget {
  final DetailedTicket ticket;
  final DateTime date;
  final VoidCallback onTap;

  const _NextTicket(
      {required this.ticket, required this.date, required this.onTap});

  String _countdown() {
    final int days = skDay(date).difference(skDay(DateTime.now())).inDays;
    if (days <= 0) {
      final Duration left = date.difference(DateTime.now());
      return left.inHours >= 1 ? '${left.inHours} saat sonra' : 'Birazdan';
    }
    return days == 1 ? 'Yarın' : '$days gün sonra';
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Show show = ticket.show!;
    final String venue = (ticket.stage?.name ?? '').trim();
    return PressScale(
      onTap: onTap,
      semanticLabel: 'Sıradaki biletin: ${show.name}',
      scale: 0.99,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [cs.primaryContainer, cs.tertiaryContainer],
          ),
          boxShadow: skSoftShadow(context, strength: 0.7),
        ),
        child: Row(
          children: [
            SkImage(url: show.imageUrl, width: 62, height: 86, radius: 16),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sıradaki biletin',
                      style: Sk.ui(context,
                          size: 12,
                          color: cs.onPrimaryContainer.withValues(alpha: 0.75),
                          weight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(show.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.display(context,
                          size: 18,
                          color: cs.onPrimaryContainer,
                          height: 1.12)),
                  const SizedBox(height: 5),
                  Text(
                    [
                      '${skDayPhrase(date)} · ${skClock(date)}',
                      if (venue.isNotEmpty) venue,
                    ].join('  ·  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Sk.ui(context,
                        size: 12.5,
                        color: cs.onPrimaryContainer.withValues(alpha: 0.85),
                        weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(_countdown(),
                  style: Sk.ui(context,
                      size: 12.5,
                      color: cs.onSurface,
                      weight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}


// ═════════════════════════════════════════════════════════════════════════════
// BÜTÇE KADRANI (Smart_home'daki daire kaydırıcının TiyatRol uyarlaması)
// ═════════════════════════════════════════════════════════════════════════════

/// Dairenin ucunu sürükle → bütçe değişir, kaç gerçek seansın o fiyata
/// uyduğu anında güncellenir. "Takvimde göster" takvimi bu bütçeyle süzer.
class _BudgetCard extends StatefulWidget {
  final List<double> prices; // seansların gerçek bilet fiyatları
  final double? applied;
  final ValueChanged<double?> onApply;

  const _BudgetCard({
    super.key,
    required this.prices,
    required this.applied,
    required this.onApply,
  });

  @override
  State<_BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends State<_BudgetCard> {
  double _v = 0.6;

  double get _max {
    final double m = widget.prices.fold<double>(0, (a, b) => b > a ? b : a);
    return ((m / 50).ceil() * 50).clamp(50, 5000).toDouble();
  }

  double get _budget => ((_v * _max) / 10).round() * 10.0;

  int get _fits => widget.prices.where((final p) => p <= _budget).length;

  @override
  void initState() {
    super.initState();
    if (widget.applied != null) {
      _v = (widget.applied! / _max).clamp(0.0, 1.0);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final int fits = _fits;
    final bool applied = widget.applied != null;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(32),
        boxShadow: skSoftShadow(context, strength: 0.7),
      ),
      child: Row(
        children: [
          SkDial(
            size: 156,
            value: _v,
            semanticLabel: 'Bütçe',
            semanticValue: '${_budget.toInt()} lira',
            onChanged: (final v) => setState(() => _v = v),
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('₺${_budget.toInt()}',
                    style: Sk.display(context, size: 30, height: 1.0)),
                const SizedBox(height: 4),
                Text('bütçe',
                    style: Sk.ui(context,
                        size: 12,
                        color: cs.onSurfaceVariant,
                        weight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Bütçene göre bul',
                    style: Sk.display(context, size: 20, height: 1.1)),
                const SizedBox(height: 4),
                Text('Dairenin ucunu sürükle',
                    style: Sk.ui(context,
                        size: 12.5,
                        color: cs.onSurfaceVariant,
                        weight: FontWeight.w600)),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (final c, final a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, 0.3), end: Offset.zero)
                          .animate(a),
                      child: c,
                    ),
                  ),
                  layoutBuilder: (final current, final previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, if (current != null) current],
                  ),
                  child: Container(
                    key: ValueKey<int>(fits),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      fits == 0 ? 'Uygun seans yok' : '$fits seans uygun',
                      style: Sk.ui(context,
                          size: 12.5,
                          color: cs.onPrimaryContainer,
                          weight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Flexible(
                      child: FilledButton(
                        onPressed: fits == 0
                            ? null
                            : () => widget.onApply(_budget),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          applied ? 'Güncelle' : 'Takvimde göster',
                          maxLines: 1,
                          style: Sk.ui(context,
                              size: 13,
                              color: cs.onPrimary,
                              weight: FontWeight.w800),
                        ),
                      ),
                    ),
                    if (applied) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: 'Bütçe süzgecini kaldır',
                        onPressed: () => widget.onApply(null),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// KARNEM KARTI (Smart_home'daki "electricity" kartı şekli)
// ═════════════════════════════════════════════════════════════════════════════

/// Gerçek biletlerden: izlenen farklı oyun sayısı + rütbe. Dokununca biletlere.
class _StatsCard extends StatelessWidget {
  final List<DetailedTicket> tickets;
  final VoidCallback onTap;

  const _StatsCard({required this.tickets, required this.onTap});

  static const List<(int, String)> _ranks = [
    (0, 'Yeni Seyirci'),
    (1, 'Seyirci'),
    (3, 'Müdavim'),
    (6, 'Tiyatro Kurdu'),
    (10, 'Sahne Tozu Yutmuş'),
  ];

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Set<String> seen = {
      for (final DetailedTicket t in tickets)
        if (t.isPast && t.show != null) t.show!.id,
    };
    final int count = seen.length;
    int ri = 0;
    for (int i = 0; i < _ranks.length; i++) {
      if (count >= _ranks[i].$1) ri = i;
    }
    final (int, String)? next = ri + 1 < _ranks.length ? _ranks[ri + 1] : null;
    final String caption = next == null
        ? 'Seyirci karnen · ${_ranks[ri].$2}'
        : '${_ranks[ri].$2} · ${next.$2} için ${next.$1 - count} perde kaldı';

    return PressScale(
      onTap: onTap,
      semanticLabel: 'Seyirci karnem: $count perde',
      scale: 0.985,
      child: Container(
        height: 104,
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(28),
          boxShadow: skSoftShadow(context, strength: 0.7),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [cs.primary, cs.tertiary],
                ),
              ),
              child: SkSpinIn(
                child: Icon(Icons.confirmation_number_rounded,
                    color: cs.onPrimary, size: 28),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: count.toDouble()),
                    duration: Sk.reduceMotion(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (final context, final v, _) => Text(
                      '${v.round()} perde',
                      style: Sk.display(context, size: 24, height: 1.05),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.ui(context,
                          size: 12.5,
                          color: cs.onSurfaceVariant,
                          weight: FontWeight.w600,
                          height: 1.25)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.arrow_forward_rounded,
                  color: cs.onSecondaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}

/// Geçmiş biletlerden tür → izlenen farklı oyun sayısı.
Map<String, int> _tasteCounts(final List<DetailedTicket> tickets) {
  final Map<String, Set<String>> byCat = {};
  for (final DetailedTicket t in tickets) {
    final Show? sh = t.show;
    if (!t.isPast || sh == null || sh.category.trim().isEmpty) continue;
    byCat.putIfAbsent(sh.category.trim(), () => <String>{}).add(sh.id);
  }
  return {for (final e in byCat.entries) e.key: e.value.length};
}

class _TasteFlower extends StatelessWidget {
  final Map<String, int> counts;
  final String imageUrl;

  const _TasteFlower({required this.counts, required this.imageUrl});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<MapEntry<String, int>> top = (counts.entries.toList()
          ..sort((final a, final b) => b.value.compareTo(a.value)))
        .take(6)
        .toList();
    final int total = counts.values.fold<int>(0, (a, b) => a + b);
    final int max = top.first.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkSectionHead(
          title: 'Zevk çiçeğin',
          subtitle: 'İzlediğin oyunların tür dağılımı',
          icon: Icons.local_florist_rounded,
        ),
        const SizedBox(height: 8),
        Center(
          child: LayoutBuilder(builder: (final context, final box) {
            final double size = box.maxWidth < 340 ? box.maxWidth : 340;
            return SkPetalChart(
              size: size,
              hint: 'Yaprağa dokun: o türden kaç oyun izledin',
              semanticLabel: 'Zevk çiçeğin: ${top.length} tür',
              center: imageUrl.startsWith('http')
                  ? SkImage(url: imageUrl, fallbackIcon: Icons.person_rounded)
                  : Container(
                      color: cs.primaryContainer,
                      child: Icon(Icons.person_rounded,
                          color: cs.onPrimaryContainer, size: size * 0.11)),
              petals: [
                for (final MapEntry<String, int> e in top)
                  SkPetal(
                    label: e.key,
                    value: '%${(e.value * 100 / total).round()}',
                    weight: (e.value / max).clamp(0.3, 1.0),
                  ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(final BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: TiyatrolRiveLoader(size: 56, caption: 'Perde açılıyor…'),
            ),
            SizedBox(height: 18),
            SkBone(height: 56, radius: 28),
            SizedBox(height: 20),
            SkBone(height: 236, radius: 28),
            SizedBox(height: 18),
            SkBone(height: 92, radius: 20),
            SizedBox(height: 18),
            SkBone(height: 118, radius: 24),
            SizedBox(height: 22),
            SkBone(height: 72, radius: 18),
            SizedBox(height: 22),
            SkBone(height: 280, radius: 28),
            SizedBox(height: 24),
            SkBone(height: 146, radius: 28),
          ],
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// TÜR HALKALARI
// ═════════════════════════════════════════════════════════════════════════════

class _Genres extends StatelessWidget {
  final List<BrowseCategory> genres;
  final String? selected;
  final double gutter;
  final ValueChanged<String> onPick;

  const _Genres({
    required this.genres,
    required this.selected,
    required this.gutter,
    required this.onPick,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: const SkSectionHead(
              title: 'Türlere göz at',
              subtitle: 'Seçtiğin tür takvimi süzer',
              icon: Icons.category_rounded),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: gutter),
            itemCount: genres.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (final context, final i) {
              final BrowseCategory g = genres[i];
              final bool on = selected == g.key;
              return SizedBox(
                width: 76,
                child: PressScale(
                  onTap: () => onPick(g.key),
                  semanticLabel: g.label,
                  scale: 0.93,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: on
                              ? LinearGradient(colors: [
                                  cs.primary,
                                  cs.tertiary,
                                ])
                              : null,
                          color: on
                              ? null
                              : cs.outlineVariant.withValues(alpha: 0.5),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                              color: cs.surface, shape: BoxShape.circle),
                          child: ClipOval(
                            child:
                                SkImage(url: g.imageUrl, width: 62, height: 62),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(g.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.ui(context,
                              size: 12.5,
                              color: on ? cs.primary : cs.onSurface,
                              weight: on ? FontWeight.w900 : FontWeight.w700)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PROGRAM — gün şeridi + yatay seans şeridi
// ═════════════════════════════════════════════════════════════════════════════

class _ProgrammeSection extends StatelessWidget {
  final List<HomeSession> sessions;
  final List<HomeSession> programme;
  final DateTime? selectedDay;
  final bool hasFilter;
  final bool wide;
  final double gutter;
  final ValueChanged<DateTime?> onDay;
  final ValueChanged<HomeSession> onOpen;
  final ValueChanged<HomeSession>? onQuickBook;
  final VoidCallback onClear;

  const _ProgrammeSection({
    required this.sessions,
    required this.programme,
    required this.selectedDay,
    required this.hasFilter,
    required this.wide,
    required this.gutter,
    required this.onDay,
    required this.onOpen,
    this.onQuickBook,
    required this.onClear,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final DateTime today = skDay(DateTime.now());

    // Noktalar: yaklaşan tüm seans günleri (üst filtre tür/aralık parent'ta).
    final Map<DateTime, int> counts = {};
    for (final HomeSession s in sessions) {
      counts[s.day] = (counts[s.day] ?? 0) + 1;
    }
    final List<DateTime> days = [
      for (int i = 0; i < 21; i++) today.add(Duration(days: i)),
    ];

    bool sameDay(final DateTime? a, final DateTime b) =>
        a != null && a.year == b.year && a.month == b.month && a.day == b.day;

    // Gölge/ölçek taşması ListView tarafından kırpılmasın (kare "kutu" hissi).
    final Widget strip = SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.symmetric(horizontal: gutter, vertical: 6),
        itemCount: days.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (final context, final i) {
          if (i == 0) {
            return _DayTile(
              top: 'Hepsi',
              big: '${sessions.length}',
              selected: selectedDay == null,
              enabled: true,
              onTap: () => onDay(null),
            );
          }
          final DateTime d = days[i - 1];
          final int c = counts[d] ?? 0;
          return _DayTile(
            top: i == 1 ? 'Bugün' : kDaysShortTr[d.weekday - 1],
            big: '${d.day}',
            dot: c > 0,
            selected: sameDay(selectedDay, d),
            enabled: true,
            onTap: () => onDay(sameDay(selectedDay, d) ? null : d),
          );
        },
      ),
    );

    if (programme.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter),
            child: const SkSectionHead(
                title: 'Takvim',
                subtitle: 'Perde açılmadan önce',
                icon: Icons.calendar_month_rounded),
          ),
          const SizedBox(height: 16),
          strip,
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, 18, gutter, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                children: [
                  Icon(Icons.event_busy_rounded,
                      color: cs.onSurfaceVariant, size: 30),
                  const SizedBox(height: 10),
                  Text('Bu seçimde seans yok',
                      style: Sk.ui(context, size: 15, weight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Başka bir gün ya da tür seçebilirsin.',
                      style: Sk.ui(context,
                          size: 13,
                          color: cs.onSurfaceVariant,
                          weight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  TextButton(
                      onPressed: onClear,
                      child: const Text('Süzgeçleri temizle')),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return SkRail<HomeSession>(
      key: ValueKey<String>('programme|$selectedDay|$hasFilter'),
      title: 'Takvim',
      subtitle: '${programme.length} seans · perde açılmadan önce',
      icon: Icons.calendar_month_rounded,
      items: programme,
      gutter: gutter,
      railW: 308,
      railH: 154,
      minCell: 308,
      belowHeader: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: strip,
      ),
      builder: (final s, final w) => _SessionCard(
        session: s,
        width: w,
        onTap: () => onOpen(s),
        onQuickBook: onQuickBook != null ? () => onQuickBook!(s) : null,
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final String top;
  final String big;
  final bool selected;
  final bool enabled;
  final bool dot;
  final VoidCallback onTap;

  const _DayTile({
    required this.top,
    required this.big,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.dot = false,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool reduce = Sk.reduceMotion(context);
    final Color fg = selected
        ? cs.onPrimary
        : (enabled ? cs.onSurface : cs.onSurface.withValues(alpha: 0.35));
    // Seçili halde kırpılan drop-shadow yok — hafif büyüme + dolgu.
    return PressScale(
      onTap: enabled ? onTap : null,
      semanticLabel: '$top $big',
      scale: 0.94,
      child: AnimatedScale(
        scale: selected && !reduce ? 1.04 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: 64,
          decoration: BoxDecoration(
            color: selected ? cs.primary : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? Colors.transparent
                  : cs.outlineVariant.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(top,
                  style: Sk.ui(context,
                      size: 11.5,
                      color: fg.withValues(alpha: selected ? 0.85 : 0.7),
                      weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(big,
                  style: Sk.display(context,
                      size: 24,
                      color: fg,
                      height: 1.0,
                      weight: FontWeight.w700)),
              const SizedBox(height: 5),
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dot
                      ? (selected ? cs.onPrimary : cs.primary)
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Yatay seans kartı: Hızlı Bilet Seçim Düğmesi ile Geliştirildi
class _SessionCard extends StatelessWidget {
  final HomeSession session;
  final double width;
  final VoidCallback onTap;
  final VoidCallback? onQuickBook;
  final String heroFrom;

  const _SessionCard({
    required this.session,
    required this.width,
    required this.onTap,
    this.onQuickBook,
    this.heroFrom = 'home-programme',
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Show show = session.show;
    final String venue = (session.stage?.name ?? '').trim();
    final DateTime d = session.date;
    return PressScale(
      onTap: onTap,
      semanticLabel: '${show.name}, ${skClock(d)}',
      scale: 0.985,
      child: SizedBox(
        width: width,
        height: 154,
        child: SkSoftCard(
          radius: 24,
          shadowStrength: 0.85,
          child: Row(
            children: [
              SizedBox(
                width: 104,
                height: 154,
                child: TiyatrolHero(
                  tag: TiyatrolHeroTags.show(show.id, heroFrom),
                  child: SkImage(url: show.imageUrl),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${skDayPhrase(d)} · ${skClock(d)}',
                              style: Sk.ui(context,
                                  size: 11.5,
                                  color: cs.onPrimaryContainer,
                                  weight: FontWeight.w900),
                            ),
                          ),
                          if (session.priceLabel != null)
                            Text(
                              session.priceLabel!,
                              style: Sk.ui(context,
                                  size: 12.5,
                                  weight: FontWeight.w900,
                                  color: cs.primary),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(show.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.display(context,
                              size: 16.5,
                              height: 1.15,
                              weight: FontWeight.w700)),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              venue.isNotEmpty ? venue : 'Sahne',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Sk.ui(context,
                                  size: 11.5,
                                  color: cs.onSurfaceVariant,
                                  weight: FontWeight.w600),
                            ),
                          ),
                          if (onQuickBook != null)
                            PressScale(
                              onTap: onQuickBook!,
                              scale: 0.94,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: cs.outlineVariant
                                          .withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.confirmation_number_outlined,
                                        size: 12, color: cs.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Seç',
                                      style: Sk.ui(context,
                                          size: 11,
                                          color: cs.primary,
                                          weight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                              ),
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
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ŞERİTLER
// ═════════════════════════════════════════════════════════════════════════════

class _PosterCard extends StatelessWidget {
  final Show show;
  final double width;
  final VoidCallback onTap;
  final String heroFrom;

  const _PosterCard({
    required this.show,
    required this.width,
    required this.onTap,
    this.heroFrom = 'home-shelf',
  });

  @override
  Widget build(final BuildContext context) => PressScale(
        onTap: onTap,
        semanticLabel: show.name,
        child: Container(
          width: width,
          height: width * 1.5,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: skSoftShadow(context),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                TiyatrolHero(
                  tag: TiyatrolHeroTags.show(show.id, heroFrom),
                  child: SkImage(url: show.imageUrl),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.84),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
                if (show.hasExternalTicketing)
                  const Positioned(
                    left: 10,
                    top: 10,
                    child: SkBadge(
                        label: 'Başka platform',
                        onImage: true,
                        icon: Icons.open_in_new_rounded),
                  )
                else if (show.isRecentlyAdded)
                  const Positioned(
                    left: 10,
                    top: 10,
                    child: SkBadge(label: 'Yeni', accent: true),
                  ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (show.category.trim().isNotEmpty)
                        Text(show.category.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Sk.ui(context,
                                size: 11.5,
                                color: Colors.white70,
                                weight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(show.name,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.display(context,
                              size: 18, color: Colors.white, height: 1.1)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _Venues extends StatelessWidget {
  final List<Stage> stages;
  final double gutter;
  final bool wide;

  const _Venues(
      {required this.stages, required this.gutter, required this.wide});

  @override
  Widget build(final BuildContext context) {
    final double w = wide ? 340 : 276;
    return SkRail<Stage>(
      title: 'Mekânlar',
      subtitle: 'Perdenin açıldığı sahneler',
      items: stages,
      gutter: gutter,
      railW: w,
      railH: 190,
      minCell: w,
      builder: (final s, final cw) => PressScale(
        onTap: () => NavigationHandler.goToStage(context, s.id, s.name,
            heroTag: TiyatrolHeroTags.stage(s.id, 'home'),
            imageUrl: s.imageUrl,
            title: s.name),
        semanticLabel: s.name,
        child: Container(
          width: cw,
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: skSoftShadow(context),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              fit: StackFit.expand,
              children: [
                TiyatrolHero(
                  tag: TiyatrolHeroTags.stage(s.id, 'home'),
                  child: SkImage(
                      url: s.imageUrl,
                      fallbackIcon: Icons.location_city_rounded),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.35, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.display(context,
                              size: 21, color: Colors.white, height: 1.1)),
                      if (s.address.trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Row(
                            children: [
                              const Icon(Icons.place_rounded,
                                  size: 14, color: Colors.white70),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(s.address.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Sk.ui(context,
                                        size: 12,
                                        color: Colors.white70,
                                        weight: FontWeight.w600)),
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
      ),
    );
  }
}

class _Troupes extends StatelessWidget {
  final List<Team> teams;
  final double gutter;

  const _Troupes({required this.teams, required this.gutter});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SkRail<Team>(
      title: 'Topluluklar',
      subtitle: 'Perdeyi açan ekipler',
      items: teams,
      gutter: gutter,
      railW: 96,
      railH: 128,
      minCell: 96,
      builder: (final t, final w) => SizedBox(
        width: 96,
        child: PressScale(
          onTap: () => NavigationHandler.goToTeam(context, t.id, t.name,
              imageUrl: t.imageUrl, title: t.name),
          semanticLabel: t.name,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(colors: [
                    cs.primary,
                    cs.tertiary,
                    cs.secondary,
                    cs.primary,
                  ]),
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration:
                      BoxDecoration(color: cs.surface, shape: BoxShape.circle),
                  child: ClipOval(
                    child: SkImage(
                        url: t.imageUrl,
                        width: 72,
                        height: 72,
                        fallbackIcon: Icons.groups_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(t.name,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: Sk.ui(context,
                      size: 12, weight: FontWeight.w800, height: 1.2)),
            ],
          ),
        ),
      ),
    );
  }
}
