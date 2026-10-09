import 'dart:async';
import 'dart:ui' as ui;

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
import '../../providers/home_sessions_provider.dart';
import '../../providers/home_show_filter_provider.dart';

/// ANA SAYFA — "Sahne". Telefon, tablet ve web için tek duyarlı yüzey.
///
/// Kenardan kenara afiş kahramanı (başlık afişin üstünde), altında yumuşak
/// Material tonlu yüzeyler: tür halkaları, gün şeridiyle canlı program,
/// afiş vitrini, oyuncular, mekânlar, topluluklar. Hepsi gerçek veri.
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
    final Set<String> shelfSeen = {};
    final List<Show> shelf = [
      for (final Show s in [...activeShows, ...shows])
        if (!slideIds.contains(s.id) && shelfSeen.add(s.id)) s,
    ].take(12).toList();

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

      final Widget topBar = _TopBar(
        showActions: widget.showActions,
        unread: _unread(),
        onTickets: _openTickets,
        onNotifications: _openNotifications,
      );

      final Widget scroll = ScrollConfiguration(
        behavior: const SkScrollBehavior(),
        child: CustomScrollView(
          controller: widget.controller,
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            const SliverToBoxAdapter(child: AdminTestStrip()),
            if (failed)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 520,
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
            else if (loading || slides.isEmpty)
              SliverToBoxAdapter(
                child: _HeroSkeleton(wide: wide, topBar: topBar),
              )
            else ...[
              SliverToBoxAdapter(
                child: _Hero(
                  slides: slides,
                  wide: wide,
                  buying: _buying,
                  gutter: gutter,
                  topBar: topBar,
                  onOpen: (final f) => _openShow(f.show, from: 'home-stage'),
                  onBuy: _buy,
                ),
              ),
              SliverToBoxAdapter(
                child: pad(Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _SearchPill(
                    onTap: () => NavigationHandler.goToSearch(context),
                    hints: [for (final Show s in shows.take(4)) s.name],
                  ),
                )),
              ),
              if (genres.length > 1)
                SliverToBoxAdapter(
                  child: rail(_Genres(
                    genres: genres,
                    selected: _genre,
                    gutter: gutter,
                    onPick: (final g) {
                      HapticFeedback.selectionClick();
                      setState(() => _genre = _genre == g ? null : g);
                    },
                  )),
                ),
              if (sessions.isNotEmpty)
                SliverToBoxAdapter(
                  child: pad(Padding(
                    padding: const EdgeInsets.only(top: 36),
                    child: _ProgrammeSection(
                      sessions: sessions,
                      programme: programme,
                      selectedDay: _day,
                      hasGenre: _genre != null,
                      wide: wide,
                      onDay: (final d) {
                        HapticFeedback.selectionClick();
                        setState(() => _day = d);
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
              if (shelf.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 44),
                    child: rail(_PosterShelf(
                      shows: shelf,
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
                    child: rail(
                        _Venues(stages: stages, gutter: gutter, wide: wide)),
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
              child: widget.footer ?? const SizedBox(height: 130),
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
// KAHRAMAN (HERO)
// ═════════════════════════════════════════════════════════════════════════════

/// Fotoğraf üstü üst çubuk: marka + bilet/bildirim (cam butonlar).
class _TopBar extends StatelessWidget {
  final bool showActions;
  final int unread;
  final VoidCallback onTickets;
  final VoidCallback onNotifications;

  const _TopBar({
    required this.showActions,
    required this.unread,
    required this.onTickets,
    required this.onNotifications,
  });

  @override
  Widget build(final BuildContext context) {
    if (!showActions) return const SizedBox.shrink();
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 14, 0),
        child: Row(
          children: [
            Expanded(
              child: Text('TiyatRol',
                  style: Sk.display(context,
                      size: 24, color: Colors.white, height: 1.0)),
            ),
            _GlassIcon(
                icon: Icons.confirmation_number_outlined,
                label: 'Biletlerim',
                onTap: onTickets),
            const SizedBox(width: 8),
            _GlassIcon(
                icon: Icons.notifications_none_rounded,
                label: 'Bildirimler',
                onTap: onNotifications,
                badge: unread),
          ],
        ),
      ),
    );
  }
}

class _GlassIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int badge;

  const _GlassIcon({
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
              SkGlass(
                radius: 22,
                padding: const EdgeInsets.all(10),
                child: Icon(icon, size: 22, color: Colors.white),
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

class _HeroSkeleton extends StatelessWidget {
  final bool wide;
  final Widget topBar;
  const _HeroSkeleton({required this.wide, required this.topBar});

  @override
  Widget build(final BuildContext context) {
    final double h = wide
        ? 560
        : (MediaQuery.sizeOf(context).height * 0.66).clamp(480.0, 620.0);
    return SizedBox(
      height: h,
      child: Stack(
        children: [
          Positioned.fill(child: SkBone(height: h, radius: 0)),
          Positioned(top: 0, left: 0, right: 0, child: topBar),
        ],
      ),
    );
  }
}

class _Hero extends StatefulWidget {
  final List<HomeFeatured> slides;
  final bool wide;
  final bool buying;
  final double gutter;
  final Widget topBar;
  final ValueChanged<HomeFeatured> onOpen;
  final ValueChanged<HomeFeatured> onBuy;

  const _Hero({
    required this.slides,
    required this.wide,
    required this.buying,
    required this.gutter,
    required this.topBar,
    required this.onOpen,
    required this.onBuy,
  });

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  final PageController _page = PageController();
  Timer? _auto;
  int _index = 0;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _auto = Timer.periodic(const Duration(seconds: 7), (_) => _next());
  }

  void _go(final int i) {
    if (!mounted) return;
    if (widget.wide) {
      setState(() => _index = i);
    } else if (_page.hasClients) {
      _page.animateToPage(i,
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic);
    }
  }

  void _next() {
    if (!mounted || _paused || widget.slides.length < 2) return;
    if (Sk.reduceMotion(context)) return;
    _go((_index + 1) % widget.slides.length);
  }

  void _pause() {
    _paused = true;
    Future<void>.delayed(const Duration(seconds: 8), () => _paused = false);
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
    return widget.wide ? _wide(context, current) : _mobile(context, current);
  }

  // ─── telefon / tablet: kenardan kenara afiş ──────────────────────────────

  Widget _mobile(final BuildContext context, final HomeFeatured current) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double h =
        (MediaQuery.sizeOf(context).height * 0.7).clamp(500.0, 660.0);
    return SizedBox(
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Listener(
            onPointerDown: (_) => _pause(),
            child: PageView.builder(
              controller: _page,
              itemCount: widget.slides.length,
              onPageChanged: (final i) {
                HapticFeedback.selectionClick();
                setState(() => _index = i);
              },
              itemBuilder: (final context, final i) => AnimatedBuilder(
                animation: _page,
                builder: (final context, _) {
                  double delta = (_index - i).toDouble();
                  if (_page.hasClients && _page.position.haveDimensions) {
                    delta = (_page.page ?? _index.toDouble()) - i;
                  }
                  return GestureDetector(
                    onTap: () => widget.onOpen(widget.slides[i]),
                    child: TiyatrolHero(
                      tag: TiyatrolHeroTags.show(
                          widget.slides[i].show.id, 'home-stage'),
                      child: LayoutBuilder(
                        builder: (final context, final c) {
                          final double w = c.maxWidth;
                          return ClipRect(
                            child: Stack(
                              children: [
                                Positioned(
                                  left: -0.1 * w - delta * 50,
                                  width: 1.2 * w,
                                  top: 0,
                                  bottom: 0,
                                  child: SkImage(
                                      url: widget.slides[i].show.imageUrl),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Üstte ve altta okunurluk karartması + zemine karışan alt kenar.
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.9),
                    cs.surface,
                  ],
                  stops: const [0.0, 0.2, 0.42, 0.7, 0.9, 1.0],
                ),
              ),
            ),
          ),
          Positioned(top: 0, left: 0, right: 0, child: widget.topBar),
          Positioned(
            left: 22,
            right: 22,
            bottom: 62,
            child: IgnorePointer(
              ignoring: false,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 420),
                switchInCurve: Curves.easeOutCubic,
                layoutBuilder: (final current, final previous) => Stack(
                  alignment: Alignment.bottomLeft,
                  children: [...previous, if (current != null) current],
                ),
                transitionBuilder: (final c, final a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, 0.08), end: Offset.zero)
                        .animate(a),
                    child: c,
                  ),
                ),
                child: _HeroInfo(
                  key: ValueKey<String>(current.show.id),
                  featured: current,
                  wide: false,
                  buying: widget.buying,
                  onOpen: () => widget.onOpen(current),
                  onBuy: () => widget.onBuy(current),
                ),
              ),
            ),
          ),
          Positioned(
            left: 22,
            bottom: 38,
            child: _Dots(count: widget.slides.length, index: _index),
          ),
        ],
      ),
    );
  }

  // ─── web / geniş: bulanık sahne + büyük afiş ─────────────────────────────

  Widget _wide(final BuildContext context, final HomeFeatured current) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 600,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            child: KeyedSubtree(
              key: ValueKey<String>('bg-${current.show.id}'),
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 36, sigmaY: 36),
                child: SizedBox.expand(
                  child: SkImage(url: current.show.imageUrl),
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.82),
                  Colors.black.withValues(alpha: 0.35),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, cs.surface],
                stops: const [0.72, 1.0],
              ),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Sk.maxWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    widget.gutter, 36, widget.gutter, 56),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 420),
                            layoutBuilder: (final current, final previous) =>
                                Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                ...previous,
                                if (current != null) current,
                              ],
                            ),
                            child: _HeroInfo(
                              key: ValueKey<String>(current.show.id),
                              featured: current,
                              wide: true,
                              buying: widget.buying,
                              onOpen: () => widget.onOpen(current),
                              onBuy: () => widget.onBuy(current),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              for (int i = 0; i < widget.slides.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(right: 10),
                                  child: PressScale(
                                    onTap: () {
                                      _pause();
                                      _go(i);
                                    },
                                    semanticLabel: widget.slides[i].show.name,
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      padding: const EdgeInsets.all(2.5),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(14),
                                        border: Border.all(
                                          color: i == _index
                                              ? Colors.white
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Opacity(
                                        opacity: i == _index ? 1 : 0.6,
                                        child: SkImage(
                                            url: widget.slides[i].show.imageUrl,
                                            width: 46,
                                            height: 66,
                                            radius: 10),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      flex: 5,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: AspectRatio(
                          aspectRatio: 2 / 3,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: PressScale(
                              key: ValueKey<String>('poster-${current.show.id}'),
                              onTap: () => widget.onOpen(current),
                              semanticLabel: current.show.name,
                              scale: 0.985,
                              child: TiyatrolHero(
                                tag: TiyatrolHeroTags.show(
                                    current.show.id, 'home-stage'),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.5),
                                        blurRadius: 50,
                                        offset: const Offset(0, 26),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: SkImage(
                                        url: current.show.imageUrl),
                                  ),
                                ),
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
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;
  const _Dots({required this.count, required this.index});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            margin: const EdgeInsets.only(right: 5),
            width: i == index ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index ? cs.primary : Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

/// Afiş üstü bilgi: zaman rozeti, ad, mekân/fiyat, birincil aksiyon.
class _HeroInfo extends StatelessWidget {
  final HomeFeatured featured;
  final bool wide;
  final bool buying;
  final VoidCallback onOpen;
  final VoidCallback onBuy;

  const _HeroInfo({
    super.key,
    required this.featured,
    required this.wide,
    required this.buying,
    required this.onOpen,
    required this.onBuy,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Show show = featured.show;
    final HomeSession? s = featured.session;
    final String venue = (s?.stage?.name ?? '').trim();
    final bool external = show.hasExternalTicketing;
    final String when = s == null
        ? (external ? 'Başka platformda' : 'Programda')
        : '${skDayPhrase(s.date)} · ${skClock(s.date)}';
    final String meta = [
      if (venue.isNotEmpty) venue,
      if (s?.priceLabel != null) '${s!.priceLabel}\'den',
    ].join('  ·  ');
    final String cta =
        external ? 'Biletini bul' : (s == null ? 'Oyunu gör' : 'Bilet al');

    return SizedBox(
      width: double.infinity,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SkGlass(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(s == null ? Icons.open_in_new_rounded : Icons.schedule_rounded,
                    size: 14, color: Colors.white),
                const SizedBox(width: 6),
                Text(when,
                    style: Sk.ui(context,
                        size: 12.5,
                        color: Colors.white,
                        weight: FontWeight.w800)),
              ]),
            ),
            if (show.category.trim().isNotEmpty)
              SkGlass(
                child: Text(show.category.trim(),
                    style: Sk.ui(context,
                        size: 12.5,
                        color: Colors.white,
                        weight: FontWeight.w700)),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          show.name,
          maxLines: wide ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: Sk.display(context,
                  size: wide ? 58 : 38, color: Colors.white, height: 1.02)
              .copyWith(shadows: [
            Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 18,
                offset: const Offset(0, 4)),
          ]),
        ),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(meta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Sk.ui(context,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.82),
                  weight: FontWeight.w600)),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              onPressed: buying ? null : onBuy,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 54),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                shape: const StadiumBorder(),
                elevation: 0,
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
            ShowFavoriteButton(showId: show.id, onImage: true),
          ],
        ),
      ],
    ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ARAMA ÇUBUĞU
// ═════════════════════════════════════════════════════════════════════════════

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
    return PressScale(
      onTap: widget.onTap,
      semanticLabel: 'Ara',
      scale: 0.985,
      child: Container(
        height: 58,
        padding: const EdgeInsets.only(left: 20, right: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(30),
          boxShadow: skSoftShadow(context),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
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
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: cs.primary, shape: BoxShape.circle),
              child: Icon(Icons.arrow_forward_rounded,
                  color: cs.onPrimary, size: 20),
            ),
          ],
        ),
      ),
    );
  }
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
              subtitle: 'Seçtiğin tür aşağıdaki programı süzer'),
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
// PROGRAM
// ═════════════════════════════════════════════════════════════════════════════

