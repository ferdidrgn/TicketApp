import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/admin_test_entry.dart';
import '../../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../../../shared/widgets/tiyatrol_hero.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../campaigns/domain/entities/campaign.dart';
import '../../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../../discovery/presentation/widgets/browse_controls.dart';
import '../../../../notifications/presentation/providers/notification_provider.dart';
import '../../../../players/domain/entities/player.dart';
import '../../../../players/presentation/providers/player_provider.dart';
import '../../../../shows/domain/entities/show.dart';
import '../../../../shows/presentation/widgets/detail/show_detail_actions.dart';
import '../../../../stages/domain/entities/stage.dart';
import '../../../../stages/presentation/providers/stage_provider.dart';
import '../../../../teams/domain/entities/team.dart';
import '../../../../teams/presentation/providers/team_provider.dart';
import '../../../../users/presentation/providers/user_provider.dart';
import '../../providers/home_sessions_provider.dart';
import '../../providers/home_show_filter_provider.dart';

/// ANA SAYFA — "Sahne". Telefon, tablet ve web için TEK duyarlı yüzey.
///
/// 1. Vitrin: sıradaki seansları olan oyunlar; afişten türeyen ortam zemini,
///    kayan afişler (parallax), otomatik ilerleme (dokununca durur).
/// 2. Program: gün şeridi + tür çipleri → seçime göre canlı süzülen seanslar.
/// 3. Vitrinde / Sahnenin yüzleri / Mekânlar / Topluluklar şeritleri.
///
/// Hepsi `homeUpcomingSessionsProvider` ve ana sayfa filtresinden gelen
/// GERÇEK veriyle beslenir; sahte sayı yok.
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

class _HomeExperienceState extends ConsumerState<HomeExperience> {
  DateTime? _day; // null → tüm yaklaşan seanslar
  String? _genre;
  bool _buying = false;

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

