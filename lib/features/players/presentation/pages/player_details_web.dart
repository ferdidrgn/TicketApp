import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/deeplink/deeplink_service.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/navigation/widgets/web_site_header.dart';
import '../../../../shared/widgets/footers/web_mega_footer.dart';
import '../../../../shared/widgets/gallery_section.dart';
import '../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../../shared/widgets/ticket/ticket_profile.dart'
    show splitShowsByLiveActivity;
import '../../../search/presentation/providers/search_query_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../domain/entities/player.dart';
import '../providers/player_provider.dart';
import '../widgets/sahne/player_costars.dart';

/// OYUNCU SAYFASI — WEB. Bir kişi/profil sayfası:
/// kapakta bulanık fotoğraf + büyük yuvarlak portre + ad, sıradaki durum ve
/// künye sayıları; altında sekmeler (Hakkında · Oyunları · Ödüller ·
/// Topluluklar). Mobil uygulamanın "canlı portre" sayfasından AYRIDIR.
class PlayerDetailPageWeb extends ConsumerStatefulWidget {
  final String playerId;
  const PlayerDetailPageWeb({super.key, required this.playerId});

  @override
  ConsumerState<PlayerDetailPageWeb> createState() =>
      _PlayerDetailPageWebState();
}

class _PlayerDetailPageWebState extends ConsumerState<PlayerDetailPageWeb> {
  int _tab = 0;

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
        padding: EdgeInsets.symmetric(vertical: 120),
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      body = _content(context, state);
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const WebSiteHeader(),
            body,
            const SizedBox(height: 72),
            const WebMegaFooter(),
          ],
        ),
      ),
    );
  }

  Widget _content(final BuildContext context, final PlayerDetailState state) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Player p = state.player;
    final String name = '${p.firstName} ${p.lastName}'.trim();
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
    final String bio = p.bio.replaceAll('\\n', '\n').trim();
    final bool hasPhoto = p.imageUrl.startsWith('http');

    final List<(int, String)> tabs = [
      (0, 'Hakkında'),
      if (active.isNotEmpty || past.isNotEmpty)
        (1, 'Oyunları (${active.length + past.length})'),
      if (awards.isNotEmpty) (2, 'Ödüller (${awards.length})'),
      if (collabs.isNotEmpty) (3, 'Topluluklar (${collabs.length})'),
    ];
    final int tab = tabs.any((t) => t.$1 == _tab) ? _tab : 0;

    return LayoutBuilder(builder: (final context, final box) {
      final double w = box.maxWidth;
      final double gutter = w >= 1200 ? 48 : (w >= 768 ? 32 : 18);
      final bool wide = w >= 900;

      Widget stat(final String v, final String l) => Padding(
            padding: const EdgeInsets.only(right: 34),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(v, style: Sk.display(context, size: 34, height: 1.0)),
              const SizedBox(height: 2),
              Text(l,
                  style: Sk.ui(context,
                      size: 13,
                      color: cs.onSurfaceVariant,
                      weight: FontWeight.w700)),
            ]),
          );

      final Widget portrait = GestureDetector(
        onTap: hasPhoto
            ? () => GalleryViewerDialog.open(context, [p.imageUrl.trim()])
            : null,
        child: MouseRegion(
          cursor: hasPhoto ? SystemMouseCursors.zoomIn : MouseCursor.defer,
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: cs.primary, width: 3),
            ),
            child: ClipOval(
              child: SizedBox(
                width: wide ? 230 : 160,
                height: wide ? 230 : 160,
                child: SkImage(
                    url: p.imageUrl,
                    alignment: const Alignment(0, -0.35),
                    fallbackIcon: Icons.person_rounded),
              ),
            ),
          ),
        ),
      );

      final Widget identity = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            SkBadge(
                label: active.isNotEmpty ? 'Şu an sahnede' : 'Sahneye ara verdi',
                accent: active.isNotEmpty),
          ]),
          const SizedBox(height: 14),
          Text(name, style: Sk.display(context, size: 52, height: 1.05)),
          if (p.quote.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('“${p.quote.trim()}”',
                style: Sk.ui(context,
                    size: 17,
                    color: cs.onSurface.withValues(alpha: 0.85),
                    weight: FontWeight.w500,
                    height: 1.45)),
          ],
          const SizedBox(height: 24),
          Row(children: [
            stat('${active.length}', 'sahnede'),
            stat('${past.length}', 'geçmiş oyun'),
            stat('${awards.length}', 'ödül'),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => TiyatrolDeeplinkService.shareActor(
                  id: p.id, name: name),
              icon: const Icon(Icons.ios_share_rounded, size: 18),
              label: const Text('Paylaş'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  shape: const StadiumBorder()),
            ),
          ]),
        ],
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kapak
          Stack(children: [
            if (hasPhoto)
              Positioned.fill(
                child: ClipRect(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                    child: Transform.scale(
                        scale: 1.4, child: SkImage(url: p.imageUrl)),
                  ),
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cs.surface.withValues(alpha: 0.55),
                      cs.surface.withValues(alpha: 0.75),
                      cs.surface,
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1360),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 40, gutter, 40),
                  child: wide
                      ? Row(children: [
                          portrait,
                          const SizedBox(width: 56),
                          Expanded(child: identity),
                        ])
                      : Column(children: [
                          portrait,
                          const SizedBox(height: 24),
                          identity,
                        ]),
                ),
              ),
            ),
          ]),
          // Sekmeler
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1360),
              child: Padding(
                padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: cs.outlineVariant)),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          for (final (int, String) t in tabs)
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => setState(() => _tab = t.$1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 26, vertical: 16),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                          color: tab == t.$1
                                              ? cs.primary
                                              : Colors.transparent,
                                          width: 3),
                                    ),
                                  ),
                                  child: Text(t.$2,
                                      style: Sk.ui(context,
                                          size: 15.5,
                                          color: tab == t.$1
                                              ? cs.primary
                                              : cs.onSurface,
                                          weight: FontWeight.w800)),
                                ),
                              ),
                            ),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _tabBody(context, tab, p, bio, active, past, awards, collabs, w),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _tabBody(
    final BuildContext context,
    final int tab,
    final Player p,
    final String bio,
    final List<Show> active,
    final List<Show> past,
    final List<Map<String, String>> awards,
    final List<String> collabs,
    final double w,
  ) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    switch (tab) {
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (active.isNotEmpty) ...[
              Text('Sahnede', style: Sk.display(context, size: 26, height: 1.1)),
              const SizedBox(height: 18),
              _ShowGrid(shows: active, width: w),
            ],
            if (past.isNotEmpty) ...[
              const SizedBox(height: 44),
              Text('Geçmiş oyunlar',
                  style: Sk.display(context, size: 26, height: 1.1)),
              const SizedBox(height: 18),
              _ShowGrid(shows: past, width: w),
            ],
          ],
        );
      case 2:
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(children: [
            for (final Map<String, String> a in awards)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Row(children: [
                  Icon(Icons.emoji_events_rounded, color: cs.primary, size: 30),
                  const SizedBox(width: 18),
                  Text((a['year'] ?? '').trim(),
                      style: Sk.display(context, size: 26, color: cs.primary)),
                  const SizedBox(width: 22),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((a['title'] ?? '').trim(),
                              style: Sk.ui(context,
                                  size: 16, weight: FontWeight.w800)),
                          if ((a['detail'] ?? '').trim().isNotEmpty)
                            Text((a['detail'] ?? '').trim(),
                                style: Sk.ui(context,
                                    size: 14,
                                    color: cs.onSurfaceVariant,
                                    weight: FontWeight.w500)),
                        ]),
                  ),
                ]),
              ),
          ]),
        );
      case 3:
        return Wrap(spacing: 14, runSpacing: 14, children: [
          for (final String c in collabs)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () {
                  ref.read(searchQueryProvider.notifier).update(c);
                  ref.read(searchFilterProvider.notifier).setFilter(0);
                  NavigationHandler.goToSearch(context);
                },
                child: LayoutBuilder(builder: (final context, final box) => Container(
                  width: box.maxWidth < 330 ? box.maxWidth : 330,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        child: Icon(Icons.groups_rounded,
                            color: cs.onPrimaryContainer)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(c,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.ui(context,
                              size: 15, weight: FontWeight.w800)),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: cs.onSurfaceVariant),
                  ]),
                )),
              ),
            ),
        ]);
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: SelectableText(
                bio.isEmpty ? 'Bu oyuncu için henüz bir biyografi eklenmemiş.' : bio,
                style: Sk.ui(context,
                    size: 16,
                    weight: FontWeight.w500,
                    height: 1.75,
                    color: cs.onSurface.withValues(alpha: 0.9)),
              ),
            ),
            const SizedBox(height: 48),
            PlayerCoStars(player: p, shows: [...active, ...past]),
          ],
        );
    }
  }
}

class _ShowGrid extends StatelessWidget {
  final List<Show> shows;
  final double width;
  const _ShowGrid({required this.shows, required this.width});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double inner = (width > 1360 ? 1360 : width) - 96;
    final int cols = (inner / 220).floor().clamp(2, 6);
    const double gap = 24;
    final double cw = (inner - gap * (cols - 1)) / cols;
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
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 2 / 3,
                        child: SkImage(
                            url: s.imageUrl, alignment: Alignment.topCenter),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(s.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Sk.ui(context,
                            size: 15,
                            weight: FontWeight.w800,
                            height: 1.25,
                            color: cs.onSurface)),
                  ]),
            ),
          ),
        ),
    ]);
  }
}
