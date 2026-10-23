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
import '../widgets/sahne/show_session_extras.dart';

/// OYUN DETAYI — WEB. Bir bilet sitesinin ürün sayfası:
///
/// Üstte ekmek kırıntısı; solda galeri (büyük afiş + küçük resimler, tıklayınca
/// tam ekran); sağda yapışkan bilgi kutusu (tür, ad, puan, künye, seans
/// seçici, "Bilet al"). Altta sekmeler (Hikâye · Seanslar ve mekân · Kadro ·
/// Yorumlar) ve "Benzer oyunlar" rafı. Mobil uygulamanın "Sahne" oyun
/// sayfasından AYRIDIR. Kendi `Scaffold`'unu kurar.
class ShowDetailPage extends ConsumerStatefulWidget {
  final String showId;
  const ShowDetailPage({super.key, required this.showId});

  @override
  ConsumerState<ShowDetailPage> createState() => _ShowDetailPageState();
}

class _ShowDetailPageState extends ConsumerState<ShowDetailPage> {
  int _photo = 0;
  int _tab = 0;
  ShowSession? _selected;
  DateTime? _day;
  bool _recorded = false;
  bool _opening = false;

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
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
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
      body = const Center(
          heightFactor: 8, child: CircularProgressIndicator());
    } else {
      final ShowDetailData d = ShowDetailData.from(state);
      if (!_recorded) {
        _recorded = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(recentShowIdsProvider.notifier).add(widget.showId);
          }
        });
      }
      body = _content(context, d);
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
      floatingActionButton: state == null
          ? null
          : ShowChatBubbleButton(
              showId: state.show.id, showName: state.show.name),
    );
  }

  Widget _content(final BuildContext context, final ShowDetailData d) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Show show = d.show;
    final List<String> photos = _photos(show);
    final List<DateTime> days = [];
    for (final ShowSession s in d.sessions) {
      if (s.when == null) continue;
      final DateTime x = skDay(s.when!);
      if (!days.contains(x)) days.add(x);
    }
    final DateTime? activeDay = _day != null && days.contains(_day)
        ? _day
        : (days.isEmpty ? null : days.first);
    final List<ShowSession> daySessions = [
      for (final ShowSession s in d.sessions)
        if (activeDay == null || (s.when != null && skDay(s.when!) == activeDay))
          s,
    ];
    final ShowSession? chosen = _selected != null &&
            d.sessions.any((final s) => s.event.id == _selected!.event.id)
        ? _selected
        : (daySessions.isEmpty ? null : daySessions.first);

    return LayoutBuilder(builder: (final context, final box) {
      final double w = box.maxWidth;
      final bool desktop = w >= 1024;
      final double gutter = w >= 1200 ? 48 : (w >= 768 ? 32 : 18);

      final Widget gallery = _GalleryBlock(
        narrow: !desktop,
        photos: photos,
        index: _photo.clamp(0, photos.isEmpty ? 0 : photos.length - 1),
        onPick: (final i) => setState(() => _photo = i),
        onOpen: () => photos.isEmpty
            ? null
            : GalleryViewerDialog.open(context, photos),
      );

      final Widget info = _InfoPanel(
        data: d,
        days: days,
        activeDay: activeDay,
        daySessions: daySessions,
        chosen: chosen,
        busy: _opening,
        onDay: (final x) => setState(() {
          _day = x;
          _selected = null;
        }),
        onSession: (final s) => setState(() => _selected = s),
        onBuy: () => _buy(d, chosen),
        onReviews: () => setState(() => _tab = 3),
      );

      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Padding(
            padding: EdgeInsets.fromLTRB(gutter, 22, gutter, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Breadcrumb(show: show),
                const SizedBox(height: 22),
                desktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 6, child: gallery),
                          const SizedBox(width: 48),
                          Expanded(flex: 6, child: info),
                        ],
                      )
                    : Column(children: [
                        gallery,
                        const SizedBox(height: 28),
                        info,
                      ]),
                const SizedBox(height: 56),
                _Tabs(
                  index: _tab,
                  reviewsLabel: 'Yorumlar',
                  onTab: (final i) => setState(() => _tab = i),
                  hasCast: d.cast.isNotEmpty || d.pastCast.isNotEmpty,
                ),
                const SizedBox(height: 28),
                _tabBody(context, d, desktop),
                const SizedBox(height: 56),
                _SimilarRail(show: show),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _tabBody(
      final BuildContext context, final ShowDetailData d, final bool desktop) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    switch (_tab) {
      case 0:
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: SelectableText(
            d.description.isEmpty
                ? 'Bu oyun için henüz bir açıklama eklenmemiş.'
                : d.description,
            style: Sk.ui(context,
                size: 16,
                weight: FontWeight.w500,
                height: 1.75,
                color: cs.onSurface.withValues(alpha: 0.9)),
          ),
        );
      case 1:
        return _SessionsTable(data: d);
      case 2:
        return _CastGrid(players: [...d.cast, ...d.pastCast], current: d.cast);
      default:
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ReviewsSection(
              showId: d.show.id, showName: d.show.name),
        );
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════

