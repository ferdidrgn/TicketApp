import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/util/recent_history.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/navigation/widgets/web_site_header.dart';
import '../../../../shared/widgets/footers/web_mega_footer.dart';
import '../../../../shared/widgets/gallery_section.dart';
import '../../../../shared/widgets/sahne/flower_portrait.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../../shared/widgets/sahne/sketch.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../auth/presentation/providers/auth_provider.dart'
    show currentUserIdProvider;
import '../../../chatbot/presentation/widgets/show_chat_bubble_button.dart';
import '../../../players/domain/entities/player.dart';
import '../../../reviews/data/review_repository.dart';
import '../../../reviews/presentation/providers/review_providers.dart';
import '../../../reviews/presentation/widgets/review_widgets.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../domain/entities/show.dart';
import '../providers/show_detail_provider.dart';
import '../providers/show_provider.dart';
import '../widgets/detail/show_detail_actions.dart';
import '../widgets/detail/show_detail_data.dart';
import '../widgets/detail/sticky_aside.dart';
import '../widgets/sahne/show_session_extras.dart';

/// OYUN DETAYI — WEB. "Program ve bilet": tiyatro programı (sağda kayan
/// hikâye, kadro, seanslar, galeri, yorumlar) + solda yapışkan fildişi
/// OYUN BİLETİ. Seçilen seans bilete anında yansır; "Koltuk seç" damgası
/// birincil aksiyondur. Kaydırınca üstte ince bir çubuk (ad + bölümler +
/// aksiyon) belirir. Mobil uygulamanın "Sahne" sayfasından AYRIDIR.
class ShowDetailPage extends ConsumerStatefulWidget {
  final String showId;
  const ShowDetailPage({super.key, required this.showId});

  @override
  ConsumerState<ShowDetailPage> createState() => _ShowDetailPageState();
}

