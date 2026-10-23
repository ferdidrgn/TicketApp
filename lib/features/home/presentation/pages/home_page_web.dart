import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../core/util/comminucation_actions.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/footers/web_mega_footer.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../campaigns/domain/entities/campaign.dart';
import '../../../campaigns/presentation/providers/campaign_provider.dart';
import '../../../discovery/presentation/widgets/browse_controls.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/providers/player_provider.dart';
import '../../../reviews/data/review_repository.dart';
import '../../../reviews/presentation/providers/review_providers.dart';
import '../../../reviews/presentation/widgets/review_widgets.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/team_provider.dart';
import '../providers/home_sessions_provider.dart';
import '../providers/home_show_filter_provider.dart';
import '../widgets/web/web_home_extras.dart';

part 'home_web_sections.dart';

/// ANA SAYFA — WEB. Gerçek bir bilet sitesinin vitrini (mağaza düzeni):
///
/// vitrin kaydırıcı (kampanya + öne çıkan oyunlar) → yuvarlak tür karoları →
/// oklu raflar (Popüler oyunlar, Yeni eklenenler, tür vitrini, Uygun fiyatlı
/// seanslar) → yaklaşan seanslar tablosu → mekânlar + topluluklar +
/// oyuncular → yardım bağlantıları → özellik şeridi → footer.
///
/// Başlık (üst şerit + arama + tür menüsü) `WebSiteHeader`'dadır (kabuk).
/// Mobil uygulamanın "Sahne" ana sayfasından AYRIDIR. Her şey gerçek
/// veriden; fiyat/tarih uydurulmaz. Kendi `Scaffold`'unu kurar.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