class _Breadcrumb extends StatelessWidget {
  final Show show;
  const _Breadcrumb({required this.show});

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
      sep,
      Flexible(
        child: Text(show.name,
            maxLines: 1, overflow: TextOverflow.ellipsis, style: s(false)),
      ),
    ]);
  }
}

class _GalleryBlock extends StatelessWidget {
  final List<String> photos;
  final int index;
  final ValueChanged<int> onPick;
  final VoidCallback onOpen;
  final bool narrow;
  const _GalleryBlock(
      {required this.photos,
      required this.index,
      required this.onPick,
      required this.onOpen,
      this.narrow = false});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final String main = photos.isEmpty ? '' : photos[index];

    Widget thumb(final int i, final double w) => Padding(
          padding: EdgeInsets.only(
              right: narrow ? 10 : 0, bottom: narrow ? 0 : 12),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onPick(i),
              child: Container(
                width: w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: i == index
                          ? cs.primary
                          : cs.outlineVariant.withValues(alpha: 0.5),
                      width: i == index ? 2.5 : 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: SkImage(
                        url: photos[i], alignment: Alignment.topCenter),
                  ),
                ),
              ),
            ),
          ),
        );

    final Widget mainImage = MouseRegion(
      cursor: SystemMouseCursors.zoomIn,
      child: GestureDetector(
        onTap: onOpen,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 14)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(fit: StackFit.expand, children: [
                SkImage(url: main, alignment: Alignment.topCenter),
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.zoom_out_map_rounded,
                        color: Colors.white, size: 20),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );

    if (narrow) {
      return Column(children: [
        mainImage,
        if (photos.length > 1) ...[
          const SizedBox(height: 14),
          SizedBox(
            height: 84,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              itemBuilder: (_, final i) => thumb(i, 63),
            ),
          ),
        ],
      ]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (photos.length > 1)
          SizedBox(
            width: 84,
            child: Column(children: [
              for (int i = 0; i < photos.length && i < 6; i++) thumb(i, 84),
            ]),
          ),
        if (photos.length > 1) const SizedBox(width: 16),
        Expanded(child: mainImage),
      ],
    );
  }
}

class _InfoPanel extends ConsumerWidget {
  final ShowDetailData data;
  final List<DateTime> days;
  final DateTime? activeDay;
  final List<ShowSession> daySessions;
  final ShowSession? chosen;
  final bool busy;
  final ValueChanged<DateTime> onDay;
  final ValueChanged<ShowSession> onSession;
  final VoidCallback onBuy;
  final VoidCallback onReviews;