class _ShowDetailPageState extends ConsumerState<ShowDetailPage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _rowKey = GlobalKey();
  final List<GlobalKey> _sectionKeys = List.generate(5, (_) => GlobalKey());
  late final AnimationController _entrance =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  ShowSession? _selected;
  DateTime? _day;
  int _active = 0;
  bool _showBar = false;
  bool _recorded = false;
  bool _opening = false;

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
    final bool show = _scroll.hasClients && _scroll.offset > 520;
    int active = 0;
    for (int i = 0; i < _sectionKeys.length; i++) {
      final BuildContext? c = _sectionKeys[i].currentContext;
      if (c == null) continue;
      final RenderObject? ro = c.findRenderObject();
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
    final BuildContext? c = _sectionKeys[i].currentContext;
    if (c == null) return;
    HapticFeedback.selectionClick();
    Scrollable.ensureVisible(c,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        alignment: 0.04);
  }

  List<String> _photos(final Show s) {
    final List<String> out = [];
    final String poster = s.imageUrl.trim();
    if (poster.startsWith('http')) out.add(poster);
    for (final String p in s.photosShowId) {
      final String u = p.trim();
      if (u.startsWith('http') && !out.contains(u)) out.add(u);
    }
    return out;
  }

  Future<void> _buy(final ShowDetailData d, final ShowSession? chosen) async {
    if (d.isExternal) {
      if (_opening) return;
      setState(() => _opening = true);
      await openExternalTickets(context, d.show.externalTicketUrl);
      if (mounted) setState(() => _opening = false);
      return;
    }
    if (chosen == null) return;
    HapticFeedback.mediumImpact();
    final String uid = ref.read(currentUserIdProvider) ?? 'guest';
    NavigationHandler.goToSeatSelection(
        context, widget.showId, chosen.event.id, uid);
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final async = ref.watch(showDetailProvider(widget.showId));
    final ShowDetailState? state = async.value;

    Widget body;
    if (async.hasError && state == null) {
      body = Padding(
        padding: const EdgeInsets.all(64),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.theater_comedy_rounded, size: 48),
            const SizedBox(height: 14),
            const Text('Oyun yüklenemedi'),
            const SizedBox(height: 14),
            OutlinedButton(
                onPressed: () =>
                    ref.invalidate(showDetailProvider(widget.showId)),
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
      final ShowDetailData d = ShowDetailData.from(state);
      if (!_recorded) {
        _recorded = true;
        _entrance.forward();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(recentShowIdsProvider.notifier).add(widget.showId);
          }
        });
      }
      body = _content(context, d);
    }

    final String? name = state?.show.name;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(children: [
        if (state != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AmbientBackdrop(
                url: state.show.imageUrl, height: 980, blur: 60, opacity: 0.42),
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
        if (state != null && name != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _StickyBar(
              visible: _showBar,
              title: name,
              active: _active,
              onTab: _goTo,
              action: _barAction(state),
            ),
          ),
      ]),
      floatingActionButton: state == null
          ? null
          : ShowChatBubbleButton(
              showId: state.show.id, showName: state.show.name),
    );
  }

  Widget _barAction(final ShowDetailState state) {
    final ShowDetailData d = ShowDetailData.from(state);
    final ShowSession? chosen = _chosen(d);
    final bool canBuy = d.isExternal || chosen != null;
    return FilledButton(
      onPressed: canBuy && !_opening ? () => _buy(d, chosen) : null,
      style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44), shape: const StadiumBorder()),
      child: Text(d.isExternal ? 'Biletini bul' : 'Koltuk seç'),
    );
  }

  ShowSession? _chosen(final ShowDetailData d) {
    if (_selected != null &&
        d.sessions.any((final s) => s.event.id == _selected!.event.id)) {
      return _selected;
    }
    if (_day != null) {
      for (final ShowSession s in d.sessions) {
        if (s.when != null && skDay(s.when!) == _day) return s;
      }
    }
    return d.nextSession;
  }

  Widget _content(final BuildContext context, final ShowDetailData d) {
    final ShowSession? chosen = _chosen(d);
    return LayoutBuilder(builder: (final context, final box) {
      final double w = box.maxWidth;
      final bool desktop = w >= 1100;
      final double gutter = w >= 1200 ? 56 : (w >= 768 ? 36 : 18);

      final Widget ticket = _TicketCard(
        data: d,
        chosen: chosen,
        busy: _opening,
        entrance: _entrance,
        onSession: (final s) => setState(() {
          _selected = s;
          if (s.when != null) _day = skDay(s.when!);
        }),
        onBuy: () => _buy(d, chosen),
      );

      final Widget program = _Program(
        data: d,
        chosen: chosen,
        sectionKeys: _sectionKeys,
        entrance: _entrance,
        photos: _photos(d.show),
        onSession: (final s) => setState(() {
          _selected = s;
          if (s.when != null) _day = skDay(s.when!);
        }),
        onGoReviews: () => _goTo(4),
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
                        width: 440,
                        child: StickyAside(
                          controller: _scroll,
                          rowKey: _rowKey,
                          contentTop: 150,
                          gap: 88,
                          child: ticket,
                        ),
                      ),
                      const SizedBox(width: 72),
                      Expanded(child: program),
                    ],
                  )
                : Column(children: [
                    Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: ticket),
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

// ═════════════════════════════════════════════════════════════════════════════
// YAPIŞKAN ÜST ÇUBUK
// ═════════════════════════════════════════════════════════════════════════════

class _StickyBar extends StatelessWidget {
  final bool visible;
  final String title;
  final int active;
  final ValueChanged<int> onTab;
  final Widget action;
  const _StickyBar(
      {required this.visible,
      required this.title,
      required this.active,
      required this.onTab,
      required this.action});

  static const List<String> _labels = [
    'Hikâye',
    'Kadro',
    'Seanslar',
    'Galeri',
    'Yorumlar',
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
                      flex: wide ? 3 : 1,
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
                    const SizedBox(width: 12),
                    action,
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
// OYUN BİLETİ (solda, yapışkan)
// ═════════════════════════════════════════════════════════════════════════════

class _TicketCard extends StatelessWidget {
  final ShowDetailData data;
  final ShowSession? chosen;
  final bool busy;
  final AnimationController entrance;
  final ValueChanged<ShowSession> onSession;
  final VoidCallback onBuy;

  const _TicketCard({
    required this.data,
    required this.chosen,
    required this.busy,
    required this.entrance,
    required this.onSession,
    required this.onBuy,
  });

  @override
  Widget build(final BuildContext context) {
    final Show show = data.show;
    final bool external = data.isExternal;
    final DateTime? when = chosen?.when;
    final String venue = (chosen?.venueName ?? '').trim();
    final String dateText = when == null
        ? (chosen?.shortLabel ?? '—')
        : '${when.day} ${kMonthsTr[when.month - 1]}';
    final String timeText = when == null ? '—' : skClock(when);
    final double? price = chosen?.price ?? data.lowestPrice;
    final bool canBuy = external || chosen != null;
    final bool reduce = Sk.reduceMotion(context);

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
            TicketHeaderStrip(kind: data.kindLabel),
            const SizedBox(height: 16),
            _TiltPoster(url: show.imageUrl),
            const SizedBox(height: 18),
            Text(show.name,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TicketInk.headline(26)),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (final child, final anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(0, 0.25), end: Offset.zero)
                      .animate(anim),
                  child: child,
                ),
              ),
              child: Row(
                key: ValueKey<String>('${chosen?.event.id}-$dateText-$timeText'),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      flex: 5,
                      child: TicketField(label: 'TARİH', value: dateText)),
                  Expanded(
                      flex: 3,
                      child: TicketField(label: 'SAAT', value: timeText)),
                  Expanded(
                      flex: 6,
                      child: TicketField(
                          label: 'SAHNE', value: venue.isEmpty ? '—' : venue)),
                ],
              ),
            ),
            if (!external && data.sessions.length > 1) ...[
              const SizedBox(height: 14),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: data.sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (final context, final i) {
                    final ShowSession s = data.sessions[i];
                    final bool sel = s.event.id == chosen?.event.id;
                    final DateTime? w = s.when;
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => onSession(s),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: sel
                                ? TicketInk.accentOf(context)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: TicketInk.accentOf(context)
                                    .withValues(alpha: sel ? 1 : 0.5)),
                          ),
                          child: Text(
                              w == null
                                  ? s.shortLabel
                                  : '${w.day} ${kMonthsShortTr[w.month - 1]} ${skClock(w)}',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: sel
                                      ? TicketInk.onAccentOf(context)
                                      : TicketInk.ink)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 18),
            const SizedBox(height: 2, child: TicketPerforation()),
            const SizedBox(height: 16),
            Row(children: [
              if (price != null)
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BİLET FİYATI', style: TicketInk.label()),
                        const SizedBox(height: 2),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: price),
                          duration: reduce
                              ? Duration.zero
                              : const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder: (_, final v, __) => Text(skPrice(v),
                              style: TicketInk.headline(32)),
                        ),
                      ]),
                ),
              Expanded(
                flex: price == null ? 1 : 2,
                child: TicketStampButton(
                  label: external ? 'Biletini bul' : 'Koltuk seç',
                  leading: Icon(
                      external
                          ? Icons.open_in_new_rounded
                          : Icons.event_seat_rounded,
                      size: 18),
                  loading: busy,
                  onTap: canBuy ? onBuy : null,
                ),
              ),
            ]),
            const SizedBox(height: 16),
            TicketBarcode(seed: show.id, height: 36),
          ],
        ),
      ),
    );

    // Giriş: bilet aşağıdan süzülür ve hafifçe döner (bir kez).
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
            child: Transform.rotate(angle: (1 - t) * -0.02, child: child),
          ),
        );
      },
      child: paper,
    );
  }
}

