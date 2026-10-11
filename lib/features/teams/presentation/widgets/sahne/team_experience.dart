import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/services/deeplink/deeplink_service.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/gallery_section.dart';
import '../../../../../shared/widgets/listing.dart';
import '../../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../../../shared/widgets/ticket/ticket_profile.dart'
    show ProfileErrorView, splitShowsByLiveActivity;
import '../../../../../shared/widgets/tiyatrol_hero.dart';
import '../../../../players/domain/entities/player.dart';
import '../../../../search/presentation/providers/search_query_provider.dart';
import '../../../../shows/domain/entities/show.dart';
import '../../../../shows/presentation/providers/show_provider.dart';
import '../../../../shows/presentation/widgets/detail/show_detail_actions.dart';
import '../../../domain/entities/team.dart';
import '../../providers/team_provider.dart';

/// TOPLULUK SAYFASI — "Sahne". Telefon, tablet ve web için tek duyarlı yüzey.
///
/// Ensemble görsel + ad, canlı sayaçlar (sahnede / geçmiş / kadro / foto),
/// repertuvar rayları, hikâye, kadro, galeri. Birincil aksiyon: oyuna git.
class TeamExperience extends ConsumerStatefulWidget {
  final String teamId;
  final Widget? footer;

  const TeamExperience({super.key, required this.teamId, this.footer});

  @override
  ConsumerState<TeamExperience> createState() => _TeamExperienceState();
}