  const _InfoPanel({
    required this.data,
    required this.days,
    required this.activeDay,
    required this.daySessions,
    required this.chosen,
    required this.busy,
    required this.onDay,
    required this.onSession,
    required this.onBuy,
    required this.onReviews,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Show show = data.show;
    final ReviewStat? stat = ref.watch(reviewStatsProvider).value?[show.id];
    final bool external = data.isExternal;
    final String cta = external
        ? 'Biletini bul'
        : (chosen == null ? 'Seans seçin' : 'Koltuk seç');
    final bool canBuy = external || chosen != null;

    Widget fact(final IconData icon, final String label, final String value) =>
        Padding(
          padding: const EdgeInsets.only(right: 28, bottom: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: Sk.ui(context,
                      size: 11.5,
                      color: cs.onSurfaceVariant,
                      weight: FontWeight.w700)),
              Text(value,
                  style: Sk.ui(context, size: 14.5, weight: FontWeight.w800)),
            ]),
          ]),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          if (show.category.trim().isNotEmpty)
            SkBadge(label: show.category.trim()),
          if (external) ...[
            const SizedBox(width: 8),
            const SkBadge(
                label: 'Başka platformda',
                icon: Icons.open_in_new_rounded),
          ],
          const Spacer(),
          ShowFavoriteButton(showId: show.id),
          ShowShareButton(show: show),
        ]),
        const SizedBox(height: 12),
        Text(show.name,
            style: Sk.display(context, size: 44, height: 1.08)),
        const SizedBox(height: 14),
        if (stat != null && stat.count > 0)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onReviews,
              child: Row(children: [
                StarRow(rating: stat.average, size: 20),
                const SizedBox(width: 10),
                Text('${stat.average.toStringAsFixed(1)} · ${stat.count} yorum',
                    style: Sk.ui(context,
                        size: 14,
                        color: cs.primary,
                        weight: FontWeight.w800)),
              ]),
            ),
          ),
        const SizedBox(height: 20),
        Wrap(children: [
          if (show.duration.trim().isNotEmpty)
            fact(Icons.schedule_rounded, 'Süre', show.duration.trim()),
          if (show.ageLimit.trim().isNotEmpty)
            fact(Icons.shield_outlined, 'Yaş sınırı', show.ageLimit.trim()),
          if (show.type.trim().isNotEmpty)
            fact(Icons.category_outlined, 'Tür', show.type.trim()),
        ]),
        Divider(color: cs.outlineVariant.withValues(alpha: 0.5), height: 32),

        // Seans seçici
        if (!external) ...[
          Text(data.sessions.isEmpty
                  ? (data.hasEnded ? 'Perde indi' : 'Henüz seans yok')
                  : 'Seans seçin',
              style: Sk.ui(context, size: 16, weight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (data.sessions.isEmpty)
            Text(
                data.hasEnded
                    ? 'Bu oyunun bütün seansları geçti.'
                    : 'Perde açılınca tarihler burada görünecek.',
                style: Sk.ui(context,
                    size: 14,
                    color: cs.onSurfaceVariant,
                    weight: FontWeight.w500))
          else ...[
            SizedBox(
              height: 78,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (final context, final i) {
                  final DateTime x = days[i];
                  final bool sel = x == activeDay;
                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => onDay(x),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 66,
                        decoration: BoxDecoration(
                          color: sel ? cs.primary : cs.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(kDaysShortTr[x.weekday - 1],
                                style: Sk.ui(context,
                                    size: 11.5,
                                    color: (sel ? cs.onPrimary : cs.onSurface)
                                        .withValues(alpha: 0.8),
                                    weight: FontWeight.w700)),
                            Text('${x.day}',
                                style: Sk.display(context,
                                    size: 24,
                                    height: 1.1,
                                    color: sel ? cs.onPrimary : cs.onSurface)),
                            Text(kMonthsShortTr[x.month - 1],
                                style: Sk.ui(context,
                                    size: 11.5,
                                    color: (sel ? cs.onPrimary : cs.onSurface)
                                        .withValues(alpha: 0.8),
                                    weight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
            for (final ShowSession s in daySessions)
              _SessionPick(
                session: s,
                selected: chosen?.event.id == s.event.id,
                onTap: () => onSession(s),
              ),
          ],
          const SizedBox(height: 8),
        ],
        if (external)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(children: [
              Icon(Icons.open_in_new_rounded, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                    'Bu oyunun biletleri iş ortağımızın sayfasında satılıyor.',
                    style: Sk.ui(context,
                        size: 14, weight: FontWeight.w600, height: 1.4)),
              ),
            ]),
          ),
        const SizedBox(height: 20),
        Row(children: [
          if (data.lowestPrice != null)
            Padding(
              padding: const EdgeInsets.only(right: 22),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bilet fiyatı',
                        style: Sk.ui(context,
                            size: 12,
                            color: cs.onSurfaceVariant,
                            weight: FontWeight.w700)),
                    Text("${skPrice(chosen?.price ?? data.lowestPrice!)}"
                        "${chosen?.price == null ? "'den" : ''}",
                        style: Sk.display(context,
                            size: 30, height: 1.1, color: cs.primary)),
                  ]),
            ),
          Expanded(
            child: FilledButton(
              onPressed: canBuy && !busy ? onBuy : null,
              style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 58),
                  shape: const StadiumBorder()),
              child: busy
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: cs.onPrimary))
                  : Text(cta,
                      style: Sk.ui(context,
                          size: 17,
                          color: cs.onPrimary,
                          weight: FontWeight.w800)),
            ),
          ),
        ]),
        const SizedBox(height: 22),
        Wrap(spacing: 22, runSpacing: 8, children: [
          for (final (IconData, String) b in const [
            (Icons.event_seat_rounded, 'Koltuğunu kendin seç'),
            (Icons.phone_iphone_rounded, 'Dijital bilet'),
            (Icons.event_available_rounded, 'Takvime ekle'),
          ])
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(b.$1, size: 17, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(b.$2,
                  style: Sk.ui(context,
                      size: 13,
                      color: cs.onSurfaceVariant,
                      weight: FontWeight.w600)),
            ]),
        ]),
      ],
    );
  }
}

