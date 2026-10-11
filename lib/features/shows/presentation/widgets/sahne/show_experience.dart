import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/util/show_duration.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/gallery_section.dart';
import '../../../../../shared/widgets/listing.dart';
import '../../../../../shared/widgets/sahne/sahne_kit.dart';
import '../../../../../shared/widgets/tiyatrol_hero.dart';
import '../../../../auth/presentation/providers/auth_provider.dart'
    show currentUserIdProvider;
import '../../../../chatbot/presentation/widgets/show_chat_bubble_button.dart';
import '../../../../players/domain/entities/player.dart';
import '../../../../stages/domain/entities/stage.dart';
import '../../../domain/entities/show.dart';
import '../../providers/show_detail_provider.dart';
import '../../providers/show_provider.dart';
import '../detail/show_detail_actions.dart';
import '../detail/show_detail_data.dart';
import '../show_team_credit.dart';

/// OYUN DETAYI — "Sahne". Telefon, tablet ve web için tek duyarlı yüzey.
///
/// - Afişten türeyen ortam zemini, parallax'lı afiş, gerçek bilgi rozetleri.
/// - Seanslar: gün çipleri → seçilen günün seansları; seçili seans alttaki
///   TEK birincil aksiyonu ("Koltuk seç") belirler.
/// - Kadro, mekân (yol tarifi), galeri (tam ekran görüntüleyici).
/// - Geniş ekranda solda sabit bilet paneli, sağda kayan içerik.
class ShowExperience extends ConsumerStatefulWidget {
  final String showId;
  final bool showFooter;
  final Widget? footer;

  const ShowExperience({
    super.key,
    required this.showId,
    this.showFooter = false,
    this.footer,
  });

  @override
  ConsumerState<ShowExperience> createState() => _ShowExperienceState();
}

