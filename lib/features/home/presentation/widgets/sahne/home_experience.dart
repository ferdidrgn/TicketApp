import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/util/date_formatter.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/admin_test_entry.dart';
import '../../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../../../shared/widgets/tiyatrol_hero.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../campaigns/domain/entities/campaign.dart';
import '../../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../../discovery/presentation/widgets/browse_controls.dart';
import '../../../../notifications/presentation/providers/notification_provider.dart';
import '../../../../players/presentation/providers/player_provider.dart';
import '../../../../shows/domain/entities/show.dart';
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
///
/// Fotoğraf odaklı keşif: ışıyan arama, hareketli vitrin, haftanın nabzı,
/// ruh hâli seçici, takvim, koleksiyon şeritleri, günün repliği, oyuncu
/// hikâyeleri, mekânlar ve topluluklar. Hepsi gerçek Firestore verisi.
/// Smart-home tarzı toggle panelleri yok.
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
    // Arama kendi yerinden yukarı çıkınca üstte sabit belirir;
    // yerine geri gelince kaybolur.
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
      Scrollable.ensureVisible(c,
          duration: Sk.reduceMotion(context)
              ? Duration.zero
              : const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          alignment: 0.02);
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
        return (d.weekday == DateTime.saturday ||
                d.weekday == DateTime.sunday) &&
            day.difference(today).inDays < 14;
      case _Range.week:
        return !d.isBefore(now) &&
            day.difference(today).inDays < 7;
    }
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

    // Banner: her oyunun EN YAKIN seansı; seans yoksa oyunun kendisi.
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

    // Takvim: gün / hızlı çip + tür süzgeci.
    final List<HomeSession> programme = sessions.where((final s) {
      if (_day != null && s.day != _day) return false;
      if (_range != null && !_inRange(s.date, _range!)) return false;
      if (_genre != null && browseCategoryKey(s.show.category) != _genre) {
        return false;
      }
      return true;
    }).toList();

    // Hızlı çip sayıları.
    int count(final _Range r) =>
        sessions.where((final s) => _inRange(s.date, r)).length;
    final Map<_Range, int> rangeCounts = {
      for (final _Range r in _Range.values) r: count(r),
    };

    // Koleksiyonlar (hepsi gerçek seans/oyun verisinden).
    final List<HomeSession> weekend = sessions
        .where((final s) => _inRange(s.date, _Range.weekend))
        .toList();
    final List<Show> fresh =
        shows.where((final s) => s.isRecentlyAdded).take(12).toList();
    double? priceOf(final HomeSession s) =>
        double.tryParse(s.event.price.trim().replaceAll(',', '.'));
    final Set<String> cheapSeen = {};
    final List<HomeSession> cheap = ([
      for (final HomeSession s in sessions)
        if ((priceOf(s) ?? 0) > 0) s,
    ]..sort((final a, final b) => priceOf(a)!.compareTo(priceOf(b)!)))
        .where((final s) => cheapSeen.add(s.show.id))
        .take(12)
        .toList();
    final List<BrowseCategory> topGenres =
        genres.where((final g) => g.count >= 2).take(2).toList();

    final Set<String> slideIds = slides.map((final f) => f.show.id).toSet();
    final Set<String> shelfSeen = {};
    final List<Show> shelf = [
      for (final Show s in [...activeShows, ...shows])
        if (!slideIds.contains(s.id) && shelfSeen.add(s.id)) s,
    ].take(12).toList();

    // Sıradaki bilet (gerçek).
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
            child: Padding(padding: EdgeInsets.only(top: top), child: child),
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
            railH: 146,
            minCell: 308,
            builder: (final s, final cw) => _SessionCard(
              session: s,
              width: cw,
              heroFrom: 'home-$key',
              onTap: () => _openShow(s.show, from: 'home-$key'),
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
                )),
              ),
            ),
            SliverToBoxAdapter(
              child: pad(Padding(
                key: _searchKey,
                padding: const EdgeInsets.only(top: 18),
                child: HomeSearchField(
                  onTap: () => NavigationHandler.goToSearch(context),
                  hint: 'Oyun, oyuncu veya sahne ara',
                ),
              )),
            ),
            if (failed)
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
            else if (loading)
              SliverToBoxAdapter(child: pad(const _HomeSkeleton()))
            else ...[
              // Hareketli vitrin — kampanya + sahnedeki oyunlar
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
                    height: wide ? 280 : 220,
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                  ),
                  22,
                );
              }),
              // Bu haftanın nabzı
              if (sessions.isNotEmpty)
                gap(
                  pad(HomeWeekPulse(
                    sessions: sessions,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _scrollToProgramme();
                    },
                  )),
                  18,
                ),
              if (sessions.isNotEmpty)
                gap(
                  rail(_RangeChips(
                    gutter: gutter,
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
                  )),
                  14,
                ),
              if (nextTicket != null)
                gap(
                  pad(_NextTicket(
                    ticket: nextTicket,
                    date: nextTicketDate!,
                    onTap: _openTickets,
                  )),
                  22,
                ),
              // Ruh hâline göre keşif (en az 2 farklı tür)
              if ({
                for (final Show s in [...activeShows, ...shows])
                  if (s.category.trim().isNotEmpty) s.category.trim(),
              }.length >=
                  2) ...[
                gap(
                  pad(const HomeSectionHeader(
                    title: 'Nasıl bir akşam?',
                  )),
                  28,
                ),
                gap(
                  HomeMoodPicker(
                    shows: [...activeShows, ...shows],
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                  ),
                  12,
                ),
              ],
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
              if (sessions.isNotEmpty)
                gap(
                  KeyedSubtree(
                    key: _programmeKey,
                    child: rail(_ProgrammeSection(
                      gutter: gutter,
                      sessions: sessions,
                      programme: programme,
                      selectedDay: _day,
                      hasFilter: _genre != null || _range != null,
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
                      onClear: () => setState(() {
                        _day = null;
                        _range = null;
                        _genre = null;
                      }),
                    )),
                  ),
                  36,
                ),
              if (weekend.isNotEmpty)
                gap(
                  rail(sessionRail(
                      'weekend',
                      'Hafta sonu planı',
                      'Cumartesi ve pazar perdeleri',
                      Icons.weekend_rounded,
                      weekend)),
                ),
              if (fresh.isNotEmpty)
                gap(
                  rail(showRail(
                      'fresh',
                      'Yeni eklenenler',
                      'Programa yeni giren oyunlar',
                      Icons.auto_awesome_rounded,
                      fresh)),
                ),
              if (cheap.length >= 2)
                gap(
                  rail(sessionRail(
                      'cheap',
                      'Uygun fiyatlı seanslar',
                      'En düşük bilet fiyatından başlayarak',
                      Icons.savings_rounded,
                      cheap)),
                ),
              for (final BrowseCategory g in topGenres)
                gap(
                  rail(showRail(
                    'genre-${g.key}',
                    '${g.label} seçmeleri',
                    '${g.count} oyun',
                    Icons.theater_comedy_rounded,
                    [
                      for (final Show s in shows)
                        if (browseCategoryKey(s.category) == g.key) s,
                    ],
                  )),
                ),
              if (shelf.isNotEmpty)
                gap(
                  rail(_PosterShelf(
                    shows: shelf,
                    gutter: gutter,
                    wide: wide,
                    onOpen: (final s) => _openShow(s, from: 'home-shelf'),
                    onAll: () => NavigationHandler.goToDiscover(context),
                  )),
                ),
              // Günün repliği — nefes alanı
              gap(pad(const HomeQuoteOfDay()), 36),
              // Oyuncu hikâyeleri (veri yoksa tamamen gizle)
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
              if (stages.isNotEmpty)
                gap(rail(_Venues(stages: stages, gutter: gutter, wide: wide))),
              if (teams.isNotEmpty)
                gap(rail(_Troupes(teams: teams, gutter: gutter))),
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
            // Aşağı kaydırınca arama üstte sabit; yerine gelince kaybolur.
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
// UYGULAMA ÇUBUĞU
// ═════════════════════════════════════════════════════════════════════════════