class _SessionPick extends StatelessWidget {
  final ShowSession session;
  final bool selected;
  final VoidCallback onTap;
  const _SessionPick(
      {required this.session, required this.selected, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final DateTime? when = session.when;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: selected
                  ? cs.primary.withValues(alpha: 0.12)
                  : cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: selected
                      ? cs.primary
                      : cs.outlineVariant.withValues(alpha: 0.5),
                  width: selected ? 1.8 : 1),
            ),
            child: Row(children: [
              Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? cs.primary : cs.outline),
              const SizedBox(width: 14),
              Text(when == null ? session.shortLabel : skClock(when),
                  style: Sk.display(context,
                      size: 24, height: 1.0, color: cs.primary)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(session.venueName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Sk.ui(context,
                        size: 14.5, weight: FontWeight.w700, height: 1.25)),
              ),
              if (session.priceLabel != null)
                Text(session.priceLabel!,
                    style: Sk.ui(context,
                        size: 15, color: cs.primary, weight: FontWeight.w800)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final int index;
  final String reviewsLabel;
  final ValueChanged<int> onTab;
  final bool hasCast;
  const _Tabs(
      {required this.index,
      required this.reviewsLabel,
      required this.onTab,
      required this.hasCast});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<(int, String)> tabs = [
      (0, 'Hikâye'),
      (1, 'Seanslar ve mekân'),
      if (hasCast) (2, 'Kadro'),
      (3, reviewsLabel),
    ];
    return Container(
      decoration: BoxDecoration(
        border:
            Border(bottom: BorderSide(color: cs.outlineVariant, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
        for (final (int, String) t in tabs)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTab(t.$1),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                        color: index == t.$1 ? cs.primary : Colors.transparent,
                        width: 3),
                  ),
                ),
                child: Text(t.$2,
                    maxLines: 1,
                    style: Sk.ui(context,
                        size: 15.5,
                        color: index == t.$1 ? cs.primary : cs.onSurface,
                        weight: FontWeight.w800)),
              ),
            ),
          ),
      ]),
      ),
    );
  }
}

