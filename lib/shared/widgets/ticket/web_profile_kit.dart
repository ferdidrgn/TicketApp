import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/shows/domain/entities/show.dart';
import '../../../features/shows/presentation/widgets/detail/sticky_aside.dart';
import '../../navigation/widgets/nav_handler.dart';
import '../../navigation/widgets/web_site_header.dart';
import '../footers/web_mega_footer.dart';
import '../gallery_section.dart';
import '../sahne/sahne_kit.dart';

/// WEB PROFİL KİTİ — sahne ve topluluk (ve istenirse benzeri) web sayfalarının
/// ortak "program ve bilet" iskeleti: solda yapışkan künye bileti, sağda kayan
/// program, kaydırınca beliren bölüm çubuğu (scroll-spy), altta mega footer.
/// Oyun ve oyuncu web sayfalarının dili; mobil sayfalara dokunmaz.

typedef WebProfileBuilder = Widget Function(
  BuildContext context,
  List<GlobalKey> keys,
  AnimationController entrance,
);

/// Sayfa iskeleti: kendi [Scaffold]'u + [WebSiteHeader]. [ready] false iken
/// [placeholder] gösterilir (yükleme / hata); true olunca künye ve program çizilir.
class WebProfileFrame extends StatefulWidget {
  final String barTitle;
  final String? backdropUrl;
  final List<String> labels;
  final bool ready;
  final Widget? placeholder;
  final WebProfileBuilder aside;
  final WebProfileBuilder program;

  const WebProfileFrame({
    super.key,
    required this.barTitle,
    required this.labels,
    required this.ready,
    required this.aside,
    required this.program,
    this.backdropUrl,
    this.placeholder,
  });

  @override
  State<WebProfileFrame> createState() => _WebProfileFrameState();
}

class _WebProfileFrameState extends State<WebProfileFrame>
    with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _rowKey = GlobalKey();
  late final AnimationController _entrance = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));
  List<GlobalKey> _keys = const [];
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

  void _syncKeys() {
    if (_keys.length != widget.labels.length) {
      _keys = List.generate(widget.labels.length, (_) => GlobalKey());
    }
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
    if (i >= _keys.length) return;
    final BuildContext? c = _keys[i].currentContext;
    if (c == null) return;
    HapticFeedback.selectionClick();
    Scrollable.ensureVisible(c,
        duration: Sk.reduceMotion(context)
            ? Duration.zero
            : const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        alignment: 0.04);
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    _syncKeys();
    if (widget.ready && !_started) {
      _started = true;
      _entrance.forward();
    }

    Widget body;
    if (!widget.ready) {
      body = widget.placeholder ?? const SizedBox(height: 480);
    } else {
      body = LayoutBuilder(builder: (final context, final box) {
        final double w = box.maxWidth;
        final bool desktop = w >= 1100;
        final double gutter = w >= 1200 ? 56 : (w >= 768 ? 36 : 18);
        final Widget card = widget.aside(context, _keys, _entrance);
        final Widget program = widget.program(context, _keys, _entrance);
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
                      const SizedBox(height: AppSpacing.huge),
                      program,
                    ]),
            ),
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(children: [
        if (widget.ready && (widget.backdropUrl ?? '').isNotEmpty)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AmbientBackdrop(
                url: widget.backdropUrl!, height: 980, blur: 60, opacity: 0.4),
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
        if (widget.ready)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _SectionBar(
                visible: _showBar,
                title: widget.barTitle,
                labels: widget.labels,
                active: _active,
                onTab: _goTo),
          ),
      ]),
    );
  }
}

class _SectionBar extends StatelessWidget {
  final bool visible;
  final String title;
  final List<String> labels;
  final int active;
  final ValueChanged<int> onTab;
  const _SectionBar(
      {required this.visible,
      required this.title,
      required this.labels,
      required this.active,
      required this.onTab});

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
                      for (int i = 0; i < labels.length; i++)
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Semantics(
                            button: true,
                            label: labels[i],
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onTab(i),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: AnimatedDefaultTextStyle(
                                  duration: AppMotion.fast,
                                  style: Sk.ui(context,
                                      size: 14.5,
                                      color: active == i
                                          ? cs.primary
                                          : cs.onSurfaceVariant,
                                      weight: FontWeight.w800),
                                  child: Text(labels[i]),
                                ),
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
// PROGRAM PARÇALARI
// ═════════════════════════════════════════════════════════════════════════════

/// Ekmek kırıntısı: "Ana Sayfa > Sahneler".
class WebCrumbs extends StatelessWidget {
  final String current;
  const WebCrumbs({super.key, required this.current});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(children: [
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => NavigationHandler.goToHome(context),
          child: Text('Ana Sayfa',
              style: Sk.ui(context,
                  size: 13, color: cs.primary, weight: FontWeight.w700)),
        ),
      ),
      Icon(Icons.chevron_right_rounded, size: 16, color: cs.onSurfaceVariant),
      Text(current,
          style: Sk.ui(context,
              size: 13, color: cs.onSurfaceVariant, weight: FontWeight.w700)),
    ]);
  }
}