class _ShowExperienceState extends ConsumerState<ShowExperience> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _sessionsKey = GlobalKey();
  final GlobalKey _castKey = GlobalKey();
  final ValueNotifier<double> _offset = ValueNotifier(0);

  ShowSession? _selected;
  DateTime? _day;
  bool _opening = false;
  bool _scrollHandled = false;

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

  void _scrollToSessions() => _scrollToKey(_sessionsKey);

  void _scrollToCast() => _scrollToKey(_castKey);

  void _scrollToKey(final GlobalKey key) {
    final BuildContext? c = key.currentContext;
    if (c == null) return;
    HapticFeedback.selectionClick();
    Scrollable.ensureVisible(c,
        duration: Sk.reduceMotion(context) ? Duration.zero : AppMotion.slow,
        curve: AppMotion.emphasized,
        alignment: 0.04);
  }

  void _maybeScrollFromLink() {
    if (_scrollHandled) return;
    String? scrollTo;
    try {
      scrollTo = GoRouterState.of(context).uri.queryParameters['scrollTo'];
    } catch (_) {}
    if (scrollTo != 'etkinlikler') return;
    _scrollHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSessions();
      Future<void>.delayed(AppMotion.normal, _scrollToSessions);
    });
  }

  Future<void> _external(final String url) async {
    if (_opening) return;
    setState(() => _opening = true);
    await openExternalTickets(context, url);
    if (mounted) setState(() => _opening = false);
  }

  void _seats(final ShowSession s) {
    HapticFeedback.mediumImpact();
    final String uid = ref.read(currentUserIdProvider) ?? 'guest';
    NavigationHandler.goToSeatSelection(context, widget.showId, s.event.id, uid);
  }

  void _primary(final ShowDetailData d) {
    if (d.isExternal) {
      _external(d.show.externalTicketUrl);
      return;
    }
    final ShowSession? s = _selected ?? d.nextSession;
    if (s == null) return;
    _seats(s);
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final async = ref.watch(showDetailProvider(widget.showId));
    final String previewTitle =
        TiyatrolHeroFlight.field(context, 'title') ?? '';
    final String previewImage =
        TiyatrolHeroFlight.field(context, 'imageUrl') ?? '';
    final state = async.value;
    final ShowDetailData? loaded =
        state == null ? null : ShowDetailData.from(state);
    final ShowDetailData data = loaded ??
        ShowDetailData.preview(
            id: widget.showId, name: previewTitle, imageUrl: previewImage);

    if (async.hasError && loaded == null) {
      return SafeArea(
        child: SkEmpty(
          icon: Icons.theater_comedy_rounded,
          title: 'Oyun yüklenemedi',
          message: 'Bağlantını kontrol edip tekrar dene.',
          actionLabel: 'Tekrar dene',
          onAction: () => ref.invalidate(showDetailProvider(widget.showId)),
        ),
      );
    }
    if (loaded != null) _maybeScrollFromLink();

    final String cat = data.show.category.trim().toLowerCase();
    final List<Show> similar = [
      for (final Show x in ref.watch(showsActiveFirstProvider(false)).value ?? const <Show>[])
        if (x.id != data.show.id &&
            cat.isNotEmpty &&
            x.category.trim().toLowerCase() == cat)
          x,
    ];

    final ShowSession? chosen = _selected != null &&
            data.sessions.any((final s) => s.event.id == _selected!.event.id)
        ? _selected
        : data.nextSession;

    return LayoutBuilder(builder: (final context, final box) {
      final double w = box.maxWidth;
      final bool wide = w >= 980;
      final double gutter = Sk.gutter(w);
      final EdgeInsets safe = MediaQuery.paddingOf(context);

      final Widget content = _Content(
        data: data,
        ready: loaded != null,
        sessionsKey: _sessionsKey,
        castKey: _castKey,
        selected: chosen,
        selectedDay: _day ?? (chosen == null ? null : _dayOf(chosen)),
        onDay: (final d) {
          HapticFeedback.selectionClick();
          setState(() {
            _day = d;
            final first = data.sessions.firstWhere(
                (final s) => s.when != null && skDay(s.when!) == d,
                orElse: () => chosen ?? data.sessions.first);
            _selected = first;
          });
        },
        onSelect: (final s) {
          HapticFeedback.selectionClick();
          setState(() {
            _selected = s;
            if (s.when != null) _day = skDay(s.when!);
          });
        },
        similar: similar,
      );

      final Widget bar = _BuyBar(
        data: data,
        session: chosen,
        busy: _opening,
        onPressed: loaded == null ? null : () => _primary(data),
      );

      if (wide) {
        return Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: AmbientBackdrop(url: data.show.imageUrl, height: 640),
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
                        width: 380,
                        child: Padding(
                          padding: EdgeInsets.only(top: safe.top + 72),
                          child: _SidePanel(
                            data: data,
                            ready: loaded != null,
                            session: chosen,
                            busy: _opening,
                            onPressed:
                                loaded == null ? null : () => _primary(data),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                      Expanded(
                        child: ScrollConfiguration(
                          behavior: const SkScrollBehavior(),
                          child: CustomScrollView(
                            controller: _scroll,
                            slivers: [
                              SliverToBoxAdapter(
                                  child: SizedBox(height: safe.top + 72)),
                              SliverToBoxAdapter(child: content),
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
            _TopBar(
                data: data, offset: _offset, threshold: 120, gutter: gutter),
            if (loaded != null)
              Positioned(
                right: gutter,
                bottom: 24,
                child: ShowChatBubbleButton(
                    showId: data.show.id, showName: data.show.name),
              ),
          ],
        );
      }

      // Telefon / tablet: tek sütun + yapışkan alt çubuk.
      return Stack(
        children: [
          ColoredBox(color: cs.surface, child: const SizedBox.expand()),
          ScrollConfiguration(
            behavior: const SkScrollBehavior(),
            child: CustomScrollView(
              controller: _scroll,
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverToBoxAdapter(
                  child: _ShowHero(
                    data: data,
                    offset: _offset,
                    ready: loaded != null,
                    photos: _showPhotoUrls(data.show),
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
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                                gutter, AppSpacing.huge, gutter, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (loaded != null)
                                  _FactTiles(
                                    data: data,
                                    onSessions: _scrollToSessions,
                                    onCast: data.cast.isEmpty
                                        ? null
                                        : _scrollToCast,
                                  ),
                                content,
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
                        SizedBox(height: 120 + safe.bottom)),
              ],
            ),
          ),
          _TopBar(data: data, offset: _offset, threshold: 300, gutter: 12),
          if (loaded != null)
            Positioned(
              left: gutter,
              bottom: 96 + safe.bottom,
              child: ShowChatBubbleButton(
                  showId: data.show.id, showName: data.show.name),
            ),
          Positioned(left: 0, right: 0, bottom: 0, child: bar),
        ],
      );
    });
  }

  DateTime? _dayOf(final ShowSession s) =>
      s.when == null ? null : skDay(s.when!);
}

// ═════════════════════════════════════════════════════════════════════════════
// ÜST ÇUBUK
// ═════════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final ShowDetailData data;
  final ValueNotifier<double> offset;
  final double threshold;
  final double gutter;

  const _TopBar({
    required this.data,
    required this.offset,
    required this.threshold,
    required this.gutter,
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
          final double t = (o / threshold).clamp(0.0, 1.0);
          return Container(
            padding: EdgeInsets.fromLTRB(
                gutter < 20 ? 8 : gutter - 8, top + 6, gutter < 20 ? 8 : gutter - 8, 6),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.92 * t),
              border: Border(
                bottom: BorderSide(
                    color: cs.outlineVariant.withValues(alpha: 0.5 * t)),
              ),
            ),
            child: Row(
              children: [
                const ShowBackButton(onImage: true),
                const SizedBox(width: 8),
                Expanded(
                  child: Opacity(
                    opacity: t,
                    child: Text(data.show.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Sk.display(context, size: 18)),
                  ),
                ),
                ShowShareButton(show: data.show, onImage: true),
                const SizedBox(width: 8),
                ShowFavoriteButton(showId: data.show.id, onImage: true),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// KAPAK
// ═════════════════════════════════════════════════════════════════════════════

/// Afiş + galeri URL’leri (tekrarsız); tam ekran lightbox için.
List<String> _showPhotoUrls(final Show show) {
  final List<String> out = <String>[];
  final String poster = show.imageUrl.trim();
  if (poster.startsWith('http')) {
    out.add(poster);
  }
  for (final String p in show.photosShowId) {
    final String u = p.trim();
    if (u.startsWith('http') && !out.contains(u)) {
      out.add(u);
    }
  }
  return out;
}

Widget _poster(final BuildContext context, final ShowDetailData d,
    {required final double width}) {
  final ColorScheme cs = Theme.of(context).colorScheme;
  final List<String> photos = _showPhotoUrls(d.show);
  return PressScale(
    onTap: photos.isEmpty
        ? null
        : () => GalleryViewerDialog.open(context, photos),
    semanticLabel: '${d.show.name} görselleri',
    child: TiyatrolHero(
      tag: resolveTiyatrolHeroTag(context, TiyatrolHeroTags.show(d.show.id)),
      child: Container(
        width: width,
        height: width * 1.48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.level5(cs.shadow),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: SkImage(url: d.show.imageUrl),
        ),
      ),
    ),
  );
}

List<Widget> _facts(final BuildContext context, final ShowDetailData d) {
  final String category = d.show.category.trim();
  final String age = d.show.ageLimit.trim();
  final String? durText = ShowDurationFormat.label(d.show.duration);
  return [
    if (category.isNotEmpty)
      SkBadge(label: category, icon: Icons.theater_comedy_rounded),
    if (durText != null)
      SkBadge(label: durText, icon: Icons.timelapse_rounded),
    if (age.isNotEmpty) SkBadge(label: age, icon: Icons.group_outlined),
    if (d.isExternal)
      const SkBadge(label: 'Başka platformda', icon: Icons.open_in_new_rounded),
  ];
}

/// Kenardan kenara afiş kahramanı: başlık, rozetler ve yapım ekibi afişin
/// üstünde; alt kenar zemine karışır, içerik yuvarlak bir tabaka olarak biner.
class _ShowHero extends StatelessWidget {
  final ShowDetailData data;
  final ValueNotifier<double> offset;
  final bool ready;
  final List<String> photos;

  const _ShowHero({
    required this.data,
    required this.offset,
    required this.ready,
    required this.photos,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double h =
        (MediaQuery.sizeOf(context).height * 0.7).clamp(500.0, 680.0);
    final String category = data.show.category.trim();

    Widget glass(final IconData icon, final String text) => SkGlass(
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(text,
                style: Sk.ui(context,
                    size: 12.5, color: Colors.white, weight: FontWeight.w800)),
          ]),
        );

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
            child: GestureDetector(
              onTap: photos.isEmpty
                  ? null
                  : () => GalleryViewerDialog.open(context, photos),
              child: TiyatrolHero(
                tag: resolveTiyatrolHeroTag(
                    context, TiyatrolHeroTags.show(data.show.id)),
                child: SkImage(url: data.show.imageUrl),
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
                // Hero'da sadece kimlik rozetleri — süre/yaş aşağıda ferah metrikte.
                Wrap(spacing: 8, runSpacing: 8, children: [
                  if (category.isNotEmpty)
                    glass(Icons.theater_comedy_rounded, category),
                  if (data.isExternal)
                    glass(Icons.open_in_new_rounded, 'Başka platformda'),
                ]),
                const SizedBox(height: 16),
                Text(
                  data.show.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Sk.display(context,
                          size: 36, color: Colors.white, height: 1.05)
                      .copyWith(shadows: [
                    Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 18,
                        offset: const Offset(0, 4)),
                  ]),
                ),
                if (data.show.teamId.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ShowTeamCredit(teamId: data.show.teamId),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Program broşürü metrikleri — sıkışık kutu değil; nefes alan daireler.
/// Dokununca ilgili bölüme kayar (seans / kadro).
class _FactTiles extends StatelessWidget {
  final ShowDetailData data;
  final VoidCallback? onSessions;
  final VoidCallback? onCast;

  const _FactTiles({
    required this.data,
    this.onSessions,
    this.onCast,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final ({String value, String unit})? durationMetric =
        ShowDurationFormat.metric(data.show.duration);
    final String age = data.show.ageLimit.trim();

    final List<({String value, String unit, bool hot, VoidCallback? onTap})>
        items = [
      if (durationMetric != null)
        (
          value: durationMetric.value,
          unit: durationMetric.unit,
          hot: true,
          onTap: null,
        ),
      if (age.isNotEmpty)
        (
          value: age,
          unit: 'yaş',
          hot: false,
          onTap: null,
        ),
      (
        value: data.isExternal ? '—' : '${data.sessions.length}',
        unit: data.isExternal ? 'harici' : 'seans',
        hot: !data.isExternal && data.sessions.isNotEmpty,
        onTap: onSessions,
      ),
      if (data.cast.isNotEmpty)
        (
          value: '${data.cast.length}',
          unit: 'oyuncu',
          hot: false,
          onTap: onCast,
        ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();

    return Reveal(
      index: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Program notu',
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
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  final ShowDetailData data;
  final bool ready;
  final ShowSession? session;
  final bool busy;
  final VoidCallback? onPressed;

  const _SidePanel({
    required this.data,
    required this.ready,
    required this.session,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(final BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _poster(context, data, width: 300),
        const SizedBox(height: 22),
        Wrap(spacing: 8, runSpacing: 8, children: _facts(context, data)),
        const SizedBox(height: 14),
        Text(data.show.name, style: Sk.display(context, size: 34, height: 1.06)),
        const SizedBox(height: 10),
        if (data.show.teamId.isNotEmpty)
          ShowTeamCredit(teamId: data.show.teamId),
        const SizedBox(height: 20),
        _BuyBar(
            data: data,
            session: session,
            busy: busy,
            onPressed: onPressed,
            inline: true),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ALT ÇUBUK — TEK BİRİNCİL AKSİYON
// ═════════════════════════════════════════════════════════════════════════════

class _BuyBar extends StatelessWidget {
  final ShowDetailData data;
  final ShowSession? session;
  final bool busy;
  final VoidCallback? onPressed;
  final bool inline;

  const _BuyBar({
    required this.data,
    required this.session,
    required this.busy,
    required this.onPressed,
    this.inline = false,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double bottom = MediaQuery.paddingOf(context).bottom;
    final bool external = data.isExternal;
    final bool hasSession = session != null;
    final bool canBuy = external || hasSession;

    final String top = external
        ? 'Biletler başka platformda'
        : (hasSession
            ? '${skDayPhrase(session!.when ?? DateTime.now())}${session!.when == null ? '' : ' · ${skClock(session!.when!)}'}'
            : 'Seans bekleniyor');
    final double? price = external ? null : (session?.price ?? data.lowestPrice);
    final String sub = external
        ? 'Satın alma sayfası açılır'
        : (price != null ? '${skPrice(price)}\'den' : 'Fiyat seansta');
    final String cta = external
        ? 'Biletini bul'
        : (hasSession ? 'Koltuk seç' : 'Yakında');

    final Widget row = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(top,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Sk.ui(context, size: 14, weight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Sk.ui(context,
                      size: 12.5,
                      color: cs.onSurfaceVariant,
                      weight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Semantics(
          button: true,
          label: cta,
          child: FilledButton(
            onPressed: canBuy && !busy
                ? () {
                    HapticFeedback.mediumImpact();
                    onPressed!();
                  }
                : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 52),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              shape: const StadiumBorder(),
            ),
            child: busy
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: cs.onPrimary))
                : Text(cta,
                    style: Sk.ui(context,
                        size: 15,
                        color: cs.onPrimary,
                        weight: FontWeight.w800)),
          ),
        ),
      ],
    );

    if (inline) {
      return SkSoftCard(
        radius: AppRadius.lg,
        color: cs.surfaceContainerHigh,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: row,
      );
    }
    return Container(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.md, AppSpacing.lg, AppSpacing.md + bottom),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.96),
        border: Border(
            top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6))),
        boxShadow: AppShadows.level2(cs.shadow),
      ),
      child: Center(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720), child: row),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// İÇERİK
// ═════════════════════════════════════════════════════════════════════════════

class _Content extends StatelessWidget {
  final ShowDetailData data;
  final bool ready;
  final GlobalKey sessionsKey;
  final GlobalKey castKey;
  final ShowSession? selected;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDay;
  final ValueChanged<ShowSession> onSelect;
  final List<Show> similar;

  const _Content({
    required this.data,
    required this.ready,
    required this.sessionsKey,
    required this.castKey,
    required this.selected,
    required this.selectedDay,
    required this.onDay,
    required this.onSelect,
    this.similar = const [],
  });

  @override
  Widget build(final BuildContext context) {
    if (!ready) {
      return const Padding(
        padding: EdgeInsets.only(top: AppSpacing.xxl),
        child: Column(
          children: [
            SkBone(height: 20, radius: AppRadius.xs),
            SizedBox(height: AppSpacing.sm + 2),
            SkBone(height: 20, radius: AppRadius.xs),
            SizedBox(height: AppSpacing.xxl + 4),
            SkBone(height: 120, radius: AppRadius.lg),
          ],
        ),
      );
    }
    final List<Widget> gallery = [];
    final List<String> photos = _showPhotoUrls(data.show);
    // Galeri rayında afiş hariç ek kareler; lightbox’ta afiş de şeritte.
    final List<String> railPhotos = [
      for (final String p in data.show.photosShowId)
        if (p.trim().startsWith('http')) p.trim(),
    ];
    if (railPhotos.isNotEmpty) {
      gallery.add(_Gallery(photos: photos.length > 1 ? photos : railPhotos));
    }

    Widget section(final int i, final Widget child) => Reveal(
        index: i,
        child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.huge),
            child: child));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (data.description.isNotEmpty)
          section(0, _About(text: data.description)),
        section(
          1,
          KeyedSubtree(
            key: sessionsKey,
            child: _Sessions(
              data: data,
              selected: selected,
              selectedDay: selectedDay,
              onDay: onDay,
              onSelect: onSelect,
            ),
          ),
        ),
        if (data.cast.isNotEmpty)
          section(
            2,
            KeyedSubtree(
              key: castKey,
              child: _Cast(
                  title: 'Kadro', players: data.cast, large: true),
            ),
          ),
        if (data.pastCast.isNotEmpty)
          section(
              3, _Cast(title: 'Önceki kadro', players: data.pastCast, large: false)),
        if (data.venues.isNotEmpty)
          section(4, _Venues(venues: data.venues)),
        for (final Widget g in gallery) section(5, g),
        if (similar.isNotEmpty) section(6, _Similar(shows: similar)),
      ],
    );
  }
}

class _About extends StatefulWidget {
  final String text;
  const _About({required this.text});

  @override
  State<_About> createState() => _AboutState();
}

class _AboutState extends State<_About> {
  bool _open = false;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool long = widget.text.length > 240;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkSectionHead(title: 'Oyun hakkında'),
        const SizedBox(height: AppSpacing.md),
        AnimatedSize(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          alignment: Alignment.topCenter,
          child: Text(
            widget.text,
            maxLines: _open || !long ? null : 5,
            overflow: _open || !long ? TextOverflow.visible : TextOverflow.fade,
            style: Sk.ui(context,
                size: 15,
                color: cs.onSurface.withValues(alpha: 0.86),
                weight: FontWeight.w500,
                height: 1.65),
          ),
        ),
        if (long)
          PressScale(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _open = !_open);
            },
            semanticLabel: _open ? 'Daha az göster' : 'Devamını oku',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(_open ? 'Daha az göster' : 'Devamını oku',
                  style: Sk.ui(context,
                      size: 14, color: cs.primary, weight: FontWeight.w800)),
            ),
          ),
      ],
    );
  }
}

class _Sessions extends StatelessWidget {
  final ShowDetailData data;
  final ShowSession? selected;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDay;
  final ValueChanged<ShowSession> onSelect;

  const _Sessions({
    required this.data,
    required this.selected,
    required this.selectedDay,
    required this.onDay,
    required this.onSelect,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    if (data.isExternal) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkSectionHead(title: 'Biletler'),
          const SizedBox(height: AppSpacing.md),
          // Bilgi paneli — birincil aksiyon alt çubuktaki "Biletini bul".
          SkSoftCard(
            radius: AppRadius.lg,
            color: cs.surfaceContainerHigh,
            padding: const EdgeInsets.all(AppSpacing.lg + 2),
            child: Row(
              children: [
                Icon(Icons.open_in_new_rounded, color: cs.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Bu oyunun biletleri iş ortağımızın sayfasında satılıyor. Alttaki düğmeyle satın alma sayfasını aç.',
                    style: Sk.ui(context,
                        size: 14, weight: FontWeight.w600, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (data.sessions.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkSectionHead(title: 'Seanslar'),
          const SizedBox(height: AppSpacing.md),
          SkSoftCard(
            radius: AppRadius.lg,
            color: cs.surfaceContainerHigh,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.event_available_rounded,
                    color: cs.onSurfaceVariant, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Henüz seans yok',
                        style: Sk.ui(context,
                            size: 15, weight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Perde açılınca tarihler burada görünecek. Favoriye ekleyip haber bekleyebilirsin.',
                        style: Sk.ui(context,
                            size: 13.5,
                            color: cs.onSurfaceVariant,
                            weight: FontWeight.w500,
                            height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Gün çipleri (benzersiz günler) + tarihi okunamayanlar sonda.
    final List<DateTime> days = [];
    for (final ShowSession s in data.sessions) {
      if (s.when == null) continue;
      final DateTime d = skDay(s.when!);
      if (!days.contains(d)) days.add(d);
    }
    final List<ShowSession> shown = data.sessions.where((final s) {
      if (selectedDay == null) return true;
      return s.when != null && skDay(s.when!) == selectedDay;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkSectionHead(
          title: 'Seanslar',
          subtitle:
              '${data.sessions.length} seans · birini seç, alttan koltuğa geç',
        ),
        const SizedBox(height: AppSpacing.md),
        if (days.length > 1)
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: days.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.sm + 2),
              itemBuilder: (final context, final i) {
                final DateTime d = days[i];
                final bool sel = d == selectedDay;
                return Reveal(
                  index: i,
                  child: PressScale(
                    onTap: () => onDay(d),
                    semanticLabel:
                        '${kDaysTr[d.weekday - 1]} ${d.day} ${kMonthsTr[d.month - 1]}',
                    scale: 0.94,
                    child: AnimatedScale(
                      scale: sel && !Sk.reduceMotion(context) ? 1.04 : 1,
                      duration: AppMotion.fast,
                      curve: AppMotion.standard,
                      child: AnimatedContainer(
                      duration: AppMotion.fast,
                      curve: AppMotion.standard,
                      width: 64,
                      decoration: BoxDecoration(
                        color: sel ? cs.primary : cs.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(AppRadius.md + 4),
                        border: Border.all(
                          color: sel
                              ? Colors.transparent
                              : cs.outlineVariant.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(kDaysShortTr[d.weekday - 1],
                              style: Sk.ui(context,
                                  size: 11.5,
                                  color: (sel ? cs.onPrimary : cs.onSurface)
                                      .withValues(alpha: 0.75),
                                  weight: FontWeight.w700)),
                          Text('${d.day}',
                              style: Sk.display(context,
                                  size: 24,
                                  height: 1.1,
                                  weight: FontWeight.w700,
                                  color: sel ? cs.onPrimary : cs.onSurface)),
                          Text(kMonthsShortTr[d.month - 1],
                              style: Sk.ui(context,
                                  size: 11,
                                  color: (sel ? cs.onPrimary : cs.onSurface)
                                      .withValues(alpha: 0.75),
                                  weight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    ),
                  ),
                );
              },
            ),
          ),
        if (days.length > 1) const SizedBox(height: AppSpacing.md),
        for (int i = 0; i < shown.length; i++)
          Reveal(
            index: i + (days.length > 1 ? days.length : 0),
            child: _SessionCard(
              session: shown[i],
              selected:
                  selected != null && selected!.event.id == shown[i].event.id,
              onTap: () => onSelect(shown[i]),
            ),
          ),
      ],
    );
  }
}

class _SessionCard extends StatelessWidget {
  final ShowSession session;
  final bool selected;
  final VoidCallback onTap;

  const _SessionCard({
    required this.session,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final DateTime? when = session.when;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm + 2),
      child: PressScale(
        onTap: onTap,
        semanticLabel: selected
            ? '${session.semanticLabel}, seçili'
            : session.semanticLabel,
        scale: 0.985,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg + 2, AppSpacing.md, AppSpacing.md, AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? cs.primary.withValues(alpha: 0.12)
                : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected
                  ? cs.primary
                  : cs.outlineVariant.withValues(alpha: 0.5),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(when == null ? session.shortLabel : skClock(when),
                      style: Sk.display(context,
                          size: 26, height: 1.0, color: cs.primary)),
                  if (when != null)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                          '${kDaysTr[when.weekday - 1]}, ${when.day} ${kMonthsTr[when.month - 1]}',
                          style: Sk.ui(context,
                              size: 12.5,
                              color: cs.onSurfaceVariant,
                              weight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (session.venueName.isNotEmpty)
                      Text(session.venueName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Sk.ui(context,
                              size: 14, weight: FontWeight.w800, height: 1.2)),
                    if (session.priceLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(session.priceLabel!,
                            style: Sk.ui(context,
                                size: 13,
                                color: cs.onSurfaceVariant,
                                weight: FontWeight.w700)),
                      ),
                    if (selected)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text('Seçildi · alttan koltuk seç',
                            style: Sk.ui(context,
                                size: 12,
                                color: cs.primary,
                                weight: FontWeight.w800)),
                      ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: AppMotion.fast,
                child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  key: ValueKey<bool>(selected),
                  color: selected ? cs.primary : cs.outline,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cast extends StatelessWidget {
  final String title;
  final List<Player> players;
  final bool large;

  const _Cast(
      {required this.title, required this.players, required this.large});

  @override
  Widget build(final BuildContext context) {
    final double w = large ? 112 : 88;
    final double h = large ? 156 : 122;
    return SkRail<Player>(
      title: title,
      subtitle: '${players.length} oyuncu',
      items: players,
      gutter: 0,
      railW: w + 8,
      railH: h + 56,
      minCell: w + 8,
      builder: (final p, final cw) {
        final String name = '${p.firstName} ${p.lastName}'.trim();
        final String tag = TiyatrolHeroTags.player(p.id, 'show');
        final int i = players.indexOf(p);
        return Reveal(
          index: i.clamp(0, 8),
          child: SizedBox(
            width: w + 8,
            child: PressScale(
              onTap: () {
                HapticFeedback.selectionClick();
                NavigationHandler.goToPlayer(context, p.id, name,
                    heroTag: tag, imageUrl: p.imageUrl, title: name);
              },
              semanticLabel: name,
              child: Column(
                children: [
                  TiyatrolHero(
                    tag: tag,
                    child: SkImage(
                        url: p.imageUrl,
                        width: w,
                        height: h,
                        radius: w / 2,
                        alignment: Alignment.topCenter,
                        fallbackIcon: Icons.person_rounded),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text('${p.firstName}\n${p.lastName}'.trim(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Sk.ui(context,
                          size: large ? 13 : 12,
                          weight: FontWeight.w700,
                          height: 1.2)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Aynı türden diğer oyunlar — yatay şerit, Tümü → aşağı açılır.
class _Similar extends StatelessWidget {
  final List<Show> shows;
  const _Similar({required this.shows});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return SkRail<Show>(
      title: 'Bunlar da hoşuna gidebilir',
      subtitle: 'Aynı türden oyunlar',
      items: shows,
      gutter: 0,
      railW: 150,
      railH: 225,
      minCell: 150,
      builder: (final s, final w) {
        final int i = shows.indexOf(s);
        return Reveal(
          index: i.clamp(0, 8),
          child: PressScale(
            onTap: () {
              HapticFeedback.selectionClick();
              NavigationHandler.goToShow(context, s.id, s.name,
                  heroTag: TiyatrolHeroTags.show(s.id, 'similar'),
                  imageUrl: s.imageUrl,
                  title: s.name);
            },
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
                      tag: TiyatrolHeroTags.show(s.id, 'similar'),
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
                              size: 16, color: Colors.white, height: 1.1)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Venues extends StatelessWidget {
  final List<Stage> venues;
  const _Venues({required this.venues});

  Future<void> _directions(final Stage s) async {
    HapticFeedback.lightImpact();
    final Uri uri = (s.locationLat != 0 || s.locationLng != 0)
        ? Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${s.locationLat},${s.locationLng}')
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('${s.name} ${s.address}')}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkSectionHead(title: venues.length > 1 ? 'Mekânlar' : 'Mekân'),
        const SizedBox(height: AppSpacing.md),
        for (int i = 0; i < venues.length; i++)
          Reveal(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: PressScale(
                onTap: () {
                  HapticFeedback.selectionClick();
                  final Stage s = venues[i];
                  NavigationHandler.goToStage(context, s.id, s.name,
                      imageUrl: s.imageUrl, title: s.name);
                },
                semanticLabel: venues[i].name,
                scale: 0.985,
                child: SkSoftCard(
                  radius: AppRadius.lg,
                  color: cs.surfaceContainerLow,
                  padding: const EdgeInsets.all(AppSpacing.sm + 2),
                  child: Row(
                    children: [
                      SkImage(
                          url: venues[i].imageUrl,
                          width: 84,
                          height: 84,
                          radius: AppRadius.md,
                          fallbackIcon: Icons.location_city_rounded),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(venues[i].name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Sk.ui(context,
                                    size: 15, weight: FontWeight.w800)),
                            if (venues[i].address.trim().isNotEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: AppSpacing.xs),
                                child: Text(venues[i].address.trim(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Sk.ui(context,
                                        size: 12.5,
                                        color: cs.onSurfaceVariant,
                                        weight: FontWeight.w500)),
                              ),
                          ],
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: '${venues[i].name} yol tarifi',
                        child: IconButton(
                          tooltip: 'Yol tarifi',
                          onPressed: () async {
                            await _directions(venues[i]);
                          },
                          icon: Icon(Icons.directions_rounded,
                              color: cs.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Gallery extends StatelessWidget {
  final List<String> photos;
  const _Gallery({required this.photos});

  @override
  Widget build(final BuildContext context) => SkRail<String>(
        title: 'Galeri',
        subtitle: '${photos.length} fotoğraf',
        items: photos,
        gutter: 0,
        railW: 210,
        railH: 150,
        minCell: 150,
        builder: (final url, final w) {
          final int i = photos.indexOf(url);
          return Reveal(
            index: i.clamp(0, 8),
            child: PressScale(
              onTap: () => GalleryViewerDialog.open(
                context,
                photos,
                initialIndex: i < 0 ? 0 : i,
              ),
              semanticLabel: 'Galeri fotoğrafı ${i + 1} / ${photos.length}',
              child: SkImage(
                  url: url,
                  width: w,
                  height: 150,
                  radius: AppRadius.md + 4),
            ),
          );
        },
      );
}
