import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/deeplink/deeplink_service.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/navigation/widgets/web_site_header.dart';
import '../../../../shared/widgets/footers/web_mega_footer.dart';
import '../../../../shared/widgets/gallery_section.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../../shared/widgets/sahne/sketch.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../../shared/widgets/ticket/ticket_profile.dart'
    show splitShowsByLiveActivity;
import '../../../search/presentation/providers/search_query_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../shows/presentation/widgets/detail/sticky_aside.dart';
import '../../domain/entities/player.dart';
import '../providers/player_provider.dart';
import '../widgets/sahne/player_costars.dart';

/// OYUNCU SAYFASI — WEB. "Künye ve program": solda yapışkan fildişi OYUNCU
/// KÜNYESİ (portre, durum damgası, sayılar, paylaş), sağda kayan program
/// (hikâye + söz, sahnede olduğu oyunlar, ödüller, topluluklar, sahne
/// arkadaşları, geçmiş oyunlar). Kaydırınca üstte ince bölüm çubuğu belirir.
/// Mobil uygulamanın "canlı portre" sayfasından AYRIDIR.
class PlayerDetailPageWeb extends ConsumerStatefulWidget {
  final String playerId;
  const PlayerDetailPageWeb({super.key, required this.playerId});

  @override
  ConsumerState<PlayerDetailPageWeb> createState() =>
      _PlayerDetailPageWebState();
}

class _PlayerDetailPageWebState extends ConsumerState<PlayerDetailPageWeb>
    with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _rowKey = GlobalKey();
  final List<GlobalKey> _keys = List.generate(5, (_) => GlobalKey());
  late final AnimationController _entrance =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  bool _started = false;
  bool _showBar = false;
  int _active = 0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _entrance.dispose();
    super.dispose();
  }

  void _onScroll() {
    final bool show = _scroll.hasClients && _scroll.offset > 460;
    int active = 0;
    for (int i = 0; i < _keys.length; i++) {
      final RenderObject? ro = _keys[i].currentContext?.findRenderObject();
      if (ro is! RenderBox || !ro.attached) continue;
      if (ro.localToGlobal(Offset.zero).dy <= 260) active = i;
    }
    if (show != _showBar || active != _active) {
      setState(() {
        _showBar = show;
        _active = active;
      });
    }
  }

  void _goTo(final int i) {
    final BuildContext? c = _keys[i].currentContext;
    if (c == null) return;
    HapticFeedback.selectionClick();
    Scrollable.ensureVisible(c,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        alignment: 0.04);
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final async = ref.watch(playerDetailProvider(widget.playerId));
    final PlayerDetailState? state = async.value;

    Widget body;
    if (async.hasError && state == null) {
      body = Padding(
        padding: const EdgeInsets.all(64),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.person_off_rounded, size: 48),
            const SizedBox(height: 14),
            const Text('Oyuncu yüklenemedi'),
            const SizedBox(height: 14),
            OutlinedButton(
                onPressed: () =>
                    ref.invalidate(playerDetailProvider(widget.playerId)),
                child: const Text('Tekrar dene')),
          ]),
        ),
      );
    } else if (state == null) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 160),
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      if (!_started) {
        _started = true;
        _entrance.forward();
      }
      body = _content(context, state);
    }

    final String name = state == null
        ? ''
        : '${state.player.firstName} ${state.player.lastName}'.trim();
    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(children: [
        if (state != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AmbientBackdrop(
                url: state.player.imageUrl, height: 980, blur: 60, opacity: 0.4),
          ),
        SingleChildScrollView(
          controller: _scroll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const WebSiteHeader(),
              body,
              const SizedBox(height: 96),
              const WebMegaFooter(),
            ],
          ),
        ),
        if (state != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _Bar(
                visible: _showBar,
                title: name,
                active: _active,
                onTab: _goTo),
          ),
      ]),
    );
  }

  Widget _content(final BuildContext context, final PlayerDetailState state) {
    final Player p = state.player;
    final split = splitShowsByLiveActivity(
      claimedActive: state.activeShows,
      past: state.pastShows,
      liveActive: ref.watch(activeShowsProvider(false)).value,
    );
    final List<Show> active = split.active;
    final List<Show> past = split.past;
    final List<Map<String, String>> awards = [
      for (final a in p.achievements)
        if ((a['title'] ?? '').trim().isNotEmpty) a,
    ]..sort((a, b) => (b['year'] ?? '').compareTo(a['year'] ?? ''));
    final List<String> collabs = [
      for (final c in p.collaborations)
        if (c.trim().isNotEmpty) c.trim(),
    ];

    return LayoutBuilder(builder: (final context, final box) {
      final double w = box.maxWidth;
      final bool desktop = w >= 1100;
      final double gutter = w >= 1200 ? 56 : (w >= 768 ? 36 : 18);

      final Widget card = _CardTicket(
        player: p,
        active: active.length,
        past: past.length,
        awards: awards.length,
        onStage: active.isNotEmpty,
        entrance: _entrance,
      );
      final Widget program = _PlayerProgram(
        player: p,
        active: active,
        past: past,
        awards: awards,
        collabs: collabs,
        keys: _keys,
        entrance: _entrance,
        onSearch: (final c) {
          ref.read(searchQueryProvider.notifier).update(c);
          ref.read(searchFilterProvider.notifier).setFilter(0);
          NavigationHandler.goToSearch(context);
        },
      );
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Padding(
            padding: EdgeInsets.fromLTRB(gutter, 24, gutter, 0),
            child: desktop
                ? Row(
                    key: _rowKey,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 420,
                        child: StickyAside(
                          controller: _scroll,
                          rowKey: _rowKey,
                          contentTop: 150,
                          gap: 88,
                          child: card,
                        ),
                      ),
                      const SizedBox(width: 72),
                      Expanded(child: program),
                    ],
                  )
                : Column(children: [
                    Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: card),
                    ),
                    const SizedBox(height: 40),
                    program,
                  ]),
          ),
        ),
      );
    });
  }
}