/// Afiş: fare üzerinde hafifçe 3B eğilir, boşta çok yavaş yakınlaşır.
class _TiltPoster extends StatefulWidget {
  final String url;
  const _TiltPoster({required this.url});

  @override
  State<_TiltPoster> createState() => _TiltPosterState();
}

class _TiltPosterState extends State<_TiltPoster>
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
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: AnimatedBuilder(
                animation: _drift,
                builder: (_, final child) => Transform.scale(
                    scale: 1.0 + 0.045 * _drift.value, child: child),
                child: SkImage(url: widget.url, alignment: Alignment.topCenter),
              ),
            ),
          ),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// PROGRAM (sağda)
// ═════════════════════════════════════════════════════════════════════════════

class _Program extends ConsumerWidget {
  final ShowDetailData data;
  final ShowSession? chosen;
  final List<GlobalKey> sectionKeys;
  final AnimationController entrance;
  final List<String> photos;
  final ValueChanged<ShowSession> onSession;
  final VoidCallback onGoReviews;

  const _Program({
    required this.data,
    required this.chosen,
    required this.sectionKeys,
    required this.entrance,
    required this.photos,
    required this.onSession,
    required this.onGoReviews,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Show show = data.show;
    final ReviewStat? stat = ref.watch(reviewStatsProvider).value?[show.id];
    final String desc = data.description;
    final List<Player> cast = [...data.cast, ...data.pastCast];

    Widget gap(final double h) => SizedBox(height: h);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Crumbs(show: show),
        gap(26),
        // Başlık: kelime kelime açılır
        _WordTitle(text: show.name, entrance: entrance),
        gap(14),
        SkSquiggle(width: 150, seed: show.name.length),
        gap(14),
        Text(
            [
              if (show.category.trim().isNotEmpty) show.category.trim(),
              if (show.type.trim().isNotEmpty &&
                  show.type.trim().toLowerCase() !=
                      show.category.trim().toLowerCase())
                show.type.trim(),
            ].join(' · '),
            style: Sketch.hand(context, size: 30, color: cs.primary)),
        gap(22),
        Wrap(spacing: 30, runSpacing: 12, children: [
          if (show.duration.trim().isNotEmpty)
            _Fact(Icons.schedule_rounded, 'Süre', show.duration.trim()),
          if (show.ageLimit.trim().isNotEmpty)
            _Fact(Icons.shield_outlined, 'Yaş sınırı', show.ageLimit.trim()),
          if (data.lowestPrice != null)
            _Fact(Icons.sell_outlined, 'Bilet', "${skPrice(data.lowestPrice!)}'den"),
          if (stat != null && stat.count > 0)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onGoReviews,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  StarRow(rating: stat.average, size: 20),
                  const SizedBox(width: 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: stat.average),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, final v, __) => Text(
                        '${v.toStringAsFixed(1)} · ${stat.count} yorum',
                        style: Sk.ui(context,
                            size: 14.5,
                            color: cs.primary,
                            weight: FontWeight.w800)),
                  ),
                ]),
              ),
            ),
          Row(mainAxisSize: MainAxisSize.min, children: [
            ShowFavoriteButton(showId: show.id),
            ShowShareButton(show: show),
          ]),
        ]),

        // 1) HİKÂYE
        gap(72),
        KeyedSubtree(
          key: sectionKeys[0],
          child: _Section(
            title: 'Hikâye',
            subtitle: 'perde açılmadan önce',
            child: _Story(
                text: desc.isEmpty
                    ? 'Bu oyun için henüz bir açıklama eklenmemiş.'
                    : desc),
          ),
        ),

        // 2) KADRO
        if (cast.isNotEmpty) ...[
          gap(72),
          KeyedSubtree(
            key: sectionKeys[1],
            child: _Section(
              title: 'Kadro',
              subtitle: '${cast.length} oyuncu, dokun ve tanı',
              child: _CastRow(players: cast, current: data.cast),
            ),
          ),
        ] else
          KeyedSubtree(key: sectionKeys[1], child: const SizedBox.shrink()),

        // 3) SEANSLAR VE MEKÂN
        gap(72),
        KeyedSubtree(
          key: sectionKeys[2],
          child: _Section(
            title: 'Seanslar ve mekân',
            subtitle: data.sessions.isEmpty
                ? (data.hasEnded ? 'perde indi' : 'tarihler yakında')
                : '${data.sessions.length} seans',
            child: _Sessions(
                data: data, chosen: chosen, onSession: onSession),
          ),
        ),

        // 4) GALERİ
        if (photos.length > 1) ...[
          gap(72),
          KeyedSubtree(
            key: sectionKeys[3],
            child: _Section(
              title: 'Galeri',
              subtitle: 'sahneden kareler',
              child: _Gallery(photos: photos),
            ),
          ),
        ] else
          KeyedSubtree(key: sectionKeys[3], child: const SizedBox.shrink()),

        // 5) YORUMLAR
        gap(72),
        KeyedSubtree(
          key: sectionKeys[4],
          child: _Section(
            title: 'Yorumlar',
            subtitle: 'izleyenler ne dedi',
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: ReviewsSection(showId: show.id, showName: show.name),
            ),
          ),
        ),

        gap(72),
        _SimilarRail(show: show),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const _Section({required this.title, this.subtitle, required this.child});

  @override
  Widget build(final BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkSectionHead(title: title, subtitle: subtitle),
          const SizedBox(height: 26),
          child,
        ],
      );
}