class _SessionsTable extends StatelessWidget {
  final ShowDetailData data;
  const _SessionsTable({required this.data});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    if (data.sessions.isEmpty) {
      return Text(
          data.hasEnded
              ? 'Bu oyunun bütün seansları geçti.'
              : 'Henüz seans eklenmemiş.',
          style: Sk.ui(context, size: 15, color: cs.onSurfaceVariant));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(children: [
            for (int i = 0; i < data.sessions.length; i++) ...[
              Padding(
                padding: const EdgeInsets.all(18),
                child: MediaQuery.sizeOf(context).width < 760
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(
                                  data.sessions[i].when == null
                                      ? data.sessions[i].shortLabel
                                      : '${data.sessions[i].when!.day} ${kMonthsTr[data.sessions[i].when!.month - 1]} ${kDaysTr[data.sessions[i].when!.weekday - 1]}',
                                  style: Sk.ui(context,
                                      size: 15, weight: FontWeight.w800)),
                            ),
                            Text(
                                data.sessions[i].when == null
                                    ? ''
                                    : skClock(data.sessions[i].when!),
                                style: Sk.display(context,
                                    size: 22, height: 1, color: cs.primary)),
                          ]),
                          const SizedBox(height: 6),
                          Row(children: [
                            Expanded(
                              child: Text(data.sessions[i].venueName,
                                  style: Sk.ui(context,
                                      size: 14, weight: FontWeight.w600)),
                            ),
                            if (data.sessions[i].priceLabel != null)
                              Text(data.sessions[i].priceLabel!,
                                  style: Sk.ui(context,
                                      size: 15,
                                      color: cs.primary,
                                      weight: FontWeight.w800)),
                          ]),
                          SessionActions(
                              session: data.sessions[i],
                              showName: data.show.name,
                              duration: data.show.duration),
                        ],
                      )
                    : Row(children: [
                  SizedBox(
                    width: 150,
                    child: Text(
                        data.sessions[i].when == null
                            ? data.sessions[i].shortLabel
                            : '${data.sessions[i].when!.day} ${kMonthsTr[data.sessions[i].when!.month - 1]} ${kDaysTr[data.sessions[i].when!.weekday - 1]}',
                        style: Sk.ui(context,
                            size: 15, weight: FontWeight.w800)),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                        data.sessions[i].when == null
                            ? ''
                            : skClock(data.sessions[i].when!),
                        style: Sk.display(context,
                            size: 22, height: 1, color: cs.primary)),
                  ),
                  Expanded(
                    child: Text(data.sessions[i].venueName,
                        style: Sk.ui(context,
                            size: 14.5, weight: FontWeight.w600)),
                  ),
                  if (data.sessions[i].priceLabel != null)
                    Text(data.sessions[i].priceLabel!,
                        style: Sk.ui(context,
                            size: 15,
                            color: cs.primary,
                            weight: FontWeight.w800)),
                  const SizedBox(width: 12),
                  SessionActions(
                      session: data.sessions[i],
                      showName: data.show.name,
                      duration: data.show.duration),
                ]),
              ),
              if (i < data.sessions.length - 1)
                Divider(
                    height: 1,
                    color: cs.outlineVariant.withValues(alpha: 0.35)),
            ],
          ]),
        ),
        if (data.venues.isNotEmpty) ...[
          const SizedBox(height: 36),
          Text('Mekân', style: Sk.display(context, size: 26, height: 1.1)),
          const SizedBox(height: 16),
          Wrap(spacing: 20, runSpacing: 20, children: [
            for (final Stage v in data.venues)
              _VenueCard(stage: v),
          ]),
        ],
      ],
    );
  }
}

class _VenueCard extends StatelessWidget {
  final Stage stage;
  const _VenueCard({required this.stage});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (final context, final box) => Container(
      width: box.maxWidth < 420 ? box.maxWidth : 420,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 92,
            height: 92,
            child: SkImage(
                url: stage.imageUrl, fallbackIcon: Icons.location_city_rounded),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stage.name,
                    style: Sk.ui(context, size: 16, weight: FontWeight.w800)),
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
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => openStageDirections(stage),
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text('Yol tarifi'),
                ),
              ]),
        ),
      ]),
    ));
  }
}

class _CastGrid extends StatelessWidget {
  final List<Player> players;
  final List<Player> current;
  const _CastGrid({required this.players, required this.current});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Wrap(spacing: 28, runSpacing: 34, children: [
      for (final Player p in players)
        SizedBox(
          width: 150,
          child: Center(
            child: SkFlowerPortrait(
              imageUrl: p.imageUrl,
              size: 126,
              semanticLabel: '${p.firstName} ${p.lastName}'.trim(),
              bottomChip: current.any((final c) => c.id == p.id)
                  ? 'Kadroda'
                  : 'Önceki kadro',
              bottomChipAccent: current.any((final c) => c.id == p.id),
              onTap: () => NavigationHandler.goToPlayer(
                  context, p.id, '${p.firstName} ${p.lastName}'.trim(),
                  imageUrl: p.imageUrl,
                  title: '${p.firstName} ${p.lastName}'.trim()),
              title: Text('${p.firstName} ${p.lastName}'.trim(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: Sk.ui(context,
                      size: 14.5,
                      weight: FontWeight.w800,
                      height: 1.2,
                      color: cs.onSurface)),
            ),
          ),
        ),
    ]);
  }
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Benzer oyunlar', style: Sk.display(context, size: 30, height: 1.1)),
        const SizedBox(height: 22),
        SizedBox(
          height: 420,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 24),
            itemBuilder: (final context, final i) => MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => NavigationHandler.goToShow(
                    context, list[i].id, list[i].name,
                    imageUrl: list[i].imageUrl, title: list[i].name),
                child: SizedBox(
                  width: 230,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 2 / 3,
                            child: SkImage(
                                url: list[i].imageUrl,
                                alignment: Alignment.topCenter),
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
      ],
    );
  }
}