/// Kelime kelime yükselen büyük başlık.
class WebWordTitle extends StatelessWidget {
  final String text;
  final AnimationController entrance;
  const WebWordTitle({super.key, required this.text, required this.entrance});

  @override
  Widget build(final BuildContext context) {
    final List<String> words =
        text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final bool reduce = Sk.reduceMotion(context);
    final double w = MediaQuery.sizeOf(context).width;
    final double size = w >= 1100 ? 72 : (w >= 700 ? 56 : 38);
    return Semantics(
      header: true,
      label: text,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: entrance,
          builder: (final context, _) => Wrap(
            spacing: size * 0.24,
            children: [
              for (int i = 0; i < words.length; i++)
                () {
                  final double start = (0.15 + i * 0.12).clamp(0.0, 0.7);
                  final double v = reduce
                      ? 1
                      : Curves.easeOutCubic.transform(
                          ((entrance.value - start) / (1 - start))
                              .clamp(0.0, 1.0));
                  return ClipRect(
                    child: Opacity(
                      opacity: v,
                      child: Transform.translate(
                        offset: Offset(0, (1 - v) * 40),
                        child: Text(words[i],
                            style: Sk.display(context, size: size, height: 1.04)),
                      ),
                    ),
                  );
                }(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Anahtarlı program bölümü (scroll-spy hedefi).
class WebSection extends StatelessWidget {
  final GlobalKey sectionKey;
  final String title;
  final String? subtitle;
  final Widget child;
  const WebSection({
    super.key,
    required this.sectionKey,
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(final BuildContext context) => KeyedSubtree(
        key: sectionKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkSectionHead(title: title, subtitle: subtitle),
            const SizedBox(height: 26),
            child,
          ],
        ),
      );
}

/// Hakkında metni: büyük baş harf, uzunsa "Devamını oku".
class WebBio extends StatefulWidget {
  final String text;
  const WebBio({super.key, required this.text});

  @override
  State<WebBio> createState() => _WebBioState();
}

class _WebBioState extends State<WebBio> {
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
                            size: MediaQuery.sizeOf(context).width < 700 ? 64 : 92,
                            height: 0.86,
                            color: cs.primary)),
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

/// Sessiz not: boş durum cümlesi + isteğe bağlı eylem.
class WebQuietNote extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  const WebQuietNote(
      {super.key, required this.text, this.actionLabel, this.onAction});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Text(text,
            style: Sk.ui(context,
                size: 15.5,
                height: 1.55,
                color: cs.onSurfaceVariant,
                weight: FontWeight.w500)),
      ),
      if (actionLabel != null && onAction != null)
        TextButton(onPressed: onAction, child: Text(actionLabel!)),
    ]);
  }
}

/// Tıklanabilir bilgi satırı (adres, telefon…): üzerine gelince dolar.
class WebInfoRow extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final IconData? trailing;
  final VoidCallback? onTap;
  const WebInfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  State<WebInfoRow> createState() => _WebInfoRowState();
}

class _WebInfoRowState extends State<WebInfoRow> {
  bool _hover = false;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool tappable = widget.onTap != null;
    final Widget row = AnimatedContainer(
      duration: AppMotion.fast,
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _hover && tappable
            ? cs.surfaceContainerHigh
            : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: cs.primaryContainer, shape: BoxShape.circle),
          child: Icon(widget.icon, size: 21, color: cs.onPrimaryContainer),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title,
                    style: Sk.ui(context,
                        size: 16, weight: FontWeight.w800, height: 1.3)),
                const SizedBox(height: 2),
                Text(widget.subtitle,
                    style: Sk.ui(context,
                        size: 13.5,
                        color: cs.onSurfaceVariant,
                        weight: FontWeight.w600)),
              ]),
        ),
        if (widget.trailing != null && tappable)
          Icon(widget.trailing, color: cs.primary),
      ]),
    );
    if (!tappable) return row;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: PressScale(
        onTap: widget.onTap,
        semanticLabel: '${widget.title}, ${widget.subtitle}',
        child: row,
      ),
    );
  }
}