class _Crumbs extends StatelessWidget {
  final Show show;
  const _Crumbs({required this.show});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    TextStyle s(final bool link) => Sk.ui(context,
        size: 13,
        color: link ? cs.primary : cs.onSurfaceVariant,
        weight: FontWeight.w700);
    Widget link(final String t, final VoidCallback tap) => MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(onTap: tap, child: Text(t, style: s(true))),
        );
    final Widget sep = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(Icons.chevron_right_rounded,
          size: 16, color: cs.onSurfaceVariant),
    );
    return Row(children: [
      link('Ana Sayfa', () => NavigationHandler.goToHome(context)),
      sep,
      link('Keşfet', () => NavigationHandler.goToDiscover(context)),
      if (show.category.trim().isNotEmpty) ...[
        sep,
        link(show.category.trim(),
            () => NavigationHandler.goToDiscoverWithCategory(
                context, show.category)),
      ],
    ]);
  }
}

/// Oyun adı: kelime kelime aşağıdan açılır (giriş animasyonuna bağlı).
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
        spacing: 16,
        runSpacing: 0,
        children: [
          for (int i = 0; i < words.length; i++)
            () {
              final double start = (0.15 + i * 0.09).clamp(0.0, 0.7);
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
                        style: Sk.display(context, size: 68, height: 1.04)),
                  ),
                ),
              );
            }(),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Fact(this.icon, this.label, this.value);

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 22, color: cs.primary),
      const SizedBox(width: 9),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: Sk.ui(context,
                size: 11.5, color: cs.onSurfaceVariant, weight: FontWeight.w700)),
        Text(value, style: Sk.ui(context, size: 15, weight: FontWeight.w800)),
      ]),
    ]);
  }
}