const double _kMaxW = 1360;

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _agendaKey = GlobalKey();
  int _agendaShown = 8;
  String? _spotKey; // tür vitrininde seçili tür

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _openShow(final Show s) => NavigationHandler.goToShow(
      context, s.id, s.name, imageUrl: s.imageUrl, title: s.name);

  void _scrollToAgenda() {
    final BuildContext? c = _agendaKey.currentContext;
    if (c == null) return;
    Scrollable.ensureVisible(c,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        alignment: 0.02);
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final showsAsync = ref.watch(homeShowsActiveFirstProvider(true));
    final List<Show> shows = showsAsync.value ?? const [];
    final bool loading = showsAsync.isLoading && shows.isEmpty;
    final List<HomeSession> sessions =
        ref.watch(homeUpcomingSessionsProvider).value ?? const [];
    final List<Stage> stages =
        ref.watch(stagesProvider(isLimit: true)).value ?? const [];
    final List<Team> teams =
        ref.watch(teamsProvider(isLimit: true)).value ?? const [];
    final List<Player> players =
        ref.watch(playersProvider()).value ?? const [];
    final List<Campaign> campaigns =
        ref.watch(campaignsProvider).value ?? const [];

    final Map<String, HomeSession> nextByShow = {};
    for (final HomeSession s in sessions) {
      nextByShow.putIfAbsent(s.show.id, () => s);
    }
    final List<BrowseCategory> categories = browseCategoriesOf(shows);

    // Raflar
    final List<Show> popular = [
      ...nextByShow.keys
          .map((final id) => shows.where((final s) => s.id == id))
          .expand((final i) => i),
      ...shows.where((final s) => !nextByShow.containsKey(s.id)),
    ].take(14).toList();
    final List<Show> fresh =
        shows.where((final s) => s.isRecentlyAdded).take(14).toList();
    final List<HomeSession> cheap = ([
      for (final HomeSession s in sessions)
        if (s.priceLabel != null) s,
    ]..sort((final a, final b) => _priceOf(a).compareTo(_priceOf(b))))
        .take(14)
        .toList();
    // Top 10: yorum puanı + yorum sayısı + yaklaşan seans sırasıyla
    final Map<String, ReviewStat> stats =
        ref.watch(reviewStatsProvider).value ?? const {};
    final List<Show> ranked = ([...shows]
          ..sort((final a, final b) {
            final ReviewStat? x = stats[a.id];
            final ReviewStat? y = stats[b.id];
            final int c = (y?.average ?? 0).compareTo(x?.average ?? 0);
            if (c != 0) return c;
            final int d = (y?.count ?? 0).compareTo(x?.count ?? 0);
            if (d != 0) return d;
            final DateTime? na = nextByShow[a.id]?.date;
            final DateTime? nb = nextByShow[b.id]?.date;
            if (na == null && nb == null) return 0;
            if (na == null) return 1;
            if (nb == null) return -1;
            return na.compareTo(nb);
          }))
        .toList();
    final Show? weekShow = ranked
        .where((final s) => nextByShow.containsKey(s.id))
        .firstOrNull;
    // Son çağrı: tüm seansları önümüzdeki 14 gün içinde biten oyunlar
    final Map<String, List<HomeSession>> byShow = {};
    for (final HomeSession x in sessions) {
      byShow.putIfAbsent(x.show.id, () => []).add(x);
    }
    final List<(Show, HomeSession, int)> closing = [];
    for (final Show sh in shows) {
      final List<HomeSession>? l = byShow[sh.id];
      if (l == null || l.isEmpty) continue;
      l.sort((a, b) => a.date.compareTo(b.date));
      final int left = l.last.date.difference(DateTime.now()).inDays + 1;
      if (left <= 14) closing.add((sh, l.first, left < 1 ? 1 : left));
    }

    final String? spot = _spotKey ??
        (categories.isEmpty ? null : categories.first.key);
    final BrowseCategory? spotCat = spot == null
        ? null
        : categories.where((final c) => c.key == spot).firstOrNull;
    final List<Show> spotShows = spotCat == null
        ? const []
        : shows
            .where((final s) => browseCategoryKey(s.category) == spotCat.key)
            .take(14)
            .toList();

    // Vitrin slaytları: kampanyalar + seansı olan oyunlar
    final List<_Slide> slides = [
      for (final Campaign c in campaigns.take(3))
        if (c.imageUrl.startsWith('http'))
          _Slide(
            imageUrl: c.imageUrl,
            title: c.title,
            kicker: 'Kampanya',
            cta: 'Kampanyayı gör',
            onTap: () => NavigationHandler.goToCampaigns(context),
          ),
      for (final Show s in popular.take(4))
        _Slide(
          imageUrl: s.imageUrl,
          title: s.name,
          kicker: s.category.trim(),
          line: _sessionLine(nextByShow[s.id]),
          cta: s.hasExternalTicketing ? 'Biletini bul' : 'Bilet al',
          onTap: () => _openShow(s),
        ),
    ];

    return Scaffold(
      backgroundColor: cs.surface,
      body: LayoutBuilder(builder: (final context, final box) {
        final double w = box.maxWidth;
        final bool desktop = w >= 1024;
        final double gutter = w >= 1200 ? 48 : (w >= 768 ? 32 : 18);
        final double inner = (w > _kMaxW ? _kMaxW : w) - 2 * gutter;

        Widget section(final Widget child, {final double top = 56}) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _kMaxW),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(gutter, top, gutter, 0),
                  child: child,
                ),
              ),
            );

        Widget rail(final String title, final List<Show> list,
                {final String? action, final VoidCallback? onAction}) =>
            section(
              _ProductRail(
                title: title,
                width: inner,
                action: action ?? 'Tümünü gör',
                onAction:
                    onAction ?? () => NavigationHandler.goToDiscover(context),
                children: [
                  for (final Show s in list)
                    _ShowCard(
                        show: s,
                        next: nextByShow[s.id],
                        onOpen: () => _openShow(s)),
                ],
              ),
              top: 52,
            );

        return ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          }),
          child: SingleChildScrollView(
            controller: _scroll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1) VİTRİN
                section(
                  loading
                      ? SkBone(height: desktop ? 460 : 320, radius: 20)
                      : (slides.isEmpty
                          ? const _Empty(
                              title: 'Henüz oyun yok',
                              message: 'Perde açılınca vitrin burada olacak.')
                          : _HeroSlider(
                              slides: slides,
                              height: desktop ? 460 : 320)),
                  top: 24,
                ),
                section(WebPromoTiles(wide: desktop), top: 28),
                if (sessions.isNotEmpty)
                  section(_Reveal(child: _DateStrip(sessions: sessions, onOpen: _openShow)),
                      top: 56),
                // 2) YUVARLAK TÜR KAROLARI
                if (categories.length > 1)
                  section(_CategoryCircles(categories: categories), top: 36),
                // 3) RAFLAR
                if (popular.isNotEmpty)
                  section(_Reveal(
                      child: _ProductRail(
                    title: 'Popüler oyunlar',
                    width: inner,
                    action: 'Tümünü gör',
                    onAction: () => NavigationHandler.goToDiscover(context),
                    children: [
                      for (final Show s in popular)
                        _ShowCard(
                            show: s,
                            next: nextByShow[s.id],
                            onOpen: () => _openShow(s)),
                    ],
                  )), top: 52),
                if (ranked.length >= 3)
                  section(
                      _Reveal(
                          child: _TopTen(
                              shows: ranked,
                              nextByShow: nextByShow,
                              onOpen: _openShow)),
                      top: 64),
                if (weekShow != null)
                  section(
                      _Reveal(
                          child: _WeekSpotlight(
                        show: weekShow,
                        sessions: byShow[weekShow.id] ?? const [],
                        wide: desktop,
                        onOpen: () => _openShow(weekShow),
                      )),
                      top: 64),
                if (closing.isNotEmpty)
                  section(
                      _Reveal(
                          child: _ClosingRail(
                              items: closing.take(12).toList(),
                              onOpen: _openShow)),
                      top: 64),
                if (sessions.isNotEmpty)
                  section(
                    KeyedSubtree(
                      key: _agendaKey,
                      child: _Agenda(
                        sessions: sessions,
                        shown: _agendaShown,
                        wide: desktop,
                        onOpen: (final s) => _openShow(s.show),
                        onMore: () => setState(() => _agendaShown += 8),
                      ),
                    ),
                    top: 60,
                  ),
                if (fresh.isNotEmpty)
                  rail('Yeni eklenenler', fresh),
                // tür vitrini
                if (spotCat != null && spotShows.isNotEmpty && categories.length > 1)
                  section(
                    _GenreSpotlight(
                      categories: categories,
                      selected: spotCat,
                      shows: spotShows,
                      nextByShow: nextByShow,
                      width: inner,
                      onPick: (final c) => setState(() => _spotKey = c.key),
                      onOpen: _openShow,
                      onAll: () => NavigationHandler.goToDiscoverWithCategory(
                          context, spotCat.label),
                    ),
                    top: 60,
                  ),
                if (cheap.isNotEmpty)
                  section(
                      _Reveal(
                          child: _BudgetRail(
                              sessions: sessions,
                              width: inner,
                              onOpen: _openShow)),
                      top: 64),
                // NASIL ÇALIŞIR + SAYILAR
                section(WebHowItWorks(wide: desktop), top: 80),
                section(
                  _Reveal(
                    child: _CountStats(items: [
                      (shows.length, 'Oyun', Icons.theater_comedy_rounded),
                      (stages.length, 'Sahne', Icons.location_city_rounded),
                      (teams.length, 'Topluluk', Icons.groups_rounded),
                      (players.length, 'Oyuncu', Icons.person_rounded),
                    ]),
                  ),
                  top: 56,
                ),
                // 4) MEKÂNLAR + TOPLULUKLAR
                if (stages.isNotEmpty || teams.isNotEmpty)
                  section(
                    desktop
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (stages.isNotEmpty)
                                Expanded(
                                    flex: 8, child: _Venues(stages: stages)),
                              if (stages.isNotEmpty && teams.isNotEmpty)
                                const SizedBox(width: 48),
                              if (teams.isNotEmpty)
                                Expanded(
                                    flex: 4, child: _Troupes(teams: teams)),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (stages.isNotEmpty) _Venues(stages: stages),
                              if (teams.isNotEmpty) ...[
                                const SizedBox(height: 40),
                                _Troupes(teams: teams),
                              ],
                            ],
                          ),
                    top: 72,
                  ),
                if (players.any((final p) => p.imageUrl.startsWith('http')))
                  section(_PlayerRow(players: players), top: 72),
                // REHBER + SSS
                section(WebGuide(wide: desktop), top: 80),
                // 5) YARDIM
                section(const _HelpBlock(), top: 80),
                const SizedBox(height: 72),
                const WebMegaFooter(),
              ],
            ),
          ),
        );
      }),
    );
  }
}