class _AppBar extends StatelessWidget {
  final String name;
  final String imageUrl;
  final int tonight;
  final bool showActions;
  final int unread;
  final VoidCallback onTickets;
  final VoidCallback onNotifications;

  const _AppBar({
    required this.name,
    required this.imageUrl,
    required this.tonight,
    required this.showActions,
    required this.unread,
    required this.onTickets,
    required this.onNotifications,
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
    final String initial = name.isEmpty ? 'T' : name.characters.first.toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Container(
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
                child: imageUrl.trim().startsWith('http')
                    ? SkImage(
                        url: imageUrl,
                        fallbackIcon: Icons.person_rounded)
                    : Container(
                        color: cs.primaryContainer,
                        alignment: Alignment.center,
                        child: Text(initial,
                            style: Sk.display(context,
                                size: 20,
                                color: cs.onPrimaryContainer,
                                height: 1.0)),
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
                  name.isEmpty ? _greeting : '$_greeting, $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Sk.display(context, size: 20, height: 1.1),
                ),
                const SizedBox(height: 3),
                Text(
                  tonight > 0
                      ? 'Bu akşam $tonight perde açılıyor'
                      : 'Bu hafta ne izlesek?',
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
                child: Icon(icon, size: 22, color: cs.onSurface),
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
    // Sadece seansı olan aralıklar gösterilir (boş çip yok).
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

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(final BuildContext context) => const Padding(
        padding: EdgeInsets.only(top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkBone(height: 44, radius: 22),
            SizedBox(height: 24),
            SkBone(height: 232, radius: 30),
            SizedBox(height: 28),
            SkBone(height: 84, radius: 24),
            SizedBox(height: 18),
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
                          color: on ? null : cs.outlineVariant.withValues(alpha: 0.5),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                              color: cs.surface, shape: BoxShape.circle),
                          child: ClipOval(
                            child: SkImage(
                                url: g.imageUrl, width: 62, height: 62),
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
// PROGRAM — gün şeridi + yatay seans şeridi (Tümü → aşağı açılır)
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
    required this.onClear,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final DateTime today = skDay(DateTime.now());

    final Map<DateTime, int> counts = {};
    for (final HomeSession s in sessions) {
      counts[s.day] = (counts[s.day] ?? 0) + 1;
    }
    final List<DateTime> days = [
      for (int i = 0; i < 14; i++) today.add(Duration(days: i)),
    ];

    final Widget strip = SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: gutter),
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
            selected: selectedDay == d,
            enabled: c > 0,
            onTap: () => onDay(d),
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
      railH: 146,
      minCell: 308,
      belowHeader: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: strip,
      ),
      builder: (final s, final w) =>
          _SessionCard(session: s, width: w, onTap: () => onOpen(s)),
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
    final Color fg = selected
        ? cs.onPrimary
        : (enabled ? cs.onSurface : cs.onSurface.withValues(alpha: 0.35));
    return PressScale(
      onTap: enabled ? onTap : null,
      semanticLabel: '$top $big',
      scale: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 64,
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : const [],
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
                    size: 24, color: fg, height: 1.0, weight: FontWeight.w700)),
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
    );
  }
}

/// Yatay seans kartı: solda afiş, sağda tarih rozeti, ad ve mekân.
class _SessionCard extends StatelessWidget {
  final HomeSession session;
  final double width;
  final VoidCallback onTap;
  final String heroFrom;