class _Bar extends StatelessWidget {
  final bool visible;
  final String title;
  final int active;
  final ValueChanged<int> onTab;
  const _Bar(
      {required this.visible,
      required this.title,
      required this.active,
      required this.onTab});

  static const List<String> _labels = [
    'Hakkında',
    'Sahnede',
    'Ödüller',
    'Topluluklar',
    'Geçmiş',
  ];

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool wide = MediaQuery.sizeOf(context).width >= 900;
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, -1),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        child: Material(
          color: cs.surface.withValues(alpha: 0.96),
          elevation: 6,
          shadowColor: Colors.black.withValues(alpha: 0.4),
          child: SizedBox(
            height: 64,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1360),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: wide ? 56 : 18),
                  child: Row(children: [
                    Expanded(
                      child: Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.display(context, size: 22, height: 1.1)),
                    ),
                    if (wide)
                      for (int i = 0; i < _labels.length; i++)
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onTab(i),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 180),
                                style: Sk.ui(context,
                                    size: 14.5,
                                    color: active == i
                                        ? cs.primary
                                        : cs.onSurfaceVariant,
                                    weight: FontWeight.w800),
                                child: Text(_labels[i]),
                              ),
                            ),
                          ),
                        ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// KÜNYE BİLETİ
// ═════════════════════════════════════════════════════════════════════════════

class _CardTicket extends StatelessWidget {
  final Player player;
  final int active;
  final int past;
  final int awards;
  final bool onStage;
  final AnimationController entrance;

  const _CardTicket({
    required this.player,
    required this.active,
    required this.past,
    required this.awards,
    required this.onStage,
    required this.entrance,
  });