double _priceOf(final HomeSession s) =>
    double.tryParse(s.event.price.trim().replaceAll(',', '.')) ?? 1e9;

String _priceFrom(final HomeSession? s) =>
    s?.priceLabel == null ? '' : "${s!.priceLabel}'den";

String _sessionLine(final HomeSession? n) {
  if (n == null) return '';
  final String venue = (n.stage?.name ?? '').trim();
  return '${skDayPhrase(n.date)} · ${skClock(n.date)}'
      '${venue.isEmpty ? '' : ' · $venue'}'
      '${n.priceLabel == null ? '' : ' · ${_priceFrom(n)}'}';
}

// ═════════════════════════════════════════════════════════════════════════════
// ORTAK
// ═════════════════════════════════════════════════════════════════════════════

/// Hover + odak + imleç + erişilebilirlik sarmalayıcısı (web).
class _Hoverable extends StatefulWidget {
  final Widget Function(bool hover) builder;
  final VoidCallback onTap;
  final String label;
  const _Hoverable(
      {required this.builder, required this.onTap, required this.label});

  @override
  State<_Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<_Hoverable> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(final BuildContext context) => Semantics(
        button: true,
        label: widget.label,
        child: FocusableActionDetector(
          onShowFocusHighlight: (final v) => setState(() => _focus = v),
          onShowHoverHighlight: (final v) => setState(() => _hover = v),
          mouseCursor: SystemMouseCursors.click,
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
              widget.onTap();
              return null;
            }),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: widget.builder(_hover || _focus),
          ),
        ),
      );
}