class _TeamExperienceState extends ConsumerState<TeamExperience> {
  final ScrollController _scroll = ScrollController();
  final ValueNotifier<double> _offset = ValueNotifier(0);
  final GlobalKey _onStageKey = GlobalKey();
  final GlobalKey _pastKey = GlobalKey();
  final GlobalKey _castKey = GlobalKey();
  final GlobalKey _photosKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.hasClients) {
        _offset.value = _scroll.offset;
      }
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
    if (c == null) {
      return;
    }
    HapticFeedback.selectionClick();
    Scrollable.ensureVisible(
      c,
      duration: Sk.reduceMotion(context)
          ? Duration.zero
          : const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
      alignment: 0.05,
    );
  }

  void _openShow(final Show s) => NavigationHandler.goToShow(
        context,
        s.id,
        s.name,
        heroTag: TiyatrolHeroTags.show(s.id, 'team'),
        imageUrl: s.imageUrl,
        title: s.name,
      );

  void _openPlayer(final Player p) {
    final String name = '${p.firstName} ${p.lastName}'.trim();
    NavigationHandler.goToPlayer(
      context,
      p.id,
      name,
      heroTag: TiyatrolHeroTags.player(p.id, 'team'),
      imageUrl: p.imageUrl,
      title: name,
    );
  }

  void _searchTeam(final String name) {
    HapticFeedback.selectionClick();
    ref.read(searchQueryProvider.notifier).update(name);
    ref.read(searchFilterProvider.notifier).setFilter(4);
    NavigationHandler.goToSearch(context);
  }

  @override
  Widget build(final BuildContext context) {
    final async = ref.watch(teamDetailProvider(widget.teamId));
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
      error: (final e, final _) => ProfileErrorView(
        error: e,
        notFoundTitle: 'Bu topluluk bulunamadı',
        failedTitle: 'Topluluk bilgileri yüklenemedi',
        onRetry: () => ref.invalidate(teamDetailProvider(widget.teamId)),
      ),
      data: (final state) {
        final split = splitShowsByLiveActivity(
          claimedActive: state.shows,
          past: const <Show>[],
          liveActive: ref.watch(activeShowsProvider(false)).value,
        );
        final List<Player> ensemble =
            ref.watch(teamEnsemblePlayersProvider(widget.teamId)).value ??
                const <Player>[];
        return _scaffold(
          context,
          team: state.team,
          name: state.team.name,
          imageUrl: state.team.imageUrl,
          active: split.active,
          past: split.past,
          ensemble: ensemble,
          castCount: state.ensemblePlayerIds.length,
          ready: true,
        );
      },
    );
  }

  Widget _scaffold(
    final BuildContext context, {
    final Team? team,
    required final String name,
    required final String imageUrl,
    final List<Show> active = const [],
    final List<Show> past = const [],
    final List<Player> ensemble = const [],
    final int castCount = 0,
    required final bool ready,
  }) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final EdgeInsets safe = MediaQuery.paddingOf(context);

    return LayoutBuilder(builder: (final context, final box) {
      final double w = box.maxWidth;
      final bool wide = w >= 980;
      final double gutter = Sk.gutter(w);
      final int photoCount = team?.photosId.length ?? 0;

      final List<String> teamPhotos = [
        if (imageUrl.trim().startsWith('http')) imageUrl.trim(),
        for (final String p in team?.photosId ?? const <String>[])
          if (p.trim().startsWith('http') && p.trim() != imageUrl.trim())
            p.trim(),
      ];

      final Widget identity = _Identity(
        teamId: widget.teamId,
        name: name,
        imageUrl: imageUrl,
        photos: teamPhotos,
        onStage: active.isNotEmpty,
        ready: ready,
        left: wide,
        offset: _offset,
      );

      final Widget stats = ready
          ? Padding(
              padding: const EdgeInsets.only(top: 28),
              child: _Stats(
                onStage: active.length,
                past: past.length,
                cast: castCount,
                photos: photoCount,
                onStageTap:
                    active.isEmpty ? null : () => _scrollToKey(_onStageKey),
                onPastTap: past.isEmpty ? null : () => _scrollToKey(_pastKey),
                onCastTap:
                    castCount == 0 ? null : () => _scrollToKey(_castKey),
                onPhotosTap:
                    photoCount == 0 ? null : () => _scrollToKey(_photosKey),
              ),
            )
          : const SizedBox.shrink();

      final Widget body = ready
          ? _Body(
              team: team!,
              active: active,
              past: past,
              ensemble: ensemble,
              onStageKey: _onStageKey,
              pastKey: _pastKey,
              castKey: _castKey,
              photosKey: _photosKey,
              onShow: _openShow,
              onPlayer: _openPlayer,
              onSearch: () => _searchTeam(name),
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
          _scrollToKey(_onStageKey);
        }
      }

      final Widget topBar = _TopBar(
        name: name,
        offset: _offset,
        gutter: wide ? gutter : 12,
        onShare: team == null
            ? null
            : () => TiyatrolDeeplinkService.shareTeam(
                id: team.id, name: team.name),
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
                                    child: Text(
                                      cta,
                                      style: Sk.ui(context,
                                          size: 15,
                                          color: cs.onPrimary,
                                          weight: FontWeight.w800),
                                    ),
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
                  child: _TeamHero(
                    teamId: widget.teamId,
                    name: name,
                    imageUrl: imageUrl,
                    photos: [
                      if (imageUrl.trim().startsWith('http')) imageUrl.trim(),
                      for (final String p in team?.photosId ?? const <String>[])
                        if (p.trim().startsWith('http') &&
                            p.trim() != imageUrl.trim())
                          p.trim(),
                    ],
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
                                EdgeInsets.fromLTRB(gutter, 28, gutter, 0),
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
                child: Text(
                  cta,
                  style: Sk.ui(context,
                      size: 15,
                      color: cs.onPrimary,
                      weight: FontWeight.w800),
                ),
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
        builder: (final context, final o, final _) {
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
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.display(context, size: 18),
                    ),
                  ),
                ),
                if (onShare != null)
                  ShowQuietIconButton(
                    icon: Icons.ios_share_rounded,
                    label: 'Topluluğu paylaş',
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
  final String teamId;
  final String name;
  final String imageUrl;
  final List<String> photos;
  final bool onStage;
  final bool ready;
  final bool left;
  final ValueNotifier<double> offset;

  const _Identity({
    required this.teamId,
    required this.name,
    required this.imageUrl,
    required this.photos,
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
    const double pw = 240;
    const double ph = 300;
    const double pr = 28;

    final Widget poster = GestureDetector(
      onTap: photos.isEmpty
          ? null
          : () => GalleryViewerDialog.open(context, photos),
      child: TiyatrolHero(
        tag: resolveTiyatrolHeroTag(context, TiyatrolHeroTags.team(teamId)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(pr),
            boxShadow: skSoftShadow(context, strength: 1.1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(pr),
            child: SkImage(
              url: imageUrl,
              width: pw,
              height: ph,
              radius: pr,
              alignment: const Alignment(0, -0.2),
              fallbackIcon: Icons.groups_2_rounded,
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: align,
      children: [
        if (left)
          poster
        else
          ValueListenableBuilder<double>(
            valueListenable: offset,
            builder: (final context, final o, final child) => Opacity(
              opacity: 1 - 0.85 * (o / 300).clamp(0.0, 1.0),
              child: child,
            ),
            child: poster,
          ),
        const SizedBox(height: 22),
        if (ready) _StatusPill(onStage: onStage),
        const SizedBox(height: 12),
        Text(
          name,
          textAlign: left ? TextAlign.start : TextAlign.center,
          style: Sk.display(context, size: left ? 38 : 32, height: 1.05),
        ),
        const SizedBox(height: 8),
        Text(
          'Tiyatro topluluğu',
          textAlign: left ? TextAlign.start : TextAlign.center,
          style: Sk.ui(
            context,
            size: 14,
            color: cs.onSurfaceVariant,
            weight: FontWeight.w600,
          ),
        ),
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
            builder: (final context, final _) => Container(
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
          Text(
            widget.onStage ? 'Şu an sahnede' : 'Repertuvar ara verdi',
            style: Sk.ui(context, size: 12.5, weight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  final int onStage;
  final int past;
  final int cast;
  final int photos;
  final VoidCallback? onStageTap;
  final VoidCallback? onPastTap;
  final VoidCallback? onCastTap;
  final VoidCallback? onPhotosTap;

  const _Stats({
    required this.onStage,
    required this.past,
    required this.cast,
    required this.photos,
    this.onStageTap,
    this.onPastTap,
    this.onCastTap,
    this.onPhotosTap,
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
        value: '$cast',
        unit: 'kadro',
        hot: false,
        onTap: onCastTap,
      ),
      (
        value: '$photos',
        unit: 'foto',
        hot: false,
        onTap: onPhotosTap,
      ),
    ];

    return Reveal(
      index: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Topluluk künyesi',
            style: Sk.ui(context,
                size: 12,
                color: cs.onSurfaceVariant,
                weight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (final _, final __) =>
                  const SizedBox(width: 16),
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

class _Body extends StatefulWidget {
  final Team team;
  final List<Show> active;
  final List<Show> past;
  final List<Player> ensemble;
  final GlobalKey onStageKey;
  final GlobalKey pastKey;
  final GlobalKey castKey;
  final GlobalKey photosKey;
  final ValueChanged<Show> onShow;
  final ValueChanged<Player> onPlayer;
  final VoidCallback onSearch;

  const _Body({
    required this.team,
    required this.active,
    required this.past,
    required this.ensemble,
    required this.onStageKey,
    required this.pastKey,
    required this.castKey,
    required this.photosKey,
    required this.onShow,
    required this.onPlayer,
    required this.onSearch,
  });

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  bool _storyOpen = false;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String story =
        widget.team.description.replaceAll('\\n', '\n').trim();
    final bool longStory = story.length > 260;
    final bool nothingLinked =
        widget.active.isEmpty && widget.past.isEmpty;

    Widget section(final int i, final Widget child) => Reveal(
          index: i,
          child: Padding(padding: const EdgeInsets.only(top: 34), child: child),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KeyedSubtree(
          key: widget.onStageKey,
          child: section(
            0,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkSectionHead(
                  title: 'Sahnede',
                  subtitle: widget.active.isEmpty
                      ? null
                      : '${widget.active.length} oyun',
                ),
                const SizedBox(height: 14),
                if (widget.active.isNotEmpty)
                  for (final Show s in widget.active)
                    _ShowRow(show: s, onTap: widget.onShow, live: true)
                else
                  _QuietNote(
                    text: nothingLinked
                        ? 'Topluluğun şu an sahnede bir oyunu yok.'
                        : 'Topluluğun şu an sahnede bir oyunu yok. Sahnelediği oyunlar aşağıda.',
                    actionLabel: nothingLinked
                        ? 'Sahnedeki oyunlara göz at'
                        : null,
                    onAction: nothingLinked
                        ? () {
                            HapticFeedback.selectionClick();
                            NavigationHandler.goToDiscover(context);
                          }
                        : null,
                  ),
              ],
            ),
          ),
        ),
        if (story.isNotEmpty)
          section(
            1,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkSectionHead(title: 'Hikâye'),
                const SizedBox(height: 12),
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: Text(
                    story,
                    maxLines: _storyOpen || !longStory ? null : 6,
                    overflow: _storyOpen || !longStory
                        ? TextOverflow.visible
                        : TextOverflow.fade,
                    style: Sk.ui(context,
                        size: 15,
                        color: cs.onSurface.withValues(alpha: 0.86),
                        weight: FontWeight.w500,
                        height: 1.65),
                  ),
                ),
                if (longStory)
                  PressScale(
                    onTap: () => setState(() => _storyOpen = !_storyOpen),
                    semanticLabel:
                        _storyOpen ? 'Daha az göster' : 'Devamını oku',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _storyOpen ? 'Daha az göster' : 'Devamını oku',
                        style: Sk.ui(context,
                            size: 14,
                            color: cs.primary,
                            weight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        section(
          2,
          PressScale(
            onTap: widget.onSearch,
            semanticLabel: '${widget.team.name} için ara',
            child: SkSoftCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bu topluluğu ara',
                      style: Sk.ui(context,
                          size: 14.5, weight: FontWeight.w700),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
        if (widget.ensemble.isNotEmpty)
          section(
            3,
            KeyedSubtree(
              key: widget.castKey,
              child: SkRail<Player>(
                title: 'Kadro',
                subtitle: '${widget.ensemble.length} oyuncu',
                items: widget.ensemble,
                gutter: 0,
                railW: 120,
                railH: 178,
                minCell: 120,
                builder: (final p, final cw) {
                  final String name =
                      '${p.firstName} ${p.lastName}'.trim();
                  return SizedBox(
                    width: 112,
                    child: PressScale(
                      onTap: () => widget.onPlayer(p),
                      semanticLabel: name,
                      child: Column(
                        children: [
                          TiyatrolHero(
                            tag: TiyatrolHeroTags.player(p.id, 'team'),
                            child: SkImage(
                              url: p.imageUrl,
                              width: 104,
                              height: 120,
                              radius: 52,
                              alignment: Alignment.topCenter,
                              fallbackIcon: Icons.person_rounded,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${p.firstName}\n${p.lastName}'.trim(),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Sk.ui(context,
                                size: 12.5,
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
                builder: (final s, final w) => PressScale(
                  onTap: () => widget.onShow(s),
                  semanticLabel: s.name,
                  child: Container(
                    width: w,
                    height: w * 1.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: skSoftShadow(context),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          TiyatrolHero(
                            tag: TiyatrolHeroTags.show(s.id, 'team'),
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
                            left: 12,
                            right: 12,
                            bottom: 12,
                            child: Text(
                              s.name,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Sk.display(context,
                                  size: 15,
                                  color: Colors.white,
                                  height: 1.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (widget.team.photosId.isNotEmpty)
          section(
            5,
            KeyedSubtree(
              key: widget.photosKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkSectionHead(
                    title: 'Fotoğraflar',
                    subtitle: '${widget.team.photosId.length} fotoğraf',
                  ),
                  const SizedBox(height: 14),
                  GallerySection(photos: [
                    if (widget.team.imageUrl.trim().startsWith('http'))
                      widget.team.imageUrl.trim(),
                    for (final String p in widget.team.photosId)
                      if (p.trim().startsWith('http') &&
                          p.trim() != widget.team.imageUrl.trim())
                        p.trim(),
                  ]),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _QuietNote extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _QuietNote({
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SkSoftCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: Sk.ui(context,
                size: 14.5,
                color: cs.onSurfaceVariant,
                weight: FontWeight.w500,
                height: 1.45),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            PressScale(
              onTap: onAction,
              semanticLabel: actionLabel,
              child: Text(
                actionLabel!,
                style: Sk.ui(context,
                    size: 14, color: cs.primary, weight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
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
                tag: TiyatrolHeroTags.show(show.id, 'team'),
                child: SkImage(
                    url: show.imageUrl, width: 64, height: 92, radius: 14),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      show.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.ui(context,
                          size: 15, weight: FontWeight.w800, height: 1.2),
                    ),
                    if (show.category.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          show.category.trim(),
                          style: Sk.ui(context,
                              size: 12.5,
                              color: cs.onSurfaceVariant,
                              weight: FontWeight.w500),
                        ),
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

/// Kenardan kenara topluluk kahramanı: ad ve durum fotoğrafın üstünde.
class _TeamHero extends StatelessWidget {
  final String teamId;
  final String name;
  final String imageUrl;
  final List<String> photos;
  final bool onStage;
  final bool ready;
  final ValueNotifier<double> offset;

  const _TeamHero({
    required this.teamId,
    required this.name,
    required this.imageUrl,
    required this.photos,
    required this.onStage,
    required this.ready,
    required this.offset,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double h =
        (MediaQuery.sizeOf(context).height * 0.62).clamp(440.0, 600.0);
    return SizedBox(
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ValueListenableBuilder<double>(
            valueListenable: offset,
            builder: (final context, final o, final child) => ClipRect(
              child: Transform.translate(
                offset: Offset(0, o.clamp(0, h) * 0.45),
                child: child,
              ),
            ),
            child: GestureDetector(
              onTap: photos.isEmpty
                  ? null
                  : () => GalleryViewerDialog.open(context, photos),
              child: TiyatrolHero(
                tag: resolveTiyatrolHeroTag(
                    context, TiyatrolHeroTags.team(teamId)),
                child: SkImage(
                  url: imageUrl,
                  fallbackIcon: Icons.groups_2_rounded,
                ),
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
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.92),
                    cs.surface,
                  ],
                  stops: const [0.0, 0.2, 0.42, 0.7, 0.9, 1.0],
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
                      Text(
                        onStage ? 'Şu an sahnede' : 'Repertuvar ara verdi',
                        style: Sk.ui(context,
                            size: 12.5,
                            color: Colors.white,
                            weight: FontWeight.w800),
                      ),
                    ]),
                  ),
                const SizedBox(height: 10),
                Text(
                  'TOPLULUK',
                  style: Sk.ui(context,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.78),
                      weight: FontWeight.w800,
                      letterSpacing: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Sk.display(context,
                          size: 40, color: Colors.white, height: 1.02)
                      .copyWith(shadows: [
                    Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 18,
                        offset: const Offset(0, 4)),
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