/// Hikâye: büyük baş harf + okuma sütunu.
class _Story extends StatefulWidget {
  final String text;
  const _Story({required this.text});

  @override
  State<_Story> createState() => _StoryState();
}

class _StoryState extends State<_Story> {
  bool _open = false;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String t = widget.text.trim();
    final bool letter = t.isNotEmpty && RegExp(r'^[A-Za-zÇĞİÖŞÜçğıöşü]').hasMatch(t);
    final String first = letter ? t.substring(0, 1) : '';
    final String rest = letter ? t.substring(1) : t;
    final bool long = t.length > 520;
    final TextStyle body = Sk.ui(context,
        size: 17,
        weight: FontWeight.w500,
        height: 1.8,
        color: cs.onSurface.withValues(alpha: 0.9));
    final Widget text = SelectableText(
      rest,
      maxLines: _open || !long ? null : 9,
      style: body,
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 780),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
      ]),
    );
  }
}

class _CastRow extends StatelessWidget {
  final List<Player> players;
  final List<Player> current;
  const _CastRow({required this.players, required this.current});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: players.length,
        separatorBuilder: (_, __) => const SizedBox(width: 30),
        itemBuilder: (final context, final i) {
          final Player p = players[i];
          final bool now = current.any((final c) => c.id == p.id);
          final String name = '${p.firstName} ${p.lastName}'.trim();
          return SizedBox(
            width: 160,
            child: Center(
              child: SkFlowerPortrait(
                imageUrl: p.imageUrl,
                size: 142,
                semanticLabel: name,
                bottomChip: now ? 'Kadroda' : 'Önceki kadro',
                bottomChipAccent: now,
                onTap: () => NavigationHandler.goToPlayer(context, p.id, name,
                    imageUrl: p.imageUrl, title: name),
                title: Text(name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: Sk.ui(context,
                        size: 15,
                        weight: FontWeight.w800,
                        height: 1.2,
                        color: cs.onSurface)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Sessions extends StatelessWidget {
  final ShowDetailData data;
  final ShowSession? chosen;
  final ValueChanged<ShowSession> onSession;
  const _Sessions(
      {required this.data, required this.chosen, required this.onSession});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    if (data.sessions.isEmpty) {
      return Text(
          data.hasEnded
              ? 'Bu oyunun bütün seansları geçti. Yeni tarihler açılınca burada görünür.'
              : 'Henüz seans eklenmemiş. Favoriye ekleyip haber bekleyebilirsin.',
          style: Sk.ui(context,
              size: 15.5, color: cs.onSurfaceVariant, weight: FontWeight.w500));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final ShowSession s in data.sessions)
          _SessionTile(
            session: s,
            selected: chosen?.event.id == s.event.id,
            external: data.isExternal,
            showName: data.show.name,
            duration: data.show.duration,
            onTap: () => onSession(s),
          ),
        if (data.venues.isNotEmpty) ...[
          const SizedBox(height: 40),
          Wrap(spacing: 22, runSpacing: 22, children: [
            for (final Stage v in data.venues) _VenueCard(stage: v),
          ]),
        ],
      ],
    );
  }
}

class _SessionTile extends StatefulWidget {
  final ShowSession session;
  final bool selected;
  final bool external;
  final String showName;
  final String duration;
  final VoidCallback onTap;
  const _SessionTile({
    required this.session,
    required this.selected,
    required this.external,
    required this.showName,
    required this.duration,
    required this.onTap,
  });

  @override
  State<_SessionTile> createState() => _SessionTileState();
}

class _SessionTileState extends State<_SessionTile> {
  bool _hover = false;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ShowSession s = widget.session;
    final DateTime? w = s.when;
    final bool sel = widget.selected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
            decoration: BoxDecoration(
              color: sel
                  ? cs.primary.withValues(alpha: 0.12)
                  : (_hover ? cs.surfaceContainerHigh : cs.surfaceContainerLow),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: sel
                      ? cs.primary
                      : cs.outlineVariant.withValues(alpha: 0.5),
                  width: sel ? 1.8 : 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  SizedBox(
                    width: 74,
                    child: Column(children: [
                      Text(w == null ? '' : '${w.day}',
                          style: Sk.display(context,
                              size: 40, height: 1.0, color: cs.primary)),
                      Text(
                          w == null
                              ? s.shortLabel
                              : '${kMonthsTr[w.month - 1]}',
                          style: Sk.ui(context,
                              size: 13,
                              color: cs.onSurfaceVariant,
                              weight: FontWeight.w700)),
                    ]),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              w == null
                                  ? ''
                                  : '${kDaysTr[w.weekday - 1]} · ${skClock(w)}',
                              style: Sk.ui(context,
                                  size: 17, weight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          Text(s.venueName,
                              style: Sk.ui(context,
                                  size: 14.5,
                                  color: cs.onSurfaceVariant,
                                  weight: FontWeight.w600)),
                          if (w != null)
                            Text(sessionWhenPhrase(w),
                                style: Sketch.hand(context,
                                    size: 21, color: cs.primary)),
                        ]),
                  ),
                  if (s.priceLabel != null && !widget.external)
                    Text(s.priceLabel!,
                        style: Sk.display(context,
                            size: 26, height: 1.0, color: cs.onSurface)),
                  const SizedBox(width: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: Icon(
                        sel
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        key: ValueKey<bool>(sel),
                        color: sel ? cs.primary : cs.outline,
                        size: 28),
                  ),
                ]),
                SessionActions(
                    session: s,
                    showName: widget.showName,
                    duration: widget.duration),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VenueCard extends StatelessWidget {
  final Stage stage;
  const _VenueCard({required this.stage});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (final context, final box) => Container(
        width: box.maxWidth < 440 ? box.maxWidth : 440,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 100,
              height: 100,
              child: SkImage(
                  url: stage.imageUrl,
                  fallbackIcon: Icons.location_city_rounded),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stage.name,
                      style: Sk.display(context, size: 22, height: 1.1)),
                  if (stage.address.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(stage.address.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.ui(context,
                              size: 13,
                              color: cs.onSurfaceVariant,
                              weight: FontWeight.w500)),
                    ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () => openStageDirections(stage),
                    icon: const Icon(Icons.directions_rounded, size: 18),
                    label: const Text('Yol tarifi'),
                  ),
                ]),
          ),
        ]),
      ),
    );
  }
}