  Future<void> _buy(final HomeFeatured featured) async {
    if (_buying) return;
    HapticFeedback.mediumImpact();
    final Show show = featured.show;
    if (show.hasExternalTicketing) {
      setState(() => _buying = true);
      await openExternalTickets(context, show.externalTicketUrl);
      if (mounted) setState(() => _buying = false);
      return;
    }
    final HomeSession? session = featured.session;
    if (session != null) {
      final String userId = ref.read(currentUserIdProvider) ?? 'guest';
      NavigationHandler.goToSeatSelection(
          context, show.id, session.event.id, userId);
      return;
    }
    _openShow(show);
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

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final showState = ref.watch(homeShowsActiveFirstProvider(true));
    final activeShowState = ref.watch(homeActiveShowsProvider(true));
    final sessionsState = ref.watch(homeUpcomingSessionsProvider);
    final stageState = ref.watch(stagesProvider(isLimit: true));
    final campaignState = ref.watch(campaignsProvider);
    final playerState = ref.watch(playersProvider());
    final teamState = ref.watch(teamsProvider(isLimit: true));

    final List<Show> shows = showState.value ?? const [];
    final List<Show> activeShows = activeShowState.value ?? const [];
    final List<HomeSession> sessions = sessionsState.value ?? const [];
    final List<Stage> stages = stageState.value ?? const [];
    final List<Campaign> campaigns = campaignState.value ?? const [];
    final List<Team> teams = teamState.value ?? const [];
    final List<Player> players = (playerState.value ?? const <Player>[])
        .where((final p) => p.firstName.trim().isNotEmpty)
        .take(14)
        .toList();

    final bool loading = (showState.isLoading && shows.isEmpty) ||
        (sessionsState.isLoading && sessions.isEmpty && shows.isEmpty);
    final bool failed = showState.hasError && shows.isEmpty;

    final String firstName =
        (ref.watch(userProfileProvider).value?.firstName ?? '').trim();

    final List<BrowseCategory> genres = browseCategoriesOf(shows);

    // Vitrin: her oyunun EN YAKIN seansı; seans yoksa oyunun kendisi.
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

    // Program: gün + tür süzgeci.
    final List<HomeSession> programme = sessions.where((final s) {
      if (_day != null && s.day != _day) return false;
      if (_genre != null && browseCategoryKey(s.show.category) != _genre) {
        return false;
      }
      return true;
    }).toList();

    final Set<String> slideIds = slides.map((final f) => f.show.id).toSet();
    final List<Show> shelf = [
      for (final Show s in [...activeShows, ...shows])
        if (!slideIds.contains(s.id)) s,
    ];
    final Set<String> shelfSeen = {};
    final List<Show> shelfUnique =
        shelf.where((final s) => shelfSeen.add(s.id)).take(12).toList();

    Campaign? campaign;
    for (final Campaign c in campaigns) {
      if (c.imageUrl.trim().isNotEmpty) {
        campaign = c;
        break;
      }
    }

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
                child: pad(_Header(
                  name: firstName,
                  eveningCount: sessions
                      .where((final s) => s.day == skDay(DateTime.now()))
                      .length,
                  showActions: widget.showActions,
                  unread: _unread(),
                  onTickets: _openTickets,
                  onNotifications: _openNotifications,
                )),
              ),
            ),
            SliverToBoxAdapter(
              child: pad(_SearchPill(
                onTap: () => NavigationHandler.goToSearch(context),
                hints: [
                  for (final Show s in shows.take(3)) s.name,
                ],
              )),
            ),
            if (failed)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 360,
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
              if (slides.isNotEmpty)
                SliverToBoxAdapter(
                  child: _Stage(
                    slides: slides,
                    wide: wide,
                    gutter: gutter,
                    buying: _buying,
                    onOpen: (final f) => _openShow(f.show, from: 'home-stage'),
                    onBuy: _buy,
                  ),
                ),
              if (sessions.isNotEmpty)
                SliverToBoxAdapter(
                  child: pad(Padding(
                    padding: const EdgeInsets.only(top: 36),
                    child: _ProgrammeSection(
                      sessions: sessions,
                      programme: programme,
                      selectedDay: _day,
                      selectedGenre: _genre,
                      genres: genres,
                      wide: wide,
                      onDay: (final d) {
                        HapticFeedback.selectionClick();
                        setState(() => _day = d);
                      },
                      onGenre: (final g) {
                        HapticFeedback.selectionClick();
                        setState(() => _genre = g);
                      },
                      onOpen: (final s) =>
                          _openShow(s.show, from: 'home-programme'),
                      onClear: () => setState(() {
                        _day = null;
                        _genre = null;
                      }),
                    ),
                  )),
                ),
              if (shelfUnique.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 44),
                    child: rail(_PosterShelf(
                      shows: shelfUnique,
                      gutter: gutter,
                      wide: wide,
                      onOpen: (final s) => _openShow(s, from: 'home-shelf'),
                      onAll: () => NavigationHandler.goToDiscover(context),
                    )),
                  ),
                ),
              if (campaign != null)
                SliverToBoxAdapter(
                  child: pad(Padding(
                    padding: const EdgeInsets.only(top: 44),
                    child: _CampaignCard(
                      campaign: campaign,
                      wide: wide,
                      onOpen: () => NavigationHandler.goToCampaigns(context,
                          index: campaigns.indexOf(campaign!)),
                    ),
                  )),
                ),
              if (players.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 44),
                    child: rail(_Faces(players: players, gutter: gutter)),
                  ),
                ),
              if (stages.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 44),
                    child: rail(_Venues(
                        stages: stages, gutter: gutter, wide: wide)),
                  ),
                ),
              if (teams.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 44),
                    child: rail(_Troupes(teams: teams, gutter: gutter)),
                  ),
                ),
            ],
            SliverToBoxAdapter(
              child: widget.footer ?? const SizedBox(height: 120),
            ),
          ],
        ),
      );

      return ColoredBox(
        color: cs.surface,
        child: widget.onRefresh == null
            ? scroll
            : RefreshIndicator(onRefresh: widget.onRefresh!, child: scroll),
      );
    });
  }

  int _unread() {
    final bool loggedIn = ref.watch(isLoggedInProvider);
    final String uid = ref.watch(currentUserIdProvider) ?? '';
    return loggedIn ? ref.watch(unreadNotificationCountProvider(uid)) : 0;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BAŞLIK + ARAMA
// ═════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  final String name;
  final int eveningCount;
  final bool showActions;
  final int unread;
  final VoidCallback onTickets;
  final VoidCallback onNotifications;

  const _Header({
    required this.name,
    required this.eveningCount,
    required this.showActions,
    required this.unread,
    required this.onTickets,
    required this.onNotifications,
  });

  String get _greeting {
    final int h = DateTime.now().hour;
    final String part = h < 6
        ? 'İyi geceler'
        : (h < 12 ? 'Günaydın' : (h < 18 ? 'İyi günler' : 'İyi akşamlar'));
    return name.isEmpty ? part : '$part, $name';
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting,
                    style: Sk.ui(context,
                        size: 13.5,
                        color: cs.onSurfaceVariant,
                        weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  eveningCount > 0
                      ? 'Bu akşam $eveningCount\nperde açılıyor'
                      : 'Perde kaçta\nbu hafta?',
                  style: Sk.display(context, size: 32, height: 1.06),
                ),
              ],
            ),
          ),
          if (showActions) ...[
            _RoundIcon(
              icon: Icons.confirmation_number_outlined,
              label: 'Biletlerim',
              onTap: onTickets,
            ),
            const SizedBox(width: 8),
            _RoundIcon(
              icon: Icons.notifications_none_rounded,
              label: 'Bildirimler',
              onTap: onNotifications,
              badge: unread,
            ),
          ],
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  const _RoundIcon({
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
                  color: cs.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
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

/// Dokununca aramaya giden alan; ipucu gerçek oyun adlarıyla döner.
class _SearchPill extends StatefulWidget {
  final VoidCallback onTap;
  final List<String> hints;

  const _SearchPill({required this.onTap, required this.hints});

  @override
  State<_SearchPill> createState() => _SearchPillState();
}

class _SearchPillState extends State<_SearchPill> {
  Timer? _timer;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || widget.hints.isEmpty) return;
      if (Sk.reduceMotion(context)) return;
      setState(() => _i = (_i + 1) % widget.hints.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String hint = widget.hints.isEmpty
        ? 'Oyun, oyuncu veya sahne ara'
        : widget.hints[_i % widget.hints.length];
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 22),
      child: PressScale(
        onTap: widget.onTap,
        semanticLabel: 'Ara',
        scale: 0.985,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (final c, final a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween<Offset>(
                              begin: const Offset(0, 0.4), end: Offset.zero)
                          .animate(a),
                      child: c,
                    ),
                  ),
                  child: Align(
                    key: ValueKey<String>(hint),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.ui(context,
                          size: 15,
                          color: cs.onSurfaceVariant,
                          weight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
              Icon(Icons.tune_rounded, color: cs.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// VİTRİN
// ═════════════════════════════════════════════════════════════════════════════

class _Stage extends StatefulWidget {
  final List<HomeFeatured> slides;
  final bool wide;
  final double gutter;
  final bool buying;
  final ValueChanged<HomeFeatured> onOpen;
  final ValueChanged<HomeFeatured> onBuy;

  const _Stage({
    required this.slides,
    required this.wide,
    required this.gutter,
    required this.buying,
    required this.onOpen,
    required this.onBuy,
  });

  @override
  State<_Stage> createState() => _StageState();
}

class _StageState extends State<_Stage> {
  late PageController _page;
  Timer? _auto;
  int _index = 0;
  bool _paused = false;
  bool _wide = false;

  @override
  void initState() {
    super.initState();
    _wide = widget.wide;
    _page = PageController(viewportFraction: _fraction(widget.wide));
    _auto = Timer.periodic(const Duration(seconds: 6), (_) => _next());
  }

  double _fraction(final bool wide) => wide ? 0.36 : 0.74;

  @override
  void didUpdateWidget(covariant final _Stage old) {
    super.didUpdateWidget(old);
    if (old.wide != widget.wide) {
      final int keep = _index;
      _page.dispose();
      _page = PageController(
          viewportFraction: _fraction(widget.wide), initialPage: keep);
      _wide = widget.wide;
    }
    if (_index >= widget.slides.length) _index = 0;
  }

  void _next() {
    if (!mounted || _paused || widget.slides.length < 2) return;
    if (Sk.reduceMotion(context)) return;
    if (!_page.hasClients) return;
    final int target = (_index + 1) % widget.slides.length;
    _page.animateToPage(target,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _auto?.cancel();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final HomeFeatured current =
        widget.slides[_index.clamp(0, widget.slides.length - 1)];
    final double cardH = _wide ? 460 : 400;

    final Widget pages = Listener(
      onPointerDown: (_) => _paused = true,
      onPointerUp: (_) =>
          Future<void>.delayed(const Duration(seconds: 4), () => _paused = false),
      child: SizedBox(
        height: cardH,
        child: PageView.builder(
          controller: _page,
          clipBehavior: Clip.none,
          itemCount: widget.slides.length,
          onPageChanged: (final i) {
            HapticFeedback.selectionClick();
            setState(() => _index = i);
          },
          itemBuilder: (final context, final i) => AnimatedBuilder(
            animation: _page,
            builder: (final context, _) {
              double delta = 0;
              if (_page.hasClients && _page.position.haveDimensions) {
                delta = (_page.page ?? _index.toDouble()) - i;
              } else {
                delta = (_index - i).toDouble();
              }
              final double t = delta.abs().clamp(0.0, 1.0);
              return Transform.scale(
                scale: 1 - 0.1 * t,
                child: Opacity(
                  opacity: 1 - 0.35 * t,
                  child: _SlidePoster(
                    featured: widget.slides[i],
                    parallax: delta,
                    onTap: () {
                      if (i == _index) {
                        widget.onOpen(widget.slides[i]);
                      } else {
                        _page.animateToPage(i,
                            duration: const Duration(milliseconds: 450),
                            curve: Curves.easeOutCubic);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    final Widget info = _SlideInfo(
      key: ValueKey<String>(current.show.id),
      featured: current,
      buying: widget.buying,
      onOpen: () => widget.onOpen(current),
      onBuy: () => widget.onBuy(current),
      centered: !_wide,
    );

    final Widget dots = Row(
      mainAxisAlignment:
          _wide ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        for (int i = 0; i < widget.slides.length; i++)
          GestureDetector(
            onTap: () => _page.animateToPage(i,
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                width: i == _index ? 26 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _index
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
      ],
    );

    return Stack(
      children: [
        Positioned.fill(
          child: Align(
            alignment: Alignment.topCenter,
            child: AmbientBackdrop(url: current.show.imageUrl, height: 620),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Sk.maxWidth),
              child: _wide
                  ? Padding(
                      padding: EdgeInsets.symmetric(horizontal: widget.gutter),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 380),
                                  child: info,
                                ),
                                const SizedBox(height: 18),
                                dots,
                              ],
                            ),
                          ),
                          Expanded(flex: 7, child: pages),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        pages,
                        const SizedBox(height: 14),
                        dots,
                        Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: widget.gutter),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 380),
                            child: info,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SlidePoster extends StatelessWidget {
  final HomeFeatured featured;
  final double parallax;
  final VoidCallback onTap;

  const _SlidePoster({
    required this.featured,
    required this.parallax,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Show show = featured.show;
    final HomeSession? session = featured.session;
    final String? label = session == null
        ? (show.hasExternalTicketing ? 'Başka platformda' : null)
        : '${skDayPhrase(session.date)} · ${skClock(session.date)}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: PressScale(
        onTap: onTap,
        scale: 0.985,
        semanticLabel: show.name,
        child: TiyatrolHero(
          tag: TiyatrolHeroTags.show(show.id, 'home-stage'),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  OverflowBox(
                    maxWidth: double.infinity,
                    child: Transform.translate(
                      offset: Offset(-parallax * 36, 0),
                      child: FractionallySizedBox(
                        widthFactor: 1.18,
                        heightFactor: 1,
                        child: SkImage(url: show.imageUrl),
                      ),
                    ),
                  ),
                  if (label != null)
                    Positioned(
                      left: 12,
                      top: 12,
                      child: SkBadge(
                          label: label,
                          onImage: true,
                          icon: session == null
                              ? Icons.open_in_new_rounded
                              : Icons.schedule_rounded),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: cs.onSurface.withValues(alpha: 0.06)),
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideInfo extends StatelessWidget {
  final HomeFeatured featured;
  final bool buying;
  final VoidCallback onOpen;
  final VoidCallback onBuy;
  final bool centered;

  const _SlideInfo({
    super.key,
    required this.featured,
    required this.buying,
    required this.onOpen,
    required this.onBuy,
    required this.centered,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Show show = featured.show;
    final HomeSession? s = featured.session;
    final String venue = (s?.stage?.name ?? '').trim();
    final String meta = [
      if (show.category.trim().isNotEmpty) show.category.trim(),
      if (venue.isNotEmpty) venue,
      if (s?.priceLabel != null) '${s!.priceLabel}\'den',
    ].join('  ·  ');
    final bool external = show.hasExternalTicketing;
    final String cta = external
        ? 'Biletini bul'
        : (s == null ? 'Oyunu gör' : 'Bilet al');

    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          show.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: centered ? TextAlign.center : TextAlign.start,
          style: Sk.display(context, size: centered ? 28 : 40, height: 1.06),
        ),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            meta,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: Sk.ui(context,
                size: 13.5,
                color: cs.onSurfaceVariant,
                weight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: buying ? null : onBuy,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 50),
                padding: const EdgeInsets.symmetric(horizontal: 26),
                shape: const StadiumBorder(),
              ),
              icon: buying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(external
                      ? Icons.open_in_new_rounded
                      : Icons.confirmation_number_rounded),
              label: Text(cta,
                  style: Sk.ui(context,
                      size: 15, weight: FontWeight.w800, color: cs.onPrimary)),
            ),
            const SizedBox(width: 10),
            ShowFavoriteButton(showId: show.id),
          ],
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PROGRAM
// ═════════════════════════════════════════════════════════════════════════════

class _ProgrammeSection extends StatelessWidget {
  final List<HomeSession> sessions;
  final List<HomeSession> programme;
  final DateTime? selectedDay;
  final String? selectedGenre;
  final List<BrowseCategory> genres;
  final bool wide;
  final ValueChanged<DateTime?> onDay;
  final ValueChanged<String?> onGenre;
  final ValueChanged<HomeSession> onOpen;
  final VoidCallback onClear;

  const _ProgrammeSection({
    required this.sessions,
    required this.programme,
    required this.selectedDay,
    required this.selectedGenre,
    required this.genres,
    required this.wide,
    required this.onDay,
    required this.onGenre,
    required this.onOpen,
    required this.onClear,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final DateTime today = skDay(DateTime.now());

    // Önümüzdeki 14 gün + her gün için seans sayısı.
    final Map<DateTime, int> counts = {};
    for (final HomeSession s in sessions) {
      counts[s.day] = (counts[s.day] ?? 0) + 1;
    }
    final List<DateTime> days = [
      for (int i = 0; i < 14; i++) today.add(Duration(days: i)),
    ];

    final bool filtered = selectedDay != null || selectedGenre != null;
    final List<HomeSession> list =
        filtered ? programme : programme.take(10).toList();

    // Gün başlıklarına göre grupla.
    final Map<DateTime, List<HomeSession>> groups = {};
    for (final HomeSession s in list) {
      groups.putIfAbsent(s.day, () => []).add(s);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkSectionHead(title: 'Program'),
        const SizedBox(height: 14),
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: days.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (final context, final i) {
              if (i == 0) {
                final bool sel = selectedDay == null;
                return _DayTile(
                  top: 'Hepsi',
                  big: '${sessions.length}',
                  selected: sel,
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
        ),
        if (genres.length > 1) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: genres.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (final context, final i) {
                if (i == 0) {
                  return SkChip(
                    label: 'Tüm türler',
                    selected: selectedGenre == null,
                    onTap: () => onGenre(null),
                  );
                }
                final BrowseCategory g = genres[i - 1];
                return SkChip(
                  label: g.label,
                  count: g.count,
                  selected: selectedGenre == g.key,
                  onTap: () => onGenre(selectedGenre == g.key ? null : g.key),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: list.isEmpty
              ? Container(
                  key: const ValueKey<String>('empty'),
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy_rounded,
                          color: cs.onSurfaceVariant, size: 30),
                      const SizedBox(height: 10),
                      Text('Bu seçimde seans yok',
                          style: Sk.ui(context,
                              size: 15, weight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Başka bir gün ya da tür seçebilirsin.',
                          style: Sk.ui(context,
                              size: 13,
                              color: cs.onSurfaceVariant,
                              weight: FontWeight.w500)),
                      const SizedBox(height: 12),
                      TextButton(
                          onPressed: onClear, child: const Text('Süzgeçleri temizle')),
                    ],
                  ),
                )
              : Column(
                  key: ValueKey<String>('$selectedDay|$selectedGenre'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final MapEntry<DateTime, List<HomeSession>> g
                        in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 10),
                        child: Text(
                          '${skDayPhrase(g.key)} · ${g.key.day} ${kMonthsTr[g.key.month - 1]}',
                          style: Sk.ui(context,
                              size: 12.5,
                              color: cs.primary,
                              weight: FontWeight.w800,
                              letterSpacing: 0.3),
                        ),
                      ),
                      _SessionGrid(
                        sessions: g.value,
                        wide: wide,
                        onOpen: onOpen,
                      ),
                    ],
                  ],
                ),
        ),
      ],
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
        duration: const Duration(milliseconds: 200),
        width: 62,
        decoration: BoxDecoration(
          color: selected ? cs.primary : cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
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
                    size: 22, color: fg, height: 1.0, weight: FontWeight.w700)),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
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

class _SessionGrid extends StatelessWidget {
  final List<HomeSession> sessions;
  final bool wide;
  final ValueChanged<HomeSession> onOpen;

  const _SessionGrid(
      {required this.sessions, required this.wide, required this.onOpen});

  @override
  Widget build(final BuildContext context) {
    if (!wide) {
      return Column(
        children: [
          for (int i = 0; i < sessions.length; i++)
            Reveal(
              index: i,
              child: _SessionRow(
                  session: sessions[i], onTap: () => onOpen(sessions[i])),
            ),
        ],
      );
    }
    return LayoutBuilder(builder: (final context, final box) {
      final int cols = box.maxWidth >= 1000 ? 3 : 2;
      final double w = (box.maxWidth - (cols - 1) * 16) / cols;
      return Wrap(
        spacing: 16,
        children: [
          for (int i = 0; i < sessions.length; i++)
            SizedBox(
              width: w,
              child: Reveal(
                index: i,
                child: _SessionRow(
                    session: sessions[i], onTap: () => onOpen(sessions[i])),
              ),
            ),
        ],
      );
    });
  }
}

class _SessionRow extends StatelessWidget {
  final HomeSession session;
  final VoidCallback onTap;

  const _SessionRow({required this.session, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Show show = session.show;
    final String venue = (session.stage?.name ?? '').trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressScale(
        onTap: onTap,
        semanticLabel: '${show.name}, ${skClock(session.date)}',
        scale: 0.985,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              SkImage(
                  url: show.imageUrl, width: 64, height: 88, radius: 14),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(skClock(session.date),
                        style: Sk.display(context,
                            size: 22, color: cs.primary, height: 1.0)),
                    const SizedBox(height: 4),
                    Text(show.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Sk.ui(context,
                            size: 15, weight: FontWeight.w800, height: 1.2)),
                    if (venue.isNotEmpty || session.priceLabel != null) ...[
                      const SizedBox(height: 4),
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
                            weight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
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
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double cardW = wide ? 200 : 144;
    final double posterH = cardW * 1.45;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: SkSectionHead(
            title: 'Vitrinde',
            subtitle: 'Sahnedeki ve yakında gelen oyunlar',
            actionLabel: 'Tümünü gör',
            onAction: onAll,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: posterH + 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: gutter),
            itemCount: shows.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (final context, final i) {
              final Show s = shows[i];
              return Reveal(
                index: i,
                dy: 0,
                child: SizedBox(
                  width: cardW,
                  child: PressScale(
                    onTap: () => onOpen(s),
                    semanticLabel: s.name,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TiyatrolHero(
                          tag: TiyatrolHeroTags.show(s.id, 'home-shelf'),
                          child: Stack(
                            children: [
                              SkImage(
                                  url: s.imageUrl,
                                  width: cardW,
                                  height: posterH,
                                  radius: 18),
                              if (s.hasExternalTicketing)
                                const Positioned(
                                  left: 8,
                                  top: 8,
                                  child: SkBadge(
                                      label: 'Başka platform',
                                      onImage: true,
                                      icon: Icons.open_in_new_rounded),
                                )
                              else if (s.isRecentlyAdded)
                                const Positioned(
                                  left: 8,
                                  top: 8,
                                  child: SkBadge(label: 'Yeni', accent: true),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(s.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Sk.ui(context,
                                size: 14, weight: FontWeight.w800, height: 1.2)),
                        if (s.category.trim().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(s.category.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Sk.ui(context,
                                    size: 12,
                                    color: cs.onSurfaceVariant,
                                    weight: FontWeight.w500)),
                          ),
                      ],
                    ),
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

class _Faces extends StatelessWidget {
  final List<Player> players;
  final double gutter;

  const _Faces({required this.players, required this.gutter});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: const SkSectionHead(
              title: 'Sahnenin yüzleri',
              subtitle: 'Perdenin önündeki oyuncular'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 236,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: gutter),
            itemCount: players.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (final context, final i) {
              final Player p = players[i];
              final String name = '${p.firstName} ${p.lastName}'.trim();
              return SizedBox(
                width: 120,
                child: PressScale(
                  onTap: () => NavigationHandler.goToPlayer(
                    context,
                    p.id,
                    name,
                    heroTag: TiyatrolHeroTags.player(p.id, 'home'),
                    imageUrl: p.imageUrl,
                    title: name,
                  ),
                  semanticLabel: name,
                  child: Column(
                    children: [
                      TiyatrolHero(
                        tag: TiyatrolHeroTags.player(p.id, 'home'),
                        child: SkImage(
                          url: p.imageUrl,
                          width: 120,
                          height: 168,
                          radius: 60,
                          fallbackIcon: Icons.person_rounded,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${p.firstName}\n${p.lastName}'.trim(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Sk.ui(context,
                            size: 13,
                            color: cs.onSurface,
                            weight: FontWeight.w700,
                            height: 1.2),
                      ),
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

class _Venues extends StatelessWidget {
  final List<Stage> stages;
  final double gutter;
  final bool wide;

  const _Venues(
      {required this.stages, required this.gutter, required this.wide});

  @override
  Widget build(final BuildContext context) {
    final double w = wide ? 320 : 260;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: SkSectionHead(
            title: 'Mekânlar',
            subtitle: 'Perdenin açıldığı sahneler',
            actionLabel: 'Yakınımda',
            onAction: () => NavigationHandler.goToNearby(context),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: gutter),
            itemCount: stages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (final context, final i) {
              final Stage s = stages[i];
              return SizedBox(
                width: w,
                child: PressScale(
                  onTap: () => NavigationHandler.goToStage(context, s.id, s.name,
                      heroTag: TiyatrolHeroTags.stage(s.id, 'home'),
                      imageUrl: s.imageUrl,
                      title: s.name),
                  semanticLabel: s.name,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
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
                                Colors.black.withValues(alpha: 0.78),
                              ],
                              stops: const [0.35, 1],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(s.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Sk.display(context,
                                      size: 20,
                                      color: Colors.white,
                                      height: 1.1)),
                              if (s.address.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(s.address.trim(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Sk.ui(context,
                                          size: 12,
                                          color: Colors.white70,
                                          weight: FontWeight.w500)),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

class _Troupes extends StatelessWidget {
  final List<Team> teams;
  final double gutter;

  const _Troupes({required this.teams, required this.gutter});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: const SkSectionHead(title: 'Topluluklar'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: gutter),
            itemCount: teams.length,
            separatorBuilder: (_, __) => const SizedBox(width: 18),
            itemBuilder: (final context, final i) {
              final Team t = teams[i];
              return SizedBox(
                width: 84,
                child: PressScale(
                  onTap: () => NavigationHandler.goToTeam(context, t.id, t.name,
                      imageUrl: t.imageUrl, title: t.name),
                  semanticLabel: t.name,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: cs.primary.withValues(alpha: 0.5),
                              width: 2),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: ClipOval(
                          child: SkImage(
                              url: t.imageUrl,
                              width: 64,
                              height: 64,
                              fallbackIcon: Icons.groups_rounded),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(t.name,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.ui(context,
                              size: 12,
                              weight: FontWeight.w700,
                              height: 1.2)),
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

class _CampaignCard extends StatelessWidget {
  final Campaign campaign;
  final bool wide;
  final VoidCallback onOpen;

  const _CampaignCard(
      {required this.campaign, required this.wide, required this.onOpen});

  @override
  Widget build(final BuildContext context) {
    return PressScale(
      onTap: onOpen,
      semanticLabel: 'Kampanya',
      scale: 0.99,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: AspectRatio(
          aspectRatio: wide ? 3.2 : 1.7,
          child: SkImage(url: campaign.imageUrl),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// YÜKLENİYOR
// ═════════════════════════════════════════════════════════════════════════════

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(final BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: SkBone(width: 280, height: 380, radius: 26)),
          SizedBox(height: 18),
          Center(child: SkBone(width: 220, height: 28, radius: 10)),
          SizedBox(height: 28),
          SkBone(height: 78, radius: 20),
          SizedBox(height: 18),
          SkBone(height: 108, radius: 22),
          SizedBox(height: 12),
          SkBone(height: 108, radius: 22),
        ],
      );
}