  @override
  Widget build(final BuildContext context) {
    final bool reduce = Sk.reduceMotion(context);
    final String name = '${player.firstName} ${player.lastName}'.trim();
    final bool hasPhoto = player.imageUrl.startsWith('http');

    Widget count(final String label, final int n) => Expanded(
          child: TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: n),
            duration:
                reduce ? Duration.zero : const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            builder: (_, final v, __) =>
                TicketField(label: label, value: '$v'),
          ),
        );

    final Widget paper = TicketPiece(
      perforated: TicketEdge.bottom,
      notch: 16,
      corner: 22,
      shadows: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 44,
            offset: const Offset(0, 22)),
      ],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const TicketHeaderStrip(kind: 'OYUNCU KÜNYESİ'),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: hasPhoto
                  ? () => GalleryViewerDialog.open(
                      context, [player.imageUrl.trim()])
                  : null,
              child: MouseRegion(
                cursor:
                    hasPhoto ? SystemMouseCursors.zoomIn : MouseCursor.defer,
                child: _TiltPortrait(url: player.imageUrl),
              ),
            ),
            const SizedBox(height: 18),
            Text(name, style: TicketInk.headline(30)),
            const SizedBox(height: 10),
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: onStage
                          ? TicketInk.accentOf(context)
                          : TicketInk.inkSoft(0.4),
                      width: 1.8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(onStage ? 'ŞU AN SAHNEDE' : 'SAHNEYE ARA VERDİ',
                    style: TextStyle(
                        color: onStage
                            ? TicketInk.accentOf(context)
                            : TicketInk.inkSoft(0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8)),
              ),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              count('SAHNEDE', active),
              count('GEÇMİŞ', past),
              count('ÖDÜL', awards),
            ]),
            const SizedBox(height: 18),
            const SizedBox(height: 2, child: TicketPerforation()),
            const SizedBox(height: 16),
            TicketStampButton(
              label: 'Paylaş',
              leading: const Icon(Icons.ios_share_rounded, size: 18),
              onTap: () => TiyatrolDeeplinkService.shareActor(
                  id: player.id, name: name),
            ),
            const SizedBox(height: 16),
            TicketBarcode(seed: player.id, height: 34),
          ],
        ),
      ),
    );

    return AnimatedBuilder(
      animation: entrance,
      builder: (final context, final child) {
        final double t = reduce
            ? 1
            : Curves.easeOutCubic
                .transform((entrance.value / 0.7).clamp(0.0, 1.0));
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 40),
            child: Transform.rotate(angle: (1 - t) * 0.02, child: child),
          ),
        );
      },
      child: paper,
    );
  }
}

/// Uzun hap portre: fare üstünde 3B eğilir, boşta çok yavaş yakınlaşır.
class _TiltPortrait extends StatefulWidget {
  final String url;
  const _TiltPortrait({required this.url});

  @override
  State<_TiltPortrait> createState() => _TiltPortraitState();
}

class _TiltPortraitState extends State<_TiltPortrait>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift =
      AnimationController(vsync: this, duration: const Duration(seconds: 18));
  Offset _tilt = Offset.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Sk.reduceMotion(context)) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => MouseRegion(
        onHover: (final e) {
          final Size? b = context.size;
          if (b == null) return;
          setState(() => _tilt = Offset(
                ((e.localPosition.dx / b.width) * 2 - 1).clamp(-1.0, 1.0),
                ((e.localPosition.dy / b.height) * 2 - 1).clamp(-1.0, 1.0),
              ));
        },
        onExit: (_) => setState(() => _tilt = Offset.zero),
        child: TweenAnimationBuilder<Offset>(
          tween: Tween(begin: Offset.zero, end: _tilt),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          builder: (final context, final t, final child) => Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(-t.dy * 0.07)
              ..rotateY(t.dx * 0.09),
            child: child,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(160), bottom: Radius.circular(18)),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: AnimatedBuilder(
                animation: _drift,
                builder: (_, final child) => Transform.scale(
                    scale: 1.0 + 0.05 * _drift.value, child: child),
                child: SkImage(
                    url: widget.url,
                    alignment: const Alignment(0, -0.35),
                    fallbackIcon: Icons.person_rounded),
              ),
            ),
          ),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// PROGRAM
// ═════════════════════════════════════════════════════════════════════════════

class _PlayerProgram extends StatelessWidget {
  final Player player;
  final List<Show> active;
  final List<Show> past;
  final List<Map<String, String>> awards;
  final List<String> collabs;
  final List<GlobalKey> keys;
  final AnimationController entrance;
  final void Function(String) onSearch;

  const _PlayerProgram({
    required this.player,
    required this.active,
    required this.past,
    required this.awards,
    required this.collabs,
    required this.keys,
    required this.entrance,
    required this.onSearch,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String name = '${player.firstName} ${player.lastName}'.trim();
    final String bio = player.bio.replaceAll('\\n', '\n').trim();
    final String quote = player.quote.trim();

    Widget gap(final double h) => SizedBox(height: h);
    Widget section(final int i, final String title, final String sub,
            final Widget child) =>
        KeyedSubtree(
          key: keys[i],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkSectionHead(title: title, subtitle: sub),
              const SizedBox(height: 26),
              child,
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => NavigationHandler.goToHome(context),
              child: Text('Ana Sayfa',
                  style: Sk.ui(context,
                      size: 13, color: cs.primary, weight: FontWeight.w700)),
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 16, color: cs.onSurfaceVariant),
          Text('Oyuncular',
              style: Sk.ui(context,
                  size: 13,
                  color: cs.onSurfaceVariant,
                  weight: FontWeight.w700)),
        ]),
        gap(26),
        _WordTitle(text: name, entrance: entrance),
        gap(14),
        SkSquiggle(width: 150, seed: name.length),
        if (quote.isNotEmpty) ...[
          gap(16),
          Text('“$quote”',
              style: Sketch.hand(context, size: 34, color: cs.primary)),
        ],

