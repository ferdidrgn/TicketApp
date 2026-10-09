import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/services/deeplink/deeplink_service.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../../../shared/widgets/ticket/ticket_profile.dart'
    show ProfileErrorView, splitShowsByLiveActivity;
import '../../../../../shared/widgets/tiyatrol_hero.dart';
import '../../../../search/presentation/providers/search_query_provider.dart';
import '../../../../shows/domain/entities/show.dart';
import '../../../../shows/presentation/providers/show_provider.dart';
import '../../../../shows/presentation/widgets/detail/show_detail_actions.dart';
import '../../../domain/entities/player.dart';
import '../../providers/player_provider.dart';

/// OYUNCU SAYFASI — "Sahne". Telefon, tablet ve web için tek duyarlı yüzey.
///
/// Portre + ad + replik, canlı sayaçlar (gerçek oyun/ödül sayısı), sahnedeki
/// oyunlar, biyografi, ödül zaman çizgisi, birlikte çalıştıkları (dokununca
/// aramaya gider), geçmiş oyunlar. Birincil aksiyon: oyuna git.
class PlayerExperience extends ConsumerStatefulWidget {
  final String playerId;
  final Widget? footer;

  const PlayerExperience({super.key, required this.playerId, this.footer});

  @override
  ConsumerState<PlayerExperience> createState() => _PlayerExperienceState();
}