  const _SessionCard({
    required this.session,
    required this.width,
    required this.onTap,
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
      child: Container(
        width: width,
        height: 146,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(28),
          boxShadow: skSoftShadow(context, strength: 0.7),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Row(
            children: [
              SizedBox(
                width: 98,
                height: 146,
                child: TiyatrolHero(
                  tag: TiyatrolHeroTags.show(show.id, heroFrom),
                  child: SkImage(url: show.imageUrl),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${skDayPhrase(d)} · ${skClock(d)}',
                          style: Sk.ui(context,
                              size: 12,
                              color: cs.onPrimaryContainer,
                              weight: FontWeight.w900),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(show.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.display(context,
                              size: 17, height: 1.15, weight: FontWeight.w700)),
                      const Spacer(),
                      Text(
                        [
                          if (venue.isNotEmpty) venue,
                          if (session.priceLabel != null) session.priceLabel!,
                        ].join('  ·  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Sk.ui(context,
                            size: 12.5,
                            color: cs.onSurfaceVariant,
                            weight: FontWeight.w600),
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
// ŞERİTLER (hepsi SkRail: en fazla 10, Tümü → aşağı açılır)
// ═════════════════════════════════════════════════════════════════════════════

/// Afişin üstüne yazılmış başlıklı kartlar — dergi kapağı gibi.
class _PosterShelf extends StatelessWidget {
  final List<Show> shows;
  final double gutter;
  final bool wide;
  final ValueChanged<Show> onOpen;
  final VoidCallback onAll;

  const _PosterShelf({
    required this.shows,
    required this.gutter,
    required this.wide,
    required this.onOpen,
    required this.onAll,
  });

  @override
  Widget build(final BuildContext context) {
    final double w = wide ? 220 : 164;
    return SkRail<Show>(
      title: 'Vitrinde',
      subtitle: 'Sahnedeki ve yakında gelen oyunlar',
      items: shows,
      gutter: gutter,
      railW: w,
      railH: w * 1.5,
      minCell: w,
      builder: (final s, final cw) => _PosterCard(show: s, width: cw, onTap: () => onOpen(s)),
    );
  }
}

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