        gap(72),
        section(
          0,
          'Hakkında',
          'perde arkasından kısa bir not',
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: _Bio(
                text: bio.isEmpty
                    ? 'Bu oyuncu için henüz bir biyografi eklenmemiş.'
                    : bio),
          ),
        ),

        gap(72),
        section(
          1,
          'Sahnede',
          active.isEmpty
              ? 'şu an oyunu yok'
              : '${active.length} oyunda sahnede',
          active.isEmpty
              ? Text('Şu an sahnede olduğu bir oyun yok.',
                  style: Sk.ui(context,
                      size: 15.5,
                      color: cs.onSurfaceVariant,
                      weight: FontWeight.w500))
              : _PosterFan(shows: active),
        ),

        if (awards.isNotEmpty) ...[
          gap(72),
          section(
            2,
            'Ödüller',
            '${awards.length} ödül',
            Column(children: [
              for (final Map<String, String> a in awards) _Award(a: a),
            ]),
          ),
        ] else
          KeyedSubtree(key: keys[2], child: const SizedBox.shrink()),

        if (collabs.isNotEmpty) ...[
          gap(72),
          section(
            3,
            'Çalıştığı topluluklar',
            '${collabs.length} topluluk, dokun ve oyunlarını ara',
            Wrap(spacing: 14, runSpacing: 14, children: [
              for (final String c in collabs)
                _CollabChip(label: c, onTap: () => onSearch(c)),
            ]),
          ),
        ] else
          KeyedSubtree(key: keys[3], child: const SizedBox.shrink()),

        gap(72),
        PlayerCoStars(player: player, shows: [...active, ...past]),

        if (past.isNotEmpty) ...[
          gap(72),
          section(
            4,
            'Geçmiş oyunlar',
            '${past.length} oyun',
            _PastGrid(shows: past),
          ),
        ] else
          KeyedSubtree(key: keys[4], child: const SizedBox.shrink()),
      ],
    );
  }
}

class _WordTitle extends StatelessWidget {
  final String text;
  final AnimationController entrance;
  const _WordTitle({required this.text, required this.entrance});

  @override
  Widget build(final BuildContext context) {
    final List<String> words =
        text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final bool reduce = Sk.reduceMotion(context);
    return AnimatedBuilder(
      animation: entrance,
      builder: (final context, _) => Wrap(
        spacing: 18,
        children: [
          for (int i = 0; i < words.length; i++)
            () {
              final double start = (0.15 + i * 0.12).clamp(0.0, 0.7);
              final double v = reduce
                  ? 1
                  : Curves.easeOutCubic.transform(
                      ((entrance.value - start) / (1 - start)).clamp(0.0, 1.0));
              return ClipRect(
                child: Opacity(
                  opacity: v,
                  child: Transform.translate(
                    offset: Offset(0, (1 - v) * 40),
                    child: Text(words[i],
                        style: Sk.display(context, size: 76, height: 1.04)),
                  ),
                ),
              );
            }(),
        ],
      ),
    );
  }
}

class _Bio extends StatefulWidget {
  final String text;
  const _Bio({required this.text});

  @override
  State<_Bio> createState() => _BioState();
}

class _BioState extends State<_Bio> {
  bool _open = false;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String t = widget.text.trim();
    final bool letter =
        t.isNotEmpty && RegExp(r'^[A-Za-zÇĞİÖŞÜçğıöşü]').hasMatch(t);
    final String first = letter ? t.substring(0, 1) : '';
    final String rest = letter ? t.substring(1) : t;
    final bool long = t.length > 520;
    final Widget text = SelectableText(rest,
        maxLines: _open || !long ? null : 9,
        style: Sk.ui(context,
            size: 17,
            weight: FontWeight.w500,
            height: 1.8,
            color: cs.onSurface.withValues(alpha: 0.9)));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: letter
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12, top: 2),
                  child: Text(first,
                      style: Sk.display(context,
                          size: 92, height: 0.86, color: cs.primary)),
                ),
                Expanded(child: text),
              ])
            : text,
      ),
      if (long)
        TextButton(
          onPressed: () => setState(() => _open = !_open),
          child: Text(_open ? 'Daha az göster' : 'Devamını oku'),
        ),
    ]);
  }
}