/// Galeri: farklı oranlı kareler (yüksek/alçak dönüşümlü), hover'da yakınlaşır.
class _Gallery extends StatelessWidget {
  final List<String> photos;
  const _Gallery({required this.photos});

  @override
  Widget build(final BuildContext context) {
    return LayoutBuilder(builder: (final context, final box) {
      final int cols = box.maxWidth >= 760 ? 3 : 2;
      const double gap = 16;
      final double cw = (box.maxWidth - gap * (cols - 1)) / cols;
      final List<List<int>> columns = List.generate(cols, (_) => []);
      for (int i = 0; i < photos.length && i < 9; i++) {
        columns[i % cols].add(i);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (int c = 0; c < cols; c++) ...[
          SizedBox(
            width: cw,
            child: Column(children: [
              for (final int i in columns[c])
                Padding(
                  padding: const EdgeInsets.only(bottom: gap),
                  child: _GalleryTile(
                    url: photos[i],
                    ratio: (i + c) % 3 == 0 ? 3 / 4 : 4 / 3,
                    onTap: () => GalleryViewerDialog.open(context, photos),
                  ),
                ),
            ]),
          ),
          if (c < cols - 1) const SizedBox(width: gap),
        ],
      ]);
    });
  }
}

class _GalleryTile extends StatefulWidget {
  final String url;
  final double ratio;
  final VoidCallback onTap;
  const _GalleryTile(
      {required this.url, required this.ratio, required this.onTap});

