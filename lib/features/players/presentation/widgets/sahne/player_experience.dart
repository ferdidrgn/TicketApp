import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/services/deeplink/deeplink_service.dart';
import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/gallery_section.dart';
import '../../../../../shared/widgets/listing.dart';
import '../../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../../../shared/widgets/sahne/sketch.dart';
import '../../../../../shared/widgets/rive/tiyatrol_rive.dart';
import '../../../../../shared/widgets/ticket/ticket_profile.dart'
    show ProfileErrorView, splitShowsByLiveActivity;
import '../../../../../shared/widgets/tiyatrol_hero.dart';
import '../../../../search/presentation/providers/search_query_provider.dart';
import '../../../../shows/domain/entities/show.dart';
import '../../../../shows/domain/next_session.dart';
import '../../../../shows/presentation/providers/show_provider.dart';
import '../../../../shows/presentation/widgets/detail/show_detail_actions.dart';
import '../../../domain/entities/player.dart';
import 'player_costars.dart';
import 'player_live_stage.dart';
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
  final GlobalKey _awardsKey = GlobalKey();
  final GlobalKey _pastKey = GlobalKey();

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

  void _scrollToKey(final GlobalKey key) {
    final BuildContext? c = key.currentContext;
    if (c == null) return;
    HapticFeedback.selectionClick();
    Scrollable.ensureVisible(c,
        duration: Sk.reduceMotion(context) ? Duration.zero : AppMotion.slow,
        curve: AppMotion.emphasized,
        alignment: 0.05);
  }

  void _openShow(final Show s) {
    HapticFeedback.selectionClick();
    NavigationHandler.goToShow(context, s.id, s.name,
        heroTag: TiyatrolHeroTags.show(s.id, 'player'),
        imageUrl: s.imageUrl,
        title: s.name);
  }

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
      final Map<String, NextSessionHint> nextByShow = {};
      NextSessionHint? soonest;
      final eventsByShow = ref.watch(eventsByShowMapProvider(false)).value;
      if (eventsByShow != null) {
        for (final Show show in active) {
          final NextSessionHint? hint = nextSessionHint(eventsByShow[show.id]);
          if (hint == null) continue;
          nextByShow[show.id] = hint;
          if (soonest == null || hint.when.isBefore(soonest.when)) {
            soonest = hint;
          }
        }
      }

      final int awardCount = player == null
          ? 0
          : player.achievements
              .where((final a) => (a['title'] ?? '').trim().isNotEmpty)
              .length;
      // Sayılar (sahnede/geçmiş/ödül) zaten "Sahne künyesi"nde — çiplerde
      // tekrar edilmez; burada künyede olmayan bilgi var.
      final int collabCount = player == null
          ? 0
          : player.collaborations.where((final c) => c.trim().isNotEmpty).length;
      final List<LiveChip> liveChips = [
        if (active.length + past.length > 0)
          LiveChip(Icons.theater_comedy_rounded,
              '${active.length + past.length} oyunda'),
        if (collabCount > 0)
          LiveChip(Icons.groups_rounded, '$collabCount toplulukla'),
      ];

      final Widget identity = _Identity(
        playerId: widget.playerId,
        name: name,
        imageUrl: imageUrl,
        quote: '',
        onStage: active.isNotEmpty,
        next: soonest,
        ready: ready,
        left: wide,
        offset: _offset,
        chips: liveChips,
      );

      final Widget stats = ready
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxl + 4),
              child: _Stats(
                onStage: active.length,
                past: past.length,
                awards: awardCount,
                onStageTap:
                    active.isEmpty ? null : () => _scrollToKey(_onStageKey),
                onPastTap: past.isEmpty ? null : () => _scrollToKey(_pastKey),
                onAwardsTap:
                    awardCount == 0 ? null : () => _scrollToKey(_awardsKey),
              ),
            )
          : const SizedBox.shrink();

      final Widget body = ready
          ? _Body(
              player: player!,
              active: active,
              past: past,
              onStageKey: _onStageKey,
              awardsKey: _awardsKey,
              pastKey: _pastKey,
              onShow: _openShow,
              onCollab: _searchFor,
              nextByShow: nextByShow,
            )
          : const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xxxl),
              child: Column(children: [
                TiyatrolRiveLoader(size: 52, caption: 'Perde açılıyor…'),
                SizedBox(height: AppSpacing.lg),
                SkBone(height: 18, radius: AppRadius.xs),
                SizedBox(height: AppSpacing.sm + 2),
                SkBone(height: 18, radius: AppRadius.xs),
                SizedBox(height: AppSpacing.xxl + 4),
                SkBone(height: 110, radius: AppRadius.lg),
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
          _scrollToKey(_onStageKey);
        }
      }

      final Widget topBar = _TopBar(
        name: name,
        offset: _offset,
        gutter: wide ? gutter : AppSpacing.md,
        onShare: player == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                TiyatrolDeeplinkService.shareActor(
                    id: player.id, name: name);
              },
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
                                const SizedBox(height: AppSpacing.xxl),
                                ListingCta(label: cta, onPressed: onCta),
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
                    quote: '',
                    onStage: active.isNotEmpty,
                    next: soonest,
                    ready: ready,
                    offset: _offset,
                    chips: liveChips,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Transform.translate(
                    offset: const Offset(0, -30),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppRadius.xl)),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 640),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                                gutter, AppSpacing.xxl + 4, gutter, 0),
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
              left: AppSpacing.xl,
              right: AppSpacing.xl,
              bottom: safe.bottom + AppSpacing.md,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  boxShadow: AppShadows.level4(cs.shadow),
                ),
                child: ListingCta(label: cta, onPressed: onCta),
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
  final NextSessionHint? next;
  final bool ready;
  final bool left;
  final ValueNotifier<double> offset;
  final List<LiveChip> chips;

  const _Identity({
    required this.playerId,
    required this.name,
    required this.imageUrl,
    required this.quote,
    required this.onStage,
    required this.ready,
    required this.left,
    required this.offset,
    this.next,
    this.chips = const [],
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final CrossAxisAlignment align =
        left ? CrossAxisAlignment.start : CrossAxisAlignment.center;

    // Canlı portre sahnesi: yapraklı portre + kalem halkaları + süzülen çipler.
    final Widget portrait = LivePortraitStage(
      imageUrl: imageUrl,
      size: left ? 240 : 210,
      chips: chips,
      onTap: imageUrl.trim().startsWith('http')
          ? () => GalleryViewerDialog.open(context, [imageUrl.trim()])
          : null,
      heroWrap: (final child) => TiyatrolHero(
        tag: resolveTiyatrolHeroTag(context, TiyatrolHeroTags.player(playerId)),
        child: child,
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
          _StatusPill(onStage: onStage, next: next),
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
  final NextSessionHint? next;
  const _StatusPill({required this.onStage, this.next});

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: AppMotion.slow * 2)
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
    final String label = widget.next == null
        ? (widget.onStage ? 'Şu an sahnede' : 'Sahneye ara verdi')
        : 'Sıradaki ${skDayPhrase(widget.next!.when)} · ${skClock(widget.next!.when)}';
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm - 1),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppRadius.md + 4),
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
                            color:
                                dot.withValues(alpha: 0.55 * (1 - _c.value)),
                            blurRadius: 10 * _c.value + 2,
                            spreadRadius: 4 * _c.value,
                          ),
                        ]
                      : AppShadows.level0,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(label,
                style: Sk.ui(context, size: 12.5, weight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

/// Künye metrikleri — sıkışık kutu değil; dokununca ilgili bölüme kayar.
class _Body extends StatefulWidget {
  final Player player;
  final List<Show> active;
  final List<Show> past;
  final GlobalKey onStageKey;
  final GlobalKey awardsKey;
  final GlobalKey pastKey;
  final ValueChanged<Show> onShow;
  final ValueChanged<String> onCollab;
  final Map<String, NextSessionHint> nextByShow;

  const _Body({
    required this.player,
    required this.active,
    required this.past,
    required this.onStageKey,
    required this.awardsKey,
    required this.pastKey,
    required this.onShow,
    required this.onCollab,
    this.nextByShow = const {},
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
        child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.huge - 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                child,
              ],
            )));

    final bool longBio = bio.length > 260;
    final bool hasAny = widget.active.isNotEmpty ||
        bio.isNotEmpty ||
        awards.isNotEmpty ||
        collabs.isNotEmpty ||
        widget.past.isNotEmpty;

    if (!hasAny) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xxl),
        child: SkSoftCard(
          radius: AppRadius.lg,
          color: cs.surfaceContainerHigh,
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Künye henüz dolu değil',
                  style: Sk.ui(context, size: 15, weight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Bu oyuncunun sahnedeki oyunları, biyografisi ve ödülleri eklendiğinde burada görünecek.',
                style: Sk.ui(context,
                    size: 13.5,
                    color: cs.onSurfaceVariant,
                    weight: FontWeight.w500,
                    height: 1.45),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (p.quote.trim().isNotEmpty)
          section(
              0, _QuoteNote(quote: p.quote.trim(), name: p.firstName.trim())),
        if (bio.isNotEmpty)
          section(
            1,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkSectionHead(
                    title: 'Hakkında', subtitle: 'defterden kısa bir not'),
                const SizedBox(height: AppSpacing.md),
                AnimatedSize(
                  duration: AppMotion.fast,
                  curve: AppMotion.standard,
                  alignment: Alignment.topCenter,
                  child: _DropCap(
                      text: bio,
                      maxLines: _bioOpen || !longBio ? null : 6),
                ),
                if (longBio)
                  PressScale(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _bioOpen = !_bioOpen);
                    },
                    semanticLabel:
                        _bioOpen ? 'Daha az göster' : 'Devamını oku',
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      child: Text(_bioOpen ? 'daha az göster' : 'devamını oku',
                          style: Sketch.hand(context,
                              size: 20,
                              color: cs.primary,
                              weight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ),
        if (widget.active.isNotEmpty)
          section(
            2,
            KeyedSubtree(
              key: widget.onStageKey,
              child: _StageFan(
                shows: widget.active,
                onShow: widget.onShow,
              ),
            ),
          ),
        if (widget.active.isNotEmpty || widget.past.isNotEmpty)
          section(
            4,
            PlayerCoStars(
                player: p, shows: [...widget.active, ...widget.past]),
          ),
        if (awards.isNotEmpty)
          section(
            3,
            KeyedSubtree(
              key: widget.awardsKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkSectionHead(
                      title: 'Ödüller',
                      subtitle: '${awards.length} ödül${_yearSpan(awards)}'),
                  const SizedBox(height: AppSpacing.lg),
                  for (int i = 0; i < awards.length; i++)
                    Reveal(
                      index: i.clamp(0, 8),
                      child: _AwardTile(
                        year: (awards[i]['year'] ?? '').trim(),
                        title: (awards[i]['title'] ?? '').trim(),
                        detail: (awards[i]['detail'] ?? '').trim(),
                        last: i == awards.length - 1,
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (collabs.isNotEmpty)
          section(
            4,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkSectionHead(
                    title: 'Çalıştığı topluluklar',
                    subtitle: '${collabs.length} topluluk'),
                const SizedBox(height: AppSpacing.lg),
                _CollabList(
                  names: collabs,
                  onTap: widget.onCollab,
                ),
              ],
            ),
          ),
        if (widget.past.isNotEmpty)
          section(
            4,
            KeyedSubtree(
              key: widget.pastKey,
              child: SkRail<Show>(
                title: 'Geçmiş oyunlar',
                subtitle: '${widget.past.length} oyun',
                items: widget.past,
                gutter: 0,
                railW: 138,
                railH: 207,
                minCell: 138,
                builder: (final s, final w) {
                  final int i = widget.past.indexOf(s);
                  return Reveal(
                    index: i.clamp(0, 8),
                    child: PressScale(
                      onTap: () => widget.onShow(s),
                      semanticLabel: s.name,
                      child: Container(
                        width: w,
                        height: w * 1.5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          boxShadow: AppShadows.level2(cs.shadow),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              TiyatrolHero(
                                tag: TiyatrolHeroTags.show(s.id, 'player'),
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
                              Positioned(
                                left: AppSpacing.md,
                                right: AppSpacing.md,
                                bottom: AppSpacing.md,
                                child: Text(s.name,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: Sk.display(context,
                                        size: 15,
                                        color: Colors.white,
                                        height: 1.1)),
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
          ),
      ],
    );
  }
}

class _ShowRow extends StatelessWidget {
  final Show show;
  final ValueChanged<Show> onTap;
  final NextSessionHint? next;

  const _ShowRow({required this.show, required this.onTap, this.next});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: PressScale(
        onTap: () => onTap(show),
        semanticLabel: next == null
            ? show.name
            : '${show.name}, ${skDayPhrase(next!.when)} ${skClock(next!.when)}',
        scale: 0.985,
        child: SkSoftCard(
          radius: AppRadius.lg,
          color: cs.surfaceContainerLow,
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          child: Row(
            children: [
              TiyatrolHero(
                tag: TiyatrolHeroTags.show(show.id, 'player'),
                child: SkImage(
                    url: show.imageUrl,
                    width: 64,
                    height: 92,
                    radius: AppRadius.sm + 2),
              ),
              const SizedBox(width: AppSpacing.md),
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
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(show.category.trim(),
                            style: Sk.ui(context,
                                size: 12.5,
                                color: cs.onSurfaceVariant,
                                weight: FontWeight.w500)),
                      ),
                    if (next != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Text(
                          next!.price == null
                              ? '${skDayPhrase(next!.when)} · ${skClock(next!.when)}'
                              : '${skDayPhrase(next!.when)} · ${skClock(next!.when)} · ${skPrice(next!.price!)}',
                          style: Sk.ui(context,
                              size: 12.5,
                              color: cs.primary,
                              weight: FontWeight.w800),
                        ),
                      )
                    else if (show.hasExternalTicketing)
                      const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.sm),
                        child: SkBadge(label: 'Başka platform', accent: true),
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
              padding: const EdgeInsets.only(top: AppSpacing.xs),
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
                margin: const EdgeInsets.only(top: AppSpacing.xs + 1),
                decoration:
                    BoxDecoration(color: cs.primary, shape: BoxShape.circle),
              ),
              if (!last)
                const Expanded(
                  child: SkPencilLine(vertical: true, thickness: 6, seed: 5),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Sk.ui(context,
                          size: 15, weight: FontWeight.w800, height: 1.25)),
                  if (detail.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
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
  final NextSessionHint? next;
  final bool ready;
  final ValueNotifier<double> offset;
  final List<LiveChip> chips;

  const _PlayerHero({
    required this.playerId,
    required this.name,
    required this.imageUrl,
    required this.quote,
    required this.onStage,
    required this.ready,
    required this.offset,
    this.next,
    this.chips = const [],
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Size screen = MediaQuery.sizeOf(context);
    final double h = (screen.height * 0.78).clamp(560.0, 700.0);
    final double s = (screen.width * 0.62).clamp(190.0, 270.0);
    final bool hasPhoto = imageUrl.trim().startsWith('http');

    return SizedBox(
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Zemin: fotoğrafın bulanık hâli (afişten türeyen ortam)
          if (hasPhoto)
            ValueListenableBuilder<double>(
              valueListenable: offset,
              builder: (final context, final o, child) => ClipRect(
                child: Transform.translate(
                  offset: Offset(0, o.clamp(0, h) * 0.3),
                  child: child,
                ),
              ),
              child: RepaintBoundary(
                child: Transform.scale(
                  scale: 1.5,
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
                    child: SkImage(url: imageUrl),
                  ),
                ),
              ),
            )
          else
            ColoredBox(color: cs.primaryContainer),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.55),
                    cs.surface,
                  ],
                  stops: const [0.0, 0.35, 0.78, 1.0],
                ),
              ),
            ),
          ),
          // Canlı portre sahnesi
          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.paddingOf(context).top + 44,
            child: Center(
              child: LivePortraitStage(
                imageUrl: imageUrl,
                size: s,
                chips: chips,
                offset: offset,
                onTap: hasPhoto
                    ? () => GalleryViewerDialog.open(context, [imageUrl.trim()])
                    : null,
                heroWrap: (final child) => TiyatrolHero(
                  tag: resolveTiyatrolHeroTag(
                      context, TiyatrolHeroTags.player(playerId)),
                  child: child,
                ),
              ),
            ),
          ),
          // Ad + durum
          Positioned(
            left: 22,
            right: 22,
            bottom: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _NameReveal(name: name),
                const SizedBox(height: 10),
                SkSquiggle(width: 120, seed: name.length),
                const SizedBox(height: 14),
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
                      Text(
                        next == null
                            ? (onStage ? 'Şu an sahnede' : 'Sahneye ara verdi')
                            : 'Sıradaki ${skDayPhrase(next!.when)} · ${skClock(next!.when)}',
                        style: Sk.ui(context,
                            size: 12.5,
                            color: Colors.white,
                            weight: FontWeight.w800),
                      ),
                    ]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ad: kelime kelime, aşağıdan süzülerek ve belirerek açılır (bir kez).
class _NameReveal extends StatefulWidget {
  final String name;
  const _NameReveal({required this.name});

  @override
  State<_NameReveal> createState() => _NameRevealState();
}

class _NameRevealState extends State<_NameReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (Sk.reduceMotion(context)) {
        _c.value = 1;
      } else {
        _c.forward();
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final List<String> words =
        widget.name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    return AnimatedBuilder(
      animation: _c,
      builder: (final context, _) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        children: [
          for (int i = 0; i < words.length; i++)
            _word(context, words[i], i),
        ],
      ),
    );
  }

  Widget _word(final BuildContext context, final String w, final int i) {
    final double start = (i * 0.22).clamp(0.0, 0.7);
    final double v = Curves.easeOutCubic
        .transform(((_c.value - start) / (1 - start)).clamp(0.0, 1.0));
    return Opacity(
      opacity: v,
      child: Transform.translate(
        offset: Offset(0, (1 - v) * 26),
        child: Text(
          w,
          style: Sk.display(context, size: 40, color: Colors.white, height: 1.05)
              .copyWith(shadows: [
            Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 18,
                offset: const Offset(0, 4)),
          ]),
        ),
      ),
    );
  }
}


/// "Şu an sahnede" afiş yelpazesi: büyük afişler yana kayar, ortadaki öne
/// çıkar, yanlardakiler eğilip küçülür. Ortadaki afişe dokununca oyun açılır;
/// yandakine dokununca ortaya gelir. Altında seçili oyunun adı ve türü.
class _StageFan extends StatefulWidget {
  final List<Show> shows;
  final ValueChanged<Show> onShow;

  const _StageFan({required this.shows, required this.onShow});

  @override
  State<_StageFan> createState() => _StageFanState();
}

class _StageFanState extends State<_StageFan> {
  late final PageController _c = PageController(viewportFraction: 0.62);
  int _i = 0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<Show> shows = widget.shows;
    final Show cur = shows[_i.clamp(0, shows.length - 1)];
    return LayoutBuilder(builder: (final context, final box) {
      final double pageW = box.maxWidth * 0.62;
      final double cardW = pageW - 16;
      final double cardH = cardW * 1.5;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkSectionHead(
            title: 'Şu an sahnede',
            subtitle: shows.length > 1
                ? '${shows.length} oyun · kaydır, ortadakine dokun'
                : 'Biletleri açık',
            icon: Icons.theater_comedy_rounded,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: cardH + 44,
            child: PageView.builder(
              controller: _c,
              clipBehavior: Clip.none,
              itemCount: shows.length,
              onPageChanged: (final i) {
                HapticFeedback.selectionClick();
                setState(() => _i = i);
              },
              itemBuilder: (final context, final i) => AnimatedBuilder(
                animation: _c,
                builder: (final context, _) {
                  double d = (_i - i).toDouble();
                  if (_c.hasClients && _c.position.haveDimensions) {
                    d = (_c.page ?? _i.toDouble()) - i;
                  }
                  final double ad = d.abs().clamp(0.0, 1.0);
                  return Transform.translate(
                    offset: Offset(0, ad * 26 + 8),
                    child: Transform.rotate(
                      angle: d * -0.11,
                      child: Transform.scale(
                        scale: 1 - 0.13 * ad,
                        child: Opacity(
                          opacity: 1 - 0.35 * ad,
                          child: Center(
                            child: PressScale(
                              onTap: () {
                                if (i == _i) {
                                  widget.onShow(shows[i]);
                                } else {
                                  _c.animateToPage(i,
                                      duration:
                                          const Duration(milliseconds: 420),
                                      curve: Curves.easeOutCubic);
                                }
                              },
                              semanticLabel: shows[i].name,
                              child: _FanCard(
                                  show: shows[i], width: cardW, height: cardH),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (shows.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < shows.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _i ? 22 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: i == _i
                            ? cs.primary
                            : cs.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: Column(
                key: ValueKey<String>(cur.id),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cur.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.display(context, size: 22, height: 1.1)),
                  if (cur.category.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(cur.category.trim(),
                        style: Sk.ui(context,
                            size: 13,
                            color: cs.onSurfaceVariant,
                            weight: FontWeight.w700)),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _FanCard extends StatelessWidget {
  final Show show;
  final double width;
  final double height;

  const _FanCard(
      {required this.show, required this.width, required this.height});

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: width,
      height: height,
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
              tag: TiyatrolHeroTags.show(show.id, 'player'),
              child: SkImage(url: show.imageUrl),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
            const Positioned(
              left: 12,
              top: 12,
              child: SkBadge(label: 'Sahnede', accent: true),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  final int onStage;
  final int past;
  final int awards;
  final VoidCallback? onStageTap;
  final VoidCallback? onPastTap;
  final VoidCallback? onAwardsTap;

  const _Stats({
    required this.onStage,
    required this.past,
    required this.awards,
    this.onStageTap,
    this.onPastTap,
    this.onAwardsTap,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<({String value, String unit, bool hot, VoidCallback? onTap})>
        items = [
      (
        value: '$onStage',
        unit: 'sahnede',
        hot: onStage > 0,
        onTap: onStageTap,
      ),
      (
        value: '$past',
        unit: 'geçmiş',
        hot: false,
        onTap: onPastTap,
      ),
      (
        value: '$awards',
        unit: 'ödül',
        hot: false,
        onTap: onAwardsTap,
      ),
    ];

    return Reveal(
      index: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sahne künyesi',
            style: Sk.ui(context,
                size: 12,
                color: cs.onSurfaceVariant,
                weight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.lg),
              itemBuilder: (final context, final i) {
                final it = items[i];
                return Reveal(
                  index: i + 1,
                  child: PressScale(
                    onTap: it.onTap,
                    semanticLabel: '${it.value} ${it.unit}',
                    scale: 0.94,
                    child: ListingMetricOrb(
                      value: it.value,
                      unit: it.unit,
                      emphasized: it.hot,
                      size: 100,
                    ),
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



String _yearSpan(final List<Map<String, String>> awards) {
  final List<int> ys = [
    for (final a in awards)
      if (int.tryParse((a['year'] ?? '').trim()) != null)
        int.parse((a['year'] ?? '').trim()),
  ]..sort();
  if (ys.isEmpty) return '';
  return ys.first == ys.last ? ' · ${ys.first}' : ' · ${ys.first}–${ys.last}';
}

/// Replik kartı: kâğıt notu gibi hafif eğik, el yazısıyla.
class _QuoteNote extends StatelessWidget {
  final String quote;
  final String name;

  const _QuoteNote({required this.quote, required this.name});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Transform.rotate(
      angle: -0.014,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
          boxShadow: skSoftShadow(context, strength: 0.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('“',
                    style: Sk.display(context,
                        size: 64, color: cs.primary, height: 0.9)),
                const Spacer(),
                Icon(Icons.edit_outlined,
                    size: 18, color: cs.onSurfaceVariant),
              ],
            ),
            Text(quote,
                style: Sketch.hand(context,
                    size: 30, height: 1.1, weight: FontWeight.w700)),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(name.isEmpty ? 'sahneden' : '— $name',
                      style: Sketch.hand(context,
                          size: 24, color: cs.onSurfaceVariant)),
                  const SkPencilLine(width: 96, seed: 9),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Biyografi: ilk harf büyük (süslü baş harf), gerisi rahat okunur metin.
class _DropCap extends StatelessWidget {
  final String text;
  final int? maxLines;

  const _DropCap({required this.text, this.maxLines});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String first = text.characters.first;
    final String rest = text.characters.skip(1).toString();
    // Rakamla/işaretle başlayan metinde süslü baş harf yok (sayı bölünmesin).
    if (!RegExp(r'^\p{L}', unicode: true).hasMatch(first)) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: maxLines == null ? TextOverflow.visible : TextOverflow.fade,
        style: Sk.ui(context,
            size: 15,
            color: cs.onSurface.withValues(alpha: 0.86),
            weight: FontWeight.w500,
            height: 1.65),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8, top: 2),
          child: Text(first,
              style: Sk.display(context,
                  size: 68,
                  height: 0.85,
                  color: cs.primary,
                  weight: FontWeight.w800)),
        ),
        Expanded(
          child: Text(
            rest,
            maxLines: maxLines,
            overflow:
                maxLines == null ? TextOverflow.visible : TextOverflow.fade,
            style: Sk.ui(context,
                size: 15,
                color: cs.onSurface.withValues(alpha: 0.86),
                weight: FontWeight.w500,
                height: 1.65),
          ),
        ),
      ],
    );
  }
}

/// El yazısıyla, hafif eğik, altı kalemle çizili isim — dokununca arama.
/// Çalıştığı topluluklar: tek yumuşak kart, satır satır; ilk 4 satır açık,
/// fazlası "+N topluluk daha" ile açılır. Dokununca topluluğun oyunları aranır.
class _CollabList extends StatefulWidget {
  final List<String> names;
  final ValueChanged<String> onTap;
  const _CollabList({required this.names, required this.onTap});

  @override
  State<_CollabList> createState() => _CollabListState();
}

class _CollabListState extends State<_CollabList> {
  bool _all = false;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<String> shown =
        _all ? widget.names : widget.names.take(4).toList();
    final int more = widget.names.length - shown.length;
    return SkSoftCard(
      radius: AppRadius.lg,
      color: cs.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          for (int i = 0; i < shown.length; i++) ...[
            PressScale(
              onTap: () => widget.onTap(shown[i]),
              semanticLabel: '${shown[i]} oyunlarını ara',
              scale: 0.99,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
                child: Row(
                  children: [
                    Icon(Icons.groups_rounded, size: 20, color: cs.primary),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(shown[i],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.ui(context,
                              size: 14.5, weight: FontWeight.w700, height: 1.25)),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 20, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
            if (i < shown.length - 1)
              Divider(
                  height: 1,
                  indent: AppSpacing.lg,
                  endIndent: AppSpacing.lg,
                  color: cs.outlineVariant.withValues(alpha: 0.4)),
          ],
          if (more > 0 || _all)
            TextButton(
              onPressed: () => setState(() => _all = !_all),
              child: Text(_all ? 'Daha az göster' : '+$more topluluk daha'),
            ),
        ],
      ),
    );
  }
}