class _ProgrammeSection extends StatelessWidget {
  final List<HomeSession> sessions;
  final List<HomeSession> programme;
  final DateTime? selectedDay;
  final bool hasGenre;
  final bool wide;
  final ValueChanged<DateTime?> onDay;
  final ValueChanged<HomeSession> onOpen;
  final VoidCallback onClear;

  const _ProgrammeSection({
    required this.sessions,
    required this.programme,
    required this.selectedDay,
    required this.hasGenre,
    required this.wide,
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

    final bool filtered = selectedDay != null || hasGenre;
    final List<HomeSession> list =
        filtered ? programme : programme.take(10).toList();

    final Map<DateTime, List<HomeSession>> groups = {};
    for (final HomeSession s in list) {
      groups.putIfAbsent(s.day, () => []).add(s);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkSectionHead(
          title: 'Program',
          subtitle: '${sessions.length} yaklaşan seans',
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
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
        ),
        const SizedBox(height: 20),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: list.isEmpty
              ? Container(
                  key: const ValueKey<String>('empty'),
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
                          onPressed: onClear,
                          child: const Text('Süzgeçleri temizle')),
                    ],
                  ),
                )
              : Column(
                  key: ValueKey<String>('$selectedDay|$hasGenre'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final MapEntry<DateTime, List<HomeSession>> g
                        in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 12),
                        child: Text(
                          '${skDayPhrase(g.key)} · ${g.key.day} ${kMonthsTr[g.key.month - 1]}',
                          style: Sk.display(context,
                              size: 18, color: cs.primary, height: 1.1),
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
      final double w = (box.maxWidth - (cols - 1) * 18) / cols;
      return Wrap(
        spacing: 18,
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
      padding: const EdgeInsets.only(bottom: 14),
      child: PressScale(
        onTap: onTap,
        semanticLabel: '${show.name}, ${skClock(session.date)}',
        scale: 0.985,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(28),
            boxShadow: skSoftShadow(context, strength: 0.6),
          ),
          child: Row(
            children: [
              SkImage(url: show.imageUrl, width: 74, height: 100, radius: 20),
              const SizedBox(width: 14),
              Expanded(
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
                      child: Text(skClock(session.date),
                          style: Sk.ui(context,
                              size: 13,
                              color: cs.onPrimaryContainer,
                              weight: FontWeight.w900)),
                    ),
                    const SizedBox(height: 8),
                    Text(show.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Sk.display(context,
                            size: 17, height: 1.15, weight: FontWeight.w700)),
                    if (venue.isNotEmpty || session.priceLabel != null) ...[
                      const SizedBox(height: 5),
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: cs.secondaryContainer, shape: BoxShape.circle),
                child: Icon(Icons.arrow_outward_rounded,
                    size: 20, color: cs.onSecondaryContainer),
              ),
              const SizedBox(width: 4),
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
    final double cardW = wide ? 230 : 172;
    final double cardH = cardW * 1.5;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: gutter),
          child: SkSectionHead(
            title: 'Vitrinde',
            subtitle: 'Sahnedeki ve yakında gelen oyunlar',
            actionLabel: 'Tümü',
            onAction: onAll,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: cardH + 20,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.symmetric(horizontal: gutter),
            itemCount: shows.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
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
                    child: Container(
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
                              tag: TiyatrolHeroTags.show(s.id, 'home-shelf'),
                              child: SkImage(url: s.imageUrl),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.82),
                                  ],
                                  stops: const [0.5, 1.0],
                                ),
                              ),
                            ),
                            if (s.hasExternalTicketing)
                              const Positioned(
                                left: 10,
                                top: 10,
                                child: SkBadge(
                                    label: 'Başka platform',
                                    onImage: true,
                                    icon: Icons.open_in_new_rounded),
                              )
                            else if (s.isRecentlyAdded)
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
                                  if (s.category.trim().isNotEmpty)
                                    Text(s.category.trim(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Sk.ui(context,
                                            size: 11.5,
                                            color: Colors.white70,
                                            weight: FontWeight.w700)),
                                  const SizedBox(height: 3),
                                  Text(s.name,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: Sk.display(context,
                                          size: 18,
                                          color: Colors.white,
                                          height: 1.1)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
        const SizedBox(height: 18),
        SizedBox(
          height: 244,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.symmetric(horizontal: gutter),
            itemCount: players.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
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
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(60),
                            boxShadow: skSoftShadow(context, strength: 0.8),
                          ),
                          child: SkImage(
                            url: p.imageUrl,
                            width: 120,
                            height: 168,
                            radius: 60,
                            fallbackIcon: Icons.person_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${p.firstName}\n${p.lastName}'.trim(),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Sk.ui(context,
                            size: 13,
                            color: cs.onSurface,
                            weight: FontWeight.w800,
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
    final double w = wide ? 340 : 276;
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
        const SizedBox(height: 18),
        SizedBox(
          height: 204,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: EdgeInsets.symmetric(horizontal: gutter),
            itemCount: stages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
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
                  child: Container(
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
                                        size: 21,
                                        color: Colors.white,
                                        height: 1.1)),
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
          child: const SkSectionHead(
              title: 'Topluluklar', subtitle: 'Perdeyi açan ekipler'),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 124,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: gutter),
            itemCount: teams.length,
            separatorBuilder: (_, __) => const SizedBox(width: 18),
            itemBuilder: (final context, final i) {
              final Team t = teams[i];
              return SizedBox(
                width: 88,
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
                          decoration: BoxDecoration(
                              color: cs.surface, shape: BoxShape.circle),
                          child: ClipOval(
                            child: SkImage(
                                url: t.imageUrl,
                                width: 64,
                                height: 64,
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
                              size: 12,
                              weight: FontWeight.w800,
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: skSoftShadow(context),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: AspectRatio(
            aspectRatio: wide ? 3.2 : 1.7,
            child: SkImage(url: campaign.imageUrl),
          ),
        ),
      ),
    );
  }
}