/// Sahnede olduğu oyunlar: hafif eğik afişler, üzerine gelince düzelip yükselir.
class _PosterFan extends StatelessWidget {
  final List<Show> shows;
  const _PosterFan({required this.shows});

  @override
  Widget build(final BuildContext context) => SizedBox(
        height: 410,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: shows.length,
          separatorBuilder: (_, __) => const SizedBox(width: 30),
          itemBuilder: (final context, final i) =>
              _FanCard(show: shows[i], index: i),
        ),
      );
}

class _FanCard extends StatefulWidget {
  final Show show;
  final int index;
  const _FanCard({required this.show, required this.index});

  @override
  State<_FanCard> createState() => _FanCardState();
}

class _FanCardState extends State<_FanCard> {
  bool _hover = false;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double rot = (widget.index.isEven ? -1 : 1) * 0.035;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => NavigationHandler.goToShow(
            context, widget.show.id, widget.show.name,
            imageUrl: widget.show.imageUrl, title: widget.show.name),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: 236,
          transformAlignment: Alignment.bottomCenter,
          transform: Matrix4.identity()
            ..translateByDouble(0, _hover ? -12 : 0, 0, 1)
            ..rotateZ(_hover ? 0 : rot),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: skSoftShadow(context, strength: _hover ? 1.3 : 0.8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: SkImage(
                          url: widget.show.imageUrl,
                          alignment: Alignment.topCenter),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(widget.show.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Sk.ui(context,
                        size: 15.5,
                        weight: FontWeight.w800,
                        height: 1.25,
                        color: _hover ? cs.primary : cs.onSurface)),
              ]),
        ),
      ),
    );
  }
}

class _Award extends StatelessWidget {
  final Map<String, String> a;
  const _Award({required this.a});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 120,
            child: Text((a['year'] ?? '').trim(),
                style: Sk.display(context,
                    size: 44, height: 1.0, color: cs.primary)),
          ),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text((a['title'] ?? '').trim(),
                      style: Sk.ui(context,
                          size: 19, weight: FontWeight.w800, height: 1.25)),
                  if ((a['detail'] ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text((a['detail'] ?? '').trim(),
                          style: Sk.ui(context,
                              size: 15,
                              color: cs.onSurfaceVariant,
                              weight: FontWeight.w500)),
                    ),
                ]),
          ),
        ]),
      ),
    );
  }
}

class _CollabChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _CollabChip({required this.label, required this.onTap});

  @override
  State<_CollabChip> createState() => _CollabChipState();
}

class _CollabChipState extends State<_CollabChip> {
  bool _hover = false;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            color: _hover ? cs.primary : cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.groups_rounded,
                size: 20, color: _hover ? cs.onPrimary : cs.primary),
            const SizedBox(width: 10),
            Text(widget.label,
                style: Sk.ui(context,
                    size: 15,
                    color: _hover ? cs.onPrimary : cs.onSurface,
                    weight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }
}

class _PastGrid extends StatelessWidget {
  final List<Show> shows;
  const _PastGrid({required this.shows});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (final context, final box) {
      final int cols = (box.maxWidth / 200).floor().clamp(2, 5);
      const double gap = 22;
      final double cw = (box.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(spacing: gap, runSpacing: 30, children: [
        for (final Show s in shows)
          SizedBox(
            width: cw,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => NavigationHandler.goToShow(context, s.id, s.name,
                    imageUrl: s.imageUrl, title: s.name),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: AspectRatio(
                          aspectRatio: 2 / 3,
                          child: ColorFiltered(
                            colorFilter: ColorFilter.mode(
                                Colors.black.withValues(alpha: 0.18),
                                BlendMode.darken),
                            child: SkImage(
                                url: s.imageUrl, alignment: Alignment.topCenter),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(s.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.ui(context,
                              size: 14.5,
                              weight: FontWeight.w800,
                              height: 1.25,
                              color: cs.onSurface)),
                    ]),
              ),
            ),
          ),
      ]);
    });
  }
}