  @override
  State<_GalleryTile> createState() => _GalleryTileState();
}

class _GalleryTileState extends State<_GalleryTile> {
  bool _hover = false;

  @override
  Widget build(final BuildContext context) => MouseRegion(
        cursor: SystemMouseCursors.zoomIn,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: widget.ratio,
              child: AnimatedScale(
                scale: _hover ? 1.06 : 1,
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                child: SkImage(url: widget.url),
              ),
            ),
          ),
        ),
      );
}

class _SimilarRail extends ConsumerWidget {
  final Show show;
  const _SimilarRail({required this.show});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String cat = show.category.trim().toLowerCase();
    final List<Show> list = [
      for (final Show x
          in ref.watch(showsActiveFirstProvider(false)).value ?? const <Show>[])
        if (x.id != show.id &&
            cat.isNotEmpty &&
            x.category.trim().toLowerCase() == cat)
          x,
    ].take(8).toList();
    if (list.isEmpty) return const SizedBox.shrink();
    return _Section(
      title: 'Benzer oyunlar',
      subtitle: 'bunları da sevebilirsin',
      child: SizedBox(
        height: 400,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: list.length,
          separatorBuilder: (_, __) => const SizedBox(width: 24),
          itemBuilder: (final context, final i) => MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => NavigationHandler.goToShow(
                  context, list[i].id, list[i].name,
                  imageUrl: list[i].imageUrl, title: list[i].name),
              child: SizedBox(
                width: 220,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          boxShadow: skSoftShadow(context, strength: 0.8),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: AspectRatio(
                            aspectRatio: 2 / 3,
                            child: SkImage(
                                url: list[i].imageUrl,
                                alignment: Alignment.topCenter),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(list[i].name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.ui(context,
                              size: 15.5,
                              weight: FontWeight.w800,
                              height: 1.25,
                              color: cs.onSurface)),
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