/// Afiş rayı: hafif eğik afişler, üzerine gelince düzelip yükselir.
class WebPosterRail extends StatelessWidget {
  final List<Show> shows;
  final String heroSource;
  const WebPosterRail({super.key, required this.shows, this.heroSource = 'web'});

  @override
  Widget build(final BuildContext context) => SizedBox(
        height: 410,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          itemCount: shows.length,
          separatorBuilder: (_, __) => const SizedBox(width: 30),
          itemBuilder: (final context, final i) =>
              _PosterCard(show: shows[i], index: i),
        ),
      );
}

class _PosterCard extends StatefulWidget {
  final Show show;
  final int index;
  const _PosterCard({required this.show, required this.index});

  @override
  State<_PosterCard> createState() => _PosterCardState();
}

class _PosterCardState extends State<_PosterCard> {
  bool _hover = false;

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double rot = (widget.index.isEven ? -1 : 1) * 0.035;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: PressScale(
        semanticLabel: '${widget.show.name} oyununu aç',
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
                    boxShadow:
                        skSoftShadow(context, strength: _hover ? 1.3 : 0.8),
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

/// Geçmiş oyunlar: soluk afişlerden ızgara.
class WebPastGrid extends StatelessWidget {
  final List<Show> shows;
  const WebPastGrid({super.key, required this.shows});

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
              child: PressScale(
                semanticLabel: '${s.name} oyununu aç',
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

/// Galeri: farklı oranlı kareler, hover'da yakınlaşır, tıklayınca büyür.
class WebGallery extends StatelessWidget {
  final List<String> photos;
  const WebGallery({super.key, required this.photos});

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
                    onTap: () => GalleryViewerDialog.open(context, photos,
                        initialIndex: i),
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
        child: PressScale(
          semanticLabel: 'Fotoğrafı büyüt',
          onTap: widget.onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: widget.ratio,
              child: AnimatedScale(
                scale: _hover ? 1.06 : 1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: SkImage(url: widget.url),
              ),
            ),
          ),
        ),
      );
}

/// Künye görseli: fare üstünde 3B eğilir, boşta çok yavaş yakınlaşır.
class WebTiltImage extends StatefulWidget {
  final String url;
  final double aspectRatio;
  final double topRadius;
  final IconData fallbackIcon;
  final Alignment alignment;
  const WebTiltImage({
    super.key,
    required this.url,
    this.aspectRatio = 4 / 5,
    this.topRadius = 18,
    this.fallbackIcon = Icons.theater_comedy_rounded,
    this.alignment = Alignment.center,
  });

  @override
  State<WebTiltImage> createState() => _WebTiltImageState();
}

class _WebTiltImageState extends State<WebTiltImage>
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
          duration: AppMotion.fast,
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
            borderRadius: BorderRadius.vertical(
                top: Radius.circular(widget.topRadius),
                bottom: const Radius.circular(18)),
            child: AspectRatio(
              aspectRatio: widget.aspectRatio,
              child: AnimatedBuilder(
                animation: _drift,
                builder: (_, final child) => Transform.scale(
                    scale: 1.0 + 0.05 * _drift.value, child: child),
                child: SkImage(
                    url: widget.url,
                    alignment: widget.alignment,
                    fallbackIcon: widget.fallbackIcon),
              ),
            ),
          ),
        ),
      );
}

/// Künye bileti için giriş: aşağıdan yükselip hafif döner.
class WebTicketEntrance extends StatelessWidget {
  final AnimationController entrance;
  final Widget child;
  const WebTicketEntrance(
      {super.key, required this.entrance, required this.child});

  @override
  Widget build(final BuildContext context) {
    final bool reduce = Sk.reduceMotion(context);
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
      child: child,
    );
  }
}

/// Yükleme iskeleti (spinner yerine).
class WebProfileSkeleton extends StatelessWidget {
  const WebProfileSkeleton({super.key});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 1000),
            child: const Column(children: [
              SkBone(height: 56, radius: 14),
              SizedBox(height: 18),
              SkBone(height: 20, radius: 8),
              SizedBox(height: 10),
              SkBone(height: 20, radius: 8),
              SizedBox(height: 40),
              SkBone(height: 260, radius: 22),
            ]),
          ),
        ),
      );
}

/// Hata / bulunamadı durumu.
class WebProfileError extends StatelessWidget {
  final String title;
  final VoidCallback onRetry;
  const WebProfileError({super.key, required this.title, required this.onRetry});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 24),
        child: Center(
          child: SkEmpty(
            icon: Icons.cloud_off_rounded,
            title: title,
            message: 'Bağlantını kontrol edip tekrar dene.',
            actionLabel: 'Tekrar dene',
            onAction: onRetry,
          ),
        ),
      );
}