class _PlayerExperienceState extends ConsumerState<PlayerExperience> {
  final ScrollController _scroll = ScrollController();
  final ValueNotifier<double> _offset = ValueNotifier(0);
  final GlobalKey _onStageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients) _offset.value = _scroll.offset;
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _offset.dispose();
    super.dispose();
  }

  void _openShow(final Show s) => NavigationHandler.goToShow(context, s.id, s.name,
      heroTag: TiyatrolHeroTags.show(s.id, 'player'),
      imageUrl: s.imageUrl,
      title: s.name);

  void _searchFor(final String name) {
    HapticFeedback.selectionClick();
    ref.read(searchQueryProvider.notifier).update(name);
    ref.read(searchFilterProvider.notifier).setFilter(0);
    NavigationHandler.goToSearch(context);
  }

  @override
  Widget build(final BuildContext context) {
    final async = ref.watch(playerDetailProvider(widget.playerId));
    final String previewName = TiyatrolHeroFlight.field(context, 'title') ?? '';
    final String previewImage =
        TiyatrolHeroFlight.field(context, 'imageUrl') ?? '';

    return async.when(
      loading: () => _scaffold(
        context,
        name: previewName,
        imageUrl: previewImage,
        ready: false,
      ),
      error: (final e, _) => ProfileErrorView(
        error: e,
        notFoundTitle: 'Bu oyuncu bulunamadı',
        failedTitle: 'Oyuncu bilgileri yüklenemedi',
        onRetry: () => ref.invalidate(playerDetailProvider(widget.playerId)),
      ),
      data: (final state) {
        final split = splitShowsByLiveActivity(
          claimedActive: state.activeShows,
          past: state.pastShows,
          liveActive: ref.watch(activeShowsProvider(false)).value,
        );
        return _scaffold(
          context,
          player: state.player,
          name: '${state.player.firstName} ${state.player.lastName}'.trim(),
          imageUrl: state.player.imageUrl,
          active: split.active,
          past: split.past,
          ready: true,
        );
      },
    );
  }

  Widget _scaffold(
    final BuildContext context, {
    final Player? player,
    required final String name,
    required final String imageUrl,
    final List<Show> active = const [],
    final List<Show> past = const [],
    required final bool ready,
  }) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final EdgeInsets safe = MediaQuery.paddingOf(context);

    return LayoutBuilder(builder: (final context, final box) {
      final double w = box.maxWidth;
      final bool wide = w >= 980;
      final double gutter = Sk.gutter(w);

      final Widget identity = _Identity(
        playerId: widget.playerId,
        name: name,
        imageUrl: imageUrl,
        quote: player?.quote.trim() ?? '',
        onStage: active.isNotEmpty,
        ready: ready,
        left: wide,
        offset: _offset,
      );

      final Widget stats = ready
          ? Padding(
              padding: const EdgeInsets.only(top: 24),
              child: _Stats(
                items: [
                  ('Sahnede', active.length),
                  ('Geçmiş oyun', past.length),
                  (
                    'Ödül',
                    player!.achievements
                        .where((final a) => (a['title'] ?? '').trim().isNotEmpty)
                        .length
                  ),
                ],
              ),
            )
          : const SizedBox.shrink();

      final Widget body = ready
          ? _Body(
              player: player!,
              active: active,
              past: past,
              onStageKey: _onStageKey,
              onShow: _openShow,
              onCollab: _searchFor,
            )
          : const Padding(
              padding: EdgeInsets.only(top: 32),
              child: Column(children: [
                SkBone(height: 18, radius: 8),
                SizedBox(height: 10),
                SkBone(height: 18, radius: 8),
                SizedBox(height: 28),
                SkBone(height: 110, radius: 22),
              ]),
            );

      final String? cta = active.isEmpty
          ? null
          : (active.length == 1 ? 'Oyuna git' : 'Oyunlarını gör');
      void onCta() {
        HapticFeedback.mediumImpact();
        if (active.length == 1) {
          _openShow(active.first);
        } else {
          final BuildContext? c = _onStageKey.currentContext;
          if (c != null) {
            Scrollable.ensureVisible(c,
                duration: const Duration(milliseconds: 550),
                curve: Curves.easeInOutCubic,
                alignment: 0.05);
          }
        }
      }

      final Widget topBar = _TopBar(
        name: name,
        offset: _offset,
        gutter: wide ? gutter : 12,
        onShare: player == null
            ? null
            : () => TiyatrolDeeplinkService.shareActor(
                id: player.id, name: name),
      );

      if (wide) {
        return Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: AmbientBackdrop(url: imageUrl, height: 620),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: Sk.maxWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 360,
                        child: Padding(
                          padding: EdgeInsets.only(top: safe.top + 80),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              identity,
                              stats,
                              if (cta != null) ...[
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: onCta,
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(0, 54),
                                      shape: const StadiumBorder(),
                                    ),
                                    child: Text(cta,
                                        style: Sk.ui(context,
                                            size: 15,
                                            color: cs.onPrimary,
                                            weight: FontWeight.w800)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 56),
                      Expanded(
                        child: ScrollConfiguration(
                          behavior: const SkScrollBehavior(),
                          child: CustomScrollView(
                            controller: _scroll,
                            slivers: [
                              SliverToBoxAdapter(
                                  child: SizedBox(height: safe.top + 80)),
                              SliverToBoxAdapter(child: body),
                              SliverToBoxAdapter(
                                  child: widget.footer ??
                                      const SizedBox(height: 80)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            topBar,
          ],
        );
      }

      return Stack(
        children: [
          ScrollConfiguration(
            behavior: const SkScrollBehavior(),
            child: CustomScrollView(
              controller: _scroll,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: _PlayerHero(
                    playerId: widget.playerId,
                    name: name,
                    imageUrl: imageUrl,
                    quote: player?.quote.trim() ?? '',
                    onStage: active.isNotEmpty,
                    ready: ready,
                    offset: _offset,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -30),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(34)),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: Padding(
                            padding:
                                EdgeInsets.fromLTRB(gutter, 4, gutter, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                stats,
                                body,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: widget.footer ??
                      SizedBox(height: 130 + safe.bottom),
                ),
              ],
            ),
          ),
          topBar,
          if (cta != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: safe.bottom + 14,
              child: FilledButton(
                onPressed: onCta,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 54),
                  shape: const StadiumBorder(),
                  elevation: 6,
                ),
                child: Text(cta,
                    style: Sk.ui(context,
                        size: 15,
                        color: cs.onPrimary,
                        weight: FontWeight.w800)),
              ),
            ),
        ],
      );
    });
  }
}