class _Title extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;
  const _Title({required this.title, this.subtitle, this.action, this.onAction});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(title, style: Sk.display(context, size: 30, height: 1.1)),
        if (subtitle != null) ...[
          const SizedBox(width: 14),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(subtitle!,
                style: Sk.ui(context,
                    size: 14,
                    color: cs.onSurfaceVariant,
                    weight: FontWeight.w600)),
          ),
        ],
        const Spacer(),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(action!,
                style: Sk.ui(context,
                    size: 14, color: cs.primary, weight: FontWeight.w800)),
          ),
      ],
    );
  }
}

class _Empty extends StatelessWidget {
  final String title;
  final String message;
  const _Empty({required this.title, required this.message});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(children: [
        Icon(Icons.event_busy_rounded, size: 36, color: cs.onSurfaceVariant),
        const SizedBox(height: 12),
        Text(title, style: Sk.ui(context, size: 17, weight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text(message,
            style: Sk.ui(context,
                size: 14, color: cs.onSurfaceVariant, weight: FontWeight.w500)),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// VİTRİN KAYDIRICI
// ═════════════════════════════════════════════════════════════════════════════

class _Slide {
  final String imageUrl;
  final String title;
  final String kicker;
  final String line;
  final String cta;
  final VoidCallback onTap;
  const _Slide({
    required this.imageUrl,
    required this.title,
    required this.kicker,
    required this.cta,
    required this.onTap,
    this.line = '',
  });
}

class _HeroSlider extends StatefulWidget {
  final List<_Slide> slides;
  final double height;
  const _HeroSlider({required this.slides, required this.height});

  @override
  State<_HeroSlider> createState() => _HeroSliderState();
}

class _HeroSliderState extends State<_HeroSlider> {
  final PageController _page = PageController();
  Timer? _timer;
  int _index = 0;
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (_hover || !mounted || widget.slides.length < 2) return;
      _go((_index + 1) % widget.slides.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _page.dispose();
    super.dispose();
  }

  void _go(final int i) {
    if (!_page.hasClients) return;
    _page.animateToPage(i,
        duration: Sk.reduceMotion(context)
            ? Duration.zero
            : const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic);
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final int n = widget.slides.length;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: SizedBox(
        height: widget.height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _page,
                itemCount: n,
                onPageChanged: (final i) => setState(() => _index = i),
                itemBuilder: (final context, final i) =>
                    _SlideView(slide: widget.slides[i]),
              ),
              if (n > 1) ...[
                Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _Arrow(
                        icon: Icons.chevron_left_rounded,
                        label: 'Önceki',
                        visible: _hover,
                        onTap: () => _go((_index - 1 + n) % n)),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _Arrow(
                        icon: Icons.chevron_right_rounded,
                        label: 'Sonraki',
                        visible: _hover,
                        onTap: () => _go((_index + 1) % n)),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < n; i++)
                        GestureDetector(
                          onTap: () => _go(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: i == _index ? 26 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: i == _index
                                  ? cs.primary
                                  : Colors.white.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Arrow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool visible;
  final VoidCallback onTap;
  const _Arrow(
      {required this.icon,
      required this.label,
      required this.visible,
      required this.onTap});

  @override
  Widget build(final BuildContext context) => AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: !visible,
          child: Material(
            color: Colors.black.withValues(alpha: 0.5),
            shape: const CircleBorder(),
            child: IconButton(
              tooltip: label,
              onPressed: onTap,
              icon: Icon(icon, color: Colors.white, size: 30),
            ),
          ),
        ),
      );
}

class _SlideView extends StatelessWidget {
  final _Slide slide;
  const _SlideView({required this.slide});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: slide.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SkImage(url: slide.imageUrl, alignment: Alignment.topCenter),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.5, 0.85],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(48, 32, 48, 56),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (slide.kicker.isNotEmpty)
                        SkBadge(label: slide.kicker, onImage: true),
                      const SizedBox(height: 14),
                      Text(slide.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.display(context,
                              size: 46, color: Colors.white, height: 1.05)),
                      if (slide.line.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(slide.line,
                            style: Sk.ui(context,
                                size: 15.5,
                                color: Colors.white.withValues(alpha: 0.9),
                                weight: FontWeight.w700)),
                      ],
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: slide.onTap,
                        style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            padding: const EdgeInsets.symmetric(horizontal: 28),
                            shape: const StadiumBorder()),
                        child: Text(slide.cta,
                            style: Sk.ui(context,
                                size: 15.5,
                                color: cs.onPrimary,
                                weight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// YUVARLAK TÜR KAROLARI
// ═════════════════════════════════════════════════════════════════════════════

class _CategoryCircles extends StatelessWidget {
  final List<BrowseCategory> categories;
  const _CategoryCircles({required this.categories});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return _ScrollRow(
      height: 168,
      itemWidth: 132,
      gap: 22,
      children: [
        for (final BrowseCategory c in categories)
          _Hoverable(
            label: '${c.label}, ${c.count} oyun',
            onTap: () =>
                NavigationHandler.goToDiscoverWithCategory(context, c.label),
            builder: (final hover) => SizedBox(
              width: 132,
              child: Column(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: hover
                            ? cs.primary
                            : cs.primary.withValues(alpha: 0.55),
                        width: 3),
                  ),
                  child: ClipOval(
                    child: SizedBox(
                      width: 108,
                      height: 108,
                      child: AnimatedScale(
                        scale: hover ? 1.08 : 1,
                        duration: const Duration(milliseconds: 240),
                        child: SkImage(
                            url: c.imageUrl,
                            alignment: Alignment.topCenter,
                            fallbackIcon: Icons.theater_comedy_rounded),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(c.label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: Sk.ui(context,
                        size: 13.5,
                        weight: FontWeight.w800,
                        height: 1.2,
                        color: hover ? cs.primary : cs.onSurface)),
              ]),
            ),
          ),
      ],
    );
  }
}

/// Yatay şerit + hover'da oklar (mouse ile de sürüklenebilir).
class _ScrollRow extends StatefulWidget {
  final List<Widget> children;
  final double height;
  final double itemWidth;
  final double gap;
  const _ScrollRow(
      {required this.children,
      required this.height,
      required this.itemWidth,
      required this.gap});

  @override
  State<_ScrollRow> createState() => _ScrollRowState();
}

class _ScrollRowState extends State<_ScrollRow> {
  final ScrollController _c = ScrollController();
  bool _hover = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _by(final double dir) {
    if (!_c.hasClients) return;
    final double step = _c.position.viewportDimension * 0.85 * dir;
    _c.animateTo(
        (_c.offset + step).clamp(0.0, _c.position.maxScrollExtent),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic);
  }

  @override
  Widget build(final BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: SizedBox(
          height: widget.height,
          child: Stack(children: [
            ListView.separated(
              controller: _c,
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: widget.children.length,
              separatorBuilder: (_, __) => SizedBox(width: widget.gap),
              itemBuilder: (_, final i) => widget.children[i],
            ),
            Positioned(
              left: -6,
              top: 0,
              bottom: 0,
              child: Center(
                  child: _Arrow(
                      icon: Icons.chevron_left_rounded,
                      label: 'Geri',
                      visible: _hover,
                      onTap: () => _by(-1))),
            ),
            Positioned(
              right: -6,
              top: 0,
              bottom: 0,
              child: Center(
                  child: _Arrow(
                      icon: Icons.chevron_right_rounded,
                      label: 'İleri',
                      visible: _hover,
                      onTap: () => _by(1))),
            ),
          ]),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// RAFLAR (ürün kartı düzeni)
// ═════════════════════════════════════════════════════════════════════════════

class _ProductRail extends StatelessWidget {
  final String title;
  final double width;
  final String action;
  final VoidCallback onAction;
  final List<Widget> children;

  const _ProductRail({
    required this.title,
    required this.width,
    required this.action,
    required this.onAction,
    required this.children,
  });

  @override
  Widget build(final BuildContext context) {
    const double cardW = 232;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Title(title: title, action: action, onAction: onAction),
        const SizedBox(height: 22),
        _ScrollRow(
          height: cardW * 1.5 + 128,
          itemWidth: cardW,
          gap: 24,
          children: [
            for (final Widget c in children) SizedBox(width: cardW, child: c),
          ],
        ),
      ],
    );
  }
}

class _ShowCard extends StatelessWidget {
  final Show show;
  final HomeSession? next;
  final VoidCallback onOpen;
  const _ShowCard({required this.show, required this.next, required this.onOpen});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final HomeSession? n = next;
    final String venue = (n?.stage?.name ?? '').trim();
    return _Hoverable(
      label: show.name,
      onTap: onOpen,
      builder: (final hover) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, hover ? -6 : 0, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: hover ? 0.4 : 0.2),
                  blurRadius: hover ? 24 : 12,
                  offset: Offset(0, hover ? 12 : 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SkImage(url: show.imageUrl, alignment: Alignment.topCenter),
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Wrap(spacing: 6, children: [
                        if (show.isRecentlyAdded)
                          const SkBadge(label: 'Yeni', accent: true),
                        if (show.hasExternalTicketing)
                          const SkBadge(
                              label: 'Başka platform',
                              onImage: true,
                              icon: Icons.open_in_new_rounded),
                      ]),
                    ),
                    Positioned(
                        right: 10, top: 10, child: RatingChip(showId: show.id)),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: AnimatedSlide(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        offset: hover ? Offset.zero : const Offset(0, 1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          color: cs.primary,
                          child: Text(
                              show.hasExternalTicketing
                                  ? 'Biletini bul'
                                  : 'Bilet al',
                              style: Sk.ui(context,
                                  size: 14,
                                  color: cs.onPrimary,
                                  weight: FontWeight.w800)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(show.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Sk.ui(context,
                  size: 15.5,
                  weight: FontWeight.w800,
                  height: 1.25,
                  color: hover ? cs.primary : cs.onSurface)),
          const SizedBox(height: 5),
          Text(
              n == null
                  ? 'Tarih yakında'
                  : '${skDayPhrase(n.date)} · ${skClock(n.date)}${venue.isEmpty ? '' : ' · $venue'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Sk.ui(context,
                  size: 12.5,
                  color: cs.onSurfaceVariant,
                  weight: FontWeight.w600)),
          if (n?.priceLabel != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(_priceFrom(n),
                  style: Sk.ui(context,
                      size: 15.5, color: cs.primary, weight: FontWeight.w800)),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TÜR VİTRİNİ ("Komediyi keşfet")
// ═════════════════════════════════════════════════════════════════════════════

class _GenreSpotlight extends StatelessWidget {
  final List<BrowseCategory> categories;
  final BrowseCategory selected;
  final List<Show> shows;
  final Map<String, HomeSession> nextByShow;
  final double width;
  final ValueChanged<BrowseCategory> onPick;
  final void Function(Show) onOpen;
  final VoidCallback onAll;

  const _GenreSpotlight({
    required this.categories,
    required this.selected,
    required this.shows,
    required this.nextByShow,
    required this.width,
    required this.onPick,
    required this.onOpen,
    required this.onAll,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            Text('${selected.label} türünü keşfet',
                style: Sk.display(context, size: 30, height: 1.1)),
            const SizedBox(width: 14),
            for (final BrowseCategory c in categories.take(8))
              _Hoverable(
                label: c.label,
                onTap: () => onPick(c),
                builder: (final hover) => AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: c.key == selected.key
                        ? cs.primary
                        : (hover
                            ? cs.surfaceContainerHighest
                            : cs.surfaceContainerHigh),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(c.label,
                      style: Sk.ui(context,
                          size: 13.5,
                          color: c.key == selected.key
                              ? cs.onPrimary
                              : cs.onSurface,
                          weight: FontWeight.w800)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _ProductRail(
          title: '',
          width: width,
          action: 'Tümünü gör',
          onAction: onAll,
          children: [
            for (final Show s in shows)
              _ShowCard(show: s, next: nextByShow[s.id], onOpen: () => onOpen(s)),
          ],
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// YAKLAŞAN SEANSLAR (tablo)
// ═════════════════════════════════════════════════════════════════════════════

class _Agenda extends StatelessWidget {
  final List<HomeSession> sessions;
  final int shown;
  final bool wide;
  final void Function(HomeSession) onOpen;
  final VoidCallback onMore;

  const _Agenda({
    required this.sessions,
    required this.shown,
    required this.wide,
    required this.onOpen,
    required this.onMore,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<HomeSession> list = sessions.take(shown).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Title(title: 'Yaklaşan seanslar', subtitle: '${sessions.length} seans'),
        const SizedBox(height: 22),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < list.length; i++) ...[
                _AgendaRow(
                    session: list[i],
                    wide: wide,
                    onOpen: () => onOpen(list[i])),
                if (i < list.length - 1)
                  Divider(
                      height: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.35)),
              ],
            ],
          ),
        ),
        if (sessions.length > shown) ...[
          const SizedBox(height: 18),
          Center(
            child: OutlinedButton(
              onPressed: onMore,
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(240, 50),
                  shape: const StadiumBorder()),
              child: const Text('Daha fazla seans göster'),
            ),
          ),
        ],
      ],
    );
  }
}

class _DateBlock extends StatelessWidget {
  final DateTime date;
  const _DateBlock({required this.date});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(kDaysShortTr[date.weekday - 1],
            style: Sk.ui(context,
                size: 11,
                color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                weight: FontWeight.w700)),
        Text('${date.day}',
            style: Sk.display(context,
                size: 24, height: 1.05, color: cs.onPrimaryContainer)),
        Text(kMonthsShortTr[date.month - 1],
            style: Sk.ui(context,
                size: 11,
                color: cs.onPrimaryContainer.withValues(alpha: 0.8),
                weight: FontWeight.w700)),
      ]),
    );
  }
}

class _AgendaRow extends StatelessWidget {
  final HomeSession session;
  final bool wide;
  final VoidCallback onOpen;
  const _AgendaRow(
      {required this.session, required this.wide, required this.onOpen});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Show show = session.show;
    final String venue = (session.stage?.name ?? '').trim();
    return _Hoverable(
      label: '${show.name}, ${skDayPhrase(session.date)}',
      onTap: onOpen,
      builder: (final hover) => AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
            horizontal: wide ? 24 : 14, vertical: wide ? 16 : 12),
        color: hover ? cs.primary.withValues(alpha: 0.07) : Colors.transparent,
        child: Row(
          children: [
            _DateBlock(date: session.date),
            const SizedBox(width: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: wide ? 52 : 44,
                height: wide ? 74 : 62,
                child: SkImage(url: show.imageUrl, alignment: Alignment.topCenter),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(show.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.ui(context,
                          size: 16,
                          weight: FontWeight.w800,
                          color: hover ? cs.primary : cs.onSurface)),
                  const SizedBox(height: 3),
                  Text(
                      wide
                          ? show.category.trim()
                          : '${skClock(session.date)}${venue.isEmpty ? '' : ' · $venue'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.ui(context,
                          size: 13,
                          color: cs.onSurfaceVariant,
                          weight: FontWeight.w600)),
                ],
              ),
            ),
            if (wide) ...[
              Expanded(
                flex: 4,
                child: Row(children: [
                  Icon(Icons.place_outlined,
                      size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(venue.isEmpty ? '—' : venue,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Sk.ui(context, size: 14, weight: FontWeight.w600)),
                  ),
                ]),
              ),
              SizedBox(
                width: 70,
                child: Text(skClock(session.date),
                    style: Sk.ui(context, size: 15, weight: FontWeight.w800)),
              ),
              SizedBox(
                width: 90,
                child: Text(session.priceLabel ?? '',
                    style: Sk.ui(context,
                        size: 15, color: cs.primary, weight: FontWeight.w800)),
              ),
              OutlinedButton(
                onPressed: onOpen,
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(110, 44),
                    shape: const StadiumBorder()),
                child: Text(
                    show.hasExternalTicketing ? 'Biletini bul' : 'Bilet al'),
              ),
            ] else if (session.priceLabel != null)
              Text(session.priceLabel!,
                  style: Sk.ui(context,
                      size: 14, color: cs.primary, weight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MEKÂNLAR · TOPLULUKLAR · OYUNCULAR
// ═════════════════════════════════════════════════════════════════════════════

class _Venues extends StatelessWidget {
  final List<Stage> stages;
  const _Venues({required this.stages});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<Stage> list = stages.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Title(title: 'Mekânlar', subtitle: 'Oyunların oynandığı sahneler'),
        const SizedBox(height: 22),
        LayoutBuilder(builder: (final context, final box) {
          final int cols = (box.maxWidth / 260).floor().clamp(1, 3);
          final double cw = (box.maxWidth - 20 * (cols - 1)) / cols;
          return Wrap(spacing: 20, runSpacing: 20, children: [
            for (final Stage s in list)
              SizedBox(
                width: cw,
                child: _Hoverable(
                  label: s.name,
                  onTap: () => NavigationHandler.goToStage(
                      context, s.id, s.name,
                      imageUrl: s.imageUrl, title: s.name),
                  builder: (final hover) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 16 / 10,
                          child: AnimatedScale(
                            scale: hover ? 1.05 : 1,
                            duration: const Duration(milliseconds: 250),
                            child: SkImage(
                                url: s.imageUrl,
                                fallbackIcon: Icons.location_city_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(s.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.ui(context,
                              size: 15.5,
                              weight: FontWeight.w800,
                              color: hover ? cs.primary : cs.onSurface)),
                      if (s.address.trim().isNotEmpty)
                        Text(s.address.trim(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Sk.ui(context,
                                size: 12.5,
                                color: cs.onSurfaceVariant,
                                weight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
          ]);
        }),
      ],
    );
  }
}

class _Troupes extends StatelessWidget {
  final List<Team> teams;
  const _Troupes({required this.teams});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<Team> list = teams.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Title(title: 'Topluluklar'),
        const SizedBox(height: 22),
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              for (int i = 0; i < list.length; i++) ...[
                _Hoverable(
                  label: list[i].name,
                  onTap: () => NavigationHandler.goToTeam(
                      context, list[i].id, list[i].name,
                      imageUrl: list[i].imageUrl, title: list[i].name),
                  builder: (final hover) => AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(14),
                    color: hover
                        ? cs.primary.withValues(alpha: 0.07)
                        : Colors.transparent,
                    child: Row(children: [
                      ClipOval(
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: SkImage(
                              url: list[i].imageUrl,
                              fallbackIcon: Icons.groups_rounded),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(list[i].name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Sk.ui(context,
                                size: 15, weight: FontWeight.w800)),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: cs.onSurfaceVariant),
                    ]),
                  ),
                ),
                if (i < list.length - 1)
                  Divider(
                      height: 1,
                      color: cs.outlineVariant.withValues(alpha: 0.35)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final List<Player> players;
  const _PlayerRow({required this.players});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<Player> list = [
      for (final Player p in players)
        if (p.imageUrl.startsWith('http')) p,
    ].take(14).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Title(title: 'Sahnenin yüzleri', subtitle: 'Oyuncular'),
        const SizedBox(height: 22),
        _ScrollRow(
          height: 170,
          itemWidth: 110,
          gap: 26,
          children: [
            for (final Player p in list)
              _Hoverable(
                label: '${p.firstName} ${p.lastName}'.trim(),
                onTap: () => NavigationHandler.goToPlayer(
                    context, p.id, '${p.firstName} ${p.lastName}'.trim(),
                    imageUrl: p.imageUrl,
                    title: '${p.firstName} ${p.lastName}'.trim()),
                builder: (final hover) => SizedBox(
                  width: 110,
                  child: Column(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: hover ? cs.primary : Colors.transparent,
                            width: 2),
                      ),
                      child: ClipOval(
                        child: SizedBox(
                          width: 96,
                          height: 96,
                          child: SkImage(
                              url: p.imageUrl,
                              alignment: const Alignment(0, -0.35),
                              fallbackIcon: Icons.person_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('${p.firstName} ${p.lastName}'.trim(),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: Sk.ui(context,
                            size: 13.5,
                            weight: FontWeight.w800,
                            height: 1.2,
                            color: hover ? cs.primary : cs.onSurface)),
                  ]),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// YARDIM + ÖZELLİK ŞERİDİ
// ═════════════════════════════════════════════════════════════════════════════

class _HelpBlock extends StatelessWidget {
  const _HelpBlock();

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<(String, IconData, VoidCallback)> items = [
      ('Bilet nasıl alınır?', Icons.confirmation_number_outlined,
          () => NavigationHandler.goToHelpSupport(context)),
      ('Sıkça sorulan sorular', Icons.quiz_outlined,
          () => NavigationHandler.goToHelpSupport(context)),
      ('Yakınımdaki sahneler', Icons.place_outlined,
          () => NavigationHandler.goToNearby(context)),
      ('Kampanyalar', Icons.local_offer_outlined,
          () => NavigationHandler.goToCampaigns(context)),
      ('Gizlilik ve şartlar', Icons.shield_outlined,
          () => NavigationHandler.goToContracts(context)),
    ];
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('Yardıma mı ihtiyacınız var?',
                  style: Sk.display(context, size: 28, height: 1.1)),
            ),
            FilledButton.icon(
              onPressed: () => TiyatrolCommunicationActions.sendEmail(),
              icon: const Icon(Icons.support_agent_rounded),
              label: const Text('Bize yazın'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: const StadiumBorder()),
            ),
          ]),
          const SizedBox(height: 22),
          Wrap(spacing: 14, runSpacing: 14, children: [
            for (final item in items)
              _Hoverable(
                label: item.$1,
                onTap: item.$3,
                builder: (final hover) => AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: hover ? cs.primaryContainer : cs.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: hover
                            ? cs.primary
                            : cs.outlineVariant.withValues(alpha: 0.6)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(item.$2, size: 20, color: cs.primary),
                    const SizedBox(width: 10),
                    Text(item.$1,
                        style: Sk.ui(context,
                            size: 14.5, weight: FontWeight.w700)),
                  ]),
                ),
              ),
          ]),
        ],
      ),
    );
  }
}

class _Benefits extends StatelessWidget {
  final bool wide;
  const _Benefits({required this.wide});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    const List<(IconData, String, String)> items = [
      (Icons.event_seat_rounded, 'Koltuğunu kendin seç',
          'Salon planından istediğin koltuğu işaretle'),
      (Icons.phone_iphone_rounded, 'Biletin cebinde',
          'Dijital bilet, uygulamada her zaman elinin altında'),
      (Icons.event_available_rounded, 'Takvime ekle',
          'Seansı tek dokunuşla takvimine kaydet'),
      (Icons.near_me_rounded, 'Yakındaki sahneler',
          'Konumuna göre oyunları haritada gör'),
    ];
    final List<Widget> cells = [
      for (final item in items)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: cs.primaryContainer, shape: BoxShape.circle),
            child: Icon(item.$1, color: cs.onPrimaryContainer),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.$2,
                      style: Sk.ui(context, size: 15.5, weight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(item.$3,
                      style: Sk.ui(context,
                          size: 13,
                          color: cs.onSurfaceVariant,
                          weight: FontWeight.w500,
                          height: 1.35)),
                ]),
          ),
        ]),
    ];
    return wide
        ? Row(children: [
            for (int i = 0; i < cells.length; i++) ...[
              Expanded(child: cells[i]),
              if (i < cells.length - 1) const SizedBox(width: 28),
            ],
          ])
        : Column(children: [
            for (final Widget c in cells) ...[c, const SizedBox(height: 20)],
          ]);
  }
}