// ═════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final String name;
  final ValueNotifier<double> offset;
  final double gutter;
  final VoidCallback? onShare;

  const _TopBar({
    required this.name,
    required this.offset,
    required this.gutter,
    required this.onShare,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double top = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ValueListenableBuilder<double>(
        valueListenable: offset,
        builder: (final context, final o, _) {
          final double t = (o / 260).clamp(0.0, 1.0);
          return Container(
            padding: EdgeInsets.fromLTRB(gutter, top + 6, gutter, 6),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.92 * t),
              border: Border(
                  bottom: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.5 * t))),
            ),
            child: Row(
              children: [
                const ShowBackButton(onImage: true),
                const SizedBox(width: 8),
                Expanded(
                  child: Opacity(
                    opacity: t,
                    child: Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Sk.display(context, size: 18)),
                  ),
                ),
                if (onShare != null)
                  ShowQuietIconButton(
                    icon: Icons.ios_share_rounded,
                    label: 'Oyuncu profilini paylaş',
                    onImage: true,
                    onPressed: onShare,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  final String playerId;
  final String name;
  final String imageUrl;
  final String quote;
  final bool onStage;
  final bool ready;
  final bool left;
  final ValueNotifier<double> offset;

  const _Identity({
    required this.playerId,
    required this.name,
    required this.imageUrl,
    required this.quote,
    required this.onStage,
    required this.ready,
    required this.left,
    required this.offset,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final CrossAxisAlignment align =
        left ? CrossAxisAlignment.start : CrossAxisAlignment.center;
    final double pw = left ? 220 : 200;

    final Widget portrait = TiyatrolHero(
      tag: resolveTiyatrolHeroTag(context, TiyatrolHeroTags.player(playerId)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(pw / 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.32),
              blurRadius: 34,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: SkImage(
          url: imageUrl,
          width: pw,
          height: pw * 1.42,
          radius: pw / 2,
          fallbackIcon: Icons.person_rounded,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: align,
      children: [
        left
            ? portrait
            : ValueListenableBuilder<double>(
                valueListenable: offset,
                builder: (final context, final o, child) => Opacity(
                  opacity: 1 - 0.85 * (o / 300).clamp(0.0, 1.0),
                  child: child,
                ),
                child: portrait,
              ),
        const SizedBox(height: 22),
        if (ready)
          _StatusPill(onStage: onStage),
        const SizedBox(height: 12),
        Text(
          name,
          textAlign: left ? TextAlign.start : TextAlign.center,
          style: Sk.display(context, size: left ? 38 : 32, height: 1.05),
        ),
        if (quote.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('“',
                  style: Sk.display(context,
                      size: 44, color: cs.primary, height: 0.9)),
              const SizedBox(width: 6),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    quote,
                    textAlign: left ? TextAlign.start : TextAlign.center,
                    style: Sk.display(context,
                        size: 16,
                        weight: FontWeight.w500,
                        color: cs.onSurface.withValues(alpha: 0.85),
                        height: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _StatusPill extends StatefulWidget {
  final bool onStage;
  const _StatusPill({required this.onStage});

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool reduce = Sk.reduceMotion(context);
    final Color dot = widget.onStage ? cs.primary : cs.outline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (final context, _) => Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dot,
                boxShadow: widget.onStage && !reduce
                    ? [
                        BoxShadow(
                          color: dot.withValues(alpha: 0.55 * (1 - _c.value)),
                          blurRadius: 10 * _c.value + 2,
                          spreadRadius: 4 * _c.value,
                        ),
                      ]
                    : const [],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(widget.onStage ? 'Şu an sahnede' : 'Sahneye ara verdi',
              style: Sk.ui(context, size: 12.5, weight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  final List<(String, int)> items;
  const _Stats({required this.items});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                        begin: 0, end: items[i].$2.toDouble()),
                    duration: Sk.reduceMotion(context)
                        ? Duration.zero
                        : Duration(milliseconds: 700 + i * 150),
                    curve: Curves.easeOutCubic,
                    builder: (final context, final v, _) => Text(
                      '${v.round()}',
                      style: Sk.display(context,
                          size: 28,
                          height: 1.0,
                          color: i == 0 ? cs.primary : cs.onSurface),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(items[i].$1,
                      style: Sk.ui(context,
                          size: 12,
                          color: cs.onSurfaceVariant,
                          weight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Body extends StatefulWidget {
  final Player player;
  final List<Show> active;
  final List<Show> past;
  final GlobalKey onStageKey;
  final ValueChanged<Show> onShow;
  final ValueChanged<String> onCollab;

  const _Body({
    required this.player,
    required this.active,
    required this.past,
    required this.onStageKey,
    required this.onShow,
    required this.onCollab,
  });

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  bool _bioOpen = false;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Player p = widget.player;
    final String bio = p.bio.replaceAll('\\n', '\n').trim();
    final List<Map<String, String>> awards = [
      for (final a in p.achievements)
        if ((a['title'] ?? '').trim().isNotEmpty) a,
    ]..sort((final a, final b) => (b['year'] ?? '').compareTo(a['year'] ?? ''));
    final List<String> collabs = [
      for (final c in p.collaborations)
        if (c.trim().isNotEmpty) c.trim(),
    ];

    Widget section(final int i, final Widget child) => Reveal(
        index: i,
        child: Padding(padding: const EdgeInsets.only(top: 34), child: child));

    final bool longBio = bio.length > 260;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.active.isNotEmpty)
          section(
            0,
            KeyedSubtree(
              key: widget.onStageKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkSectionHead(title: 'Sahnede'),
                  const SizedBox(height: 14),
                  for (final Show s in widget.active) _ShowRow(show: s, onTap: widget.onShow, live: true),
                ],
              ),
            ),
          ),
        if (bio.isNotEmpty)
          section(
            1,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkSectionHead(title: 'Hakkında'),
                const SizedBox(height: 12),
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: Text(
                    bio,
                    maxLines: _bioOpen || !longBio ? null : 6,
                    overflow: _bioOpen || !longBio
                        ? TextOverflow.visible
                        : TextOverflow.fade,
                    style: Sk.ui(context,
                        size: 15,
                        color: cs.onSurface.withValues(alpha: 0.86),
                        weight: FontWeight.w500,
                        height: 1.65),
                  ),
                ),
                if (longBio)
                  PressScale(
                    onTap: () => setState(() => _bioOpen = !_bioOpen),
                    semanticLabel: _bioOpen ? 'Daha az göster' : 'Devamını oku',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(_bioOpen ? 'Daha az göster' : 'Devamını oku',
                          style: Sk.ui(context,
                              size: 14,
                              color: cs.primary,
                              weight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
          ),
        if (awards.isNotEmpty)
          section(
            2,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkSectionHead(title: 'Ödüller', subtitle: '${awards.length} ödül'),
                const SizedBox(height: 16),
                for (int i = 0; i < awards.length; i++)
                  _AwardTile(
                    year: (awards[i]['year'] ?? '').trim(),
                    title: (awards[i]['title'] ?? '').trim(),
                    detail: (awards[i]['detail'] ?? '').trim(),
                    last: i == awards.length - 1,
                  ),
              ],
            ),
          ),
        if (collabs.isNotEmpty)
          section(
            3,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkSectionHead(
                    title: 'Birlikte çalıştıkları',
                    subtitle: 'Dokun, onların oyunlarını ara'),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final String c in collabs)
                      ActionChip(
                        label: Text(c),
                        avatar: const Icon(Icons.search_rounded, size: 18),
                        onPressed: () => widget.onCollab(c),
                      ),
                  ],
                ),
              ],
            ),
          ),
        if (widget.past.isNotEmpty)
          section(
            4,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkSectionHead(
                    title: 'Geçmiş oyunlar',
                    subtitle: '${widget.past.length} oyun'),
                const SizedBox(height: 14),
                SizedBox(
                  height: 250,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: widget.past.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (final context, final i) {
                      final Show s = widget.past[i];
                      return SizedBox(
                        width: 130,
                        child: PressScale(
                          onTap: () => widget.onShow(s),
                          semanticLabel: s.name,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TiyatrolHero(
                                tag: TiyatrolHeroTags.show(s.id, 'player'),
                                child: SkImage(
                                    url: s.imageUrl,
                                    width: 130,
                                    height: 188,
                                    radius: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(s.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Sk.ui(context,
                                      size: 13,
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
            ),
          ),
      ],
    );
  }
}

class _ShowRow extends StatelessWidget {
  final Show show;
  final ValueChanged<Show> onTap;
  final bool live;

  const _ShowRow({required this.show, required this.onTap, this.live = false});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressScale(
        onTap: () => onTap(show),
        semanticLabel: show.name,
        scale: 0.985,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(22),
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              TiyatrolHero(
                tag: TiyatrolHeroTags.show(show.id, 'player'),
                child: SkImage(
                    url: show.imageUrl, width: 64, height: 92, radius: 14),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(show.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Sk.ui(context,
                            size: 15, weight: FontWeight.w800, height: 1.2)),
                    if (show.category.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(show.category.trim(),
                            style: Sk.ui(context,
                                size: 12.5,
                                color: cs.onSurfaceVariant,
                                weight: FontWeight.w500)),
                      ),
                    if (live)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: SkBadge(label: 'Bilet var', accent: true),
                      ),
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

class _AwardTile extends StatelessWidget {
  final String year;
  final String title;
  final String detail;
  final bool last;

  const _AwardTile({
    required this.year,
    required this.title,
    required this.detail,
    required this.last,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(year.isEmpty ? '—' : year,
                  style: Sk.display(context,
                      size: 17, color: cs.primary, height: 1.1)),
            ),
          ),
          Column(
            children: [
              Container(
                width: 11,
                height: 11,
                margin: const EdgeInsets.only(top: 5),
                decoration:
                    BoxDecoration(color: cs.primary, shape: BoxShape.circle),
              ),
              if (!last)
                Expanded(
                  child: Container(
                      width: 2,
                      color: cs.outlineVariant.withValues(alpha: 0.6)),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Sk.ui(context,
                          size: 15, weight: FontWeight.w800, height: 1.25)),
                  if (detail.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(detail,
                          style: Sk.ui(context,
                              size: 13,
                              color: cs.onSurfaceVariant,
                              weight: FontWeight.w500,
                              height: 1.4)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/// Kenardan kenara portre kahramanı: ad, durum ve replik fotoğrafın üstünde.
class _PlayerHero extends StatelessWidget {
  final String playerId;
  final String name;
  final String imageUrl;
  final String quote;
  final bool onStage;
  final bool ready;
  final ValueNotifier<double> offset;

  const _PlayerHero({
    required this.playerId,
    required this.name,
    required this.imageUrl,
    required this.quote,
    required this.onStage,
    required this.ready,
    required this.offset,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double h =
        (MediaQuery.sizeOf(context).height * 0.68).clamp(480.0, 640.0);
    return SizedBox(
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ValueListenableBuilder<double>(
            valueListenable: offset,
            builder: (final context, final o, child) => ClipRect(
              child: Transform.translate(
                offset: Offset(0, o.clamp(0, h) * 0.45),
                child: child,
              ),
            ),
            child: TiyatrolHero(
              tag: resolveTiyatrolHeroTag(
                  context, TiyatrolHeroTags.player(playerId)),
              child: SkImage(
                url: imageUrl,
                fallbackIcon: Icons.person_rounded,
              ),
            ),
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.9),
                    cs.surface,
                  ],
                  stops: const [0.0, 0.2, 0.5, 0.86, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            left: 22,
            right: 22,
            bottom: 56,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ready)
                  SkGlass(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: onStage ? cs.primary : Colors.white54,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(onStage ? 'Şu an sahnede' : 'Sahneye ara verdi',
                          style: Sk.ui(context,
                              size: 12.5,
                              color: Colors.white,
                              weight: FontWeight.w800)),
                    ]),
                  ),
                const SizedBox(height: 14),
                Text(
                  name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Sk.display(context,
                          size: 42, color: Colors.white, height: 1.02)
                      .copyWith(shadows: [
                    Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 18,
                        offset: const Offset(0, 4)),
                  ]),
                ),
                if (quote.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '“$quote”',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Sk.display(context,
                        size: 17,
                        weight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.35),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
