import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/util/browse_memory.dart';
import '../../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../../shared/widgets/ticket/stage_entrance.dart';
import '../../../../campaigns/domain/entities/campaign.dart';
import '../../../../players/domain/entities/player.dart';
import '../../../../players/presentation/providers/player_provider.dart';
import '../../../../shows/domain/entities/show.dart';
import '../../../../users/presentation/providers/user_provider.dart';
import '../../providers/home_sessions_provider.dart';

// ═════════════════════════════════════════════════════════════════════════
// Ana sayfa vitrini — bilet dilinin dışında, ferah ve fotoğraf odaklı
// bölümler. Hepsi GERÇEK veriden (kampanyalar, sahnedeki oyunlar,
// seanslar, oyuncular); uydurma içerik yok. Renkler temadan; fotoğraf
// üstündeki metin her temada okunsun diye fotoğraf karartması sabit siyah.
// ═════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────
// 1. Hareketli vitrin (kampanyalar + sahnedeki oyunlar)
// ─────────────────────────────────────────────────────────────────────────

class HomeSlide {
  final String imageUrl;
  final String kicker;
  final String title;
  final String? subtitle;
  final String action;
  final VoidCallback onTap;

  const HomeSlide({
    required this.imageUrl,
    required this.kicker,
    required this.title,
    required this.action,
    required this.onTap,
    this.subtitle,
  });

  /// Kampanyalar önce, ardından sahnedeki oyunlar (sahne fotoğrafı varsa o,
  /// yoksa afiş). En fazla [max] slayt.
  static List<HomeSlide> build(
    final BuildContext context, {
    required final List<Campaign> campaigns,
    required final List<Show> shows,
    required final void Function(Show) onShow,
    final int max = 6,
  }) {
    final slides = <HomeSlide>[];
    for (int i = 0; i < campaigns.length; i++) {
      final c = campaigns[i];
      if (c.imageUrl.trim().isEmpty) continue;
      slides.add(HomeSlide(
        imageUrl: c.imageUrl,
        kicker: 'KAMPANYA',
        title: c.title,
        action: 'Kampanyayı gör',
        onTap: () => NavigationHandler.goToCampaigns(context, index: i),
      ));
    }
    for (final s in shows) {
      if (slides.length >= max) break;
      final String img = s.photosShowId.isNotEmpty
          ? s.photosShowId.first
          : s.imageUrl;
      if (img.trim().isEmpty) continue;
      final String kind = s.category.trim();
      slides.add(HomeSlide(
        imageUrl: img,
        kicker: s.hasExternalTicketing ? 'BAŞKA PLATFORMDA' : 'SAHNEDE',
        title: s.name,
        subtitle: [
          if (kind.isNotEmpty) kind,
          if (s.duration.trim().isNotEmpty) s.duration.trim(),
        ].join('  ·  '),
        action: 'Oyunu incele',
        onTap: () => onShow(s),
      ));
    }
    return slides.take(max).toList();
  }
}

/// Otomatik kayan, dokununca duran vitrin. Alttaki gösterge: etkin slaytın
/// noktası uzar ve süre doldukça içi dolar (bir sonraki slayda ne kadar
/// kaldığı görünür). Kaydırılan slaytın fotoğrafı hafif paralaksla kayar.
/// Azaltılmış harekette otomatik geçiş yok.
class HomeSpotlightCarousel extends StatefulWidget {
  final List<HomeSlide> slides;
  final double height;
  final EdgeInsets padding;

  const HomeSpotlightCarousel({
    super.key,
    required this.slides,
    this.height = 220,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
  });

  @override
  State<HomeSpotlightCarousel> createState() => _HomeSpotlightCarouselState();
}

class _HomeSpotlightCarouselState extends State<HomeSpotlightCarousel>
    with SingleTickerProviderStateMixin {
  static const Duration _dwell = Duration(seconds: 5);

  final PageController _page = PageController();
  late final AnimationController _progress =
      AnimationController(vsync: this, duration: _dwell)
        ..addStatusListener((final s) {
          if (s == AnimationStatus.completed) _next();
        });
  int _index = 0;
  bool _auto = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _auto = !MediaQuery.of(context).disableAnimations;
    if (_auto && widget.slides.length > 1 && !_progress.isAnimating) {
      _progress.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _page.dispose();
    super.dispose();
  }

  void _next() {
    if (!mounted || widget.slides.length < 2 || !_page.hasClients) return;
    final int to = (_index + 1) % widget.slides.length;
    if (to == 0) {
      _page.jumpToPage(0);
    } else {
      _page.animateToPage(to,
          duration: AppMotion.slow, curve: AppMotion.dramatic);
    }
  }

  void _onPage(final int i) {
    setState(() => _index = i);
    if (_auto && widget.slides.length > 1) _progress.forward(from: 0);
  }

  @override
  Widget build(final BuildContext context) {
    final slides = widget.slides;
    if (slides.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: widget.height,
          child: Listener(
            // Parmak değince otomatik geçiş durur, bırakınca sürer.
            onPointerDown: (final _) => _progress.stop(),
            onPointerUp: (final _) {
              if (_auto && slides.length > 1) _progress.forward();
            },
            child: PageView.builder(
              controller: _page,
              onPageChanged: _onPage,
              itemCount: slides.length,
              itemBuilder: (final context, final i) => Padding(
                padding: widget.padding,
                child: AnimatedBuilder(
                  animation: _page,
                  builder: (final context, final child) {
                    double delta = 0;
                    if (_page.hasClients && _page.position.haveDimensions) {
                      delta = (_page.page ?? 0) - i;
                    }
                    return _SlideCard(
                      slide: slides[i],
                      parallax: delta.clamp(-1.0, 1.0),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        if (slides.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          Center(
            child: AnimatedBuilder(
              animation: _progress,
              builder: (final context, final _) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < slides.length; i++)
                    GestureDetector(
                      onTap: () => _page.animateToPage(i,
                          duration: AppMotion.normal,
                          curve: AppMotion.standard),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3, vertical: AppSpacing.sm),
                        child: AnimatedContainer(
                          duration: AppMotion.fast,
                          width: i == _index ? 28 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: cs.outlineVariant,
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                          alignment: Alignment.centerLeft,
                          child: i == _index
                              ? FractionallySizedBox(
                                  widthFactor:
                                      _auto ? _progress.value.clamp(0.15, 1.0) : 1,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: cs.primary,
                                      borderRadius: BorderRadius.circular(
                                          AppRadius.pill),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SlideCard extends StatelessWidget {
  final HomeSlide slide;
  final double parallax;
  const _SlideCard({required this.slide, required this.parallax});

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '${slide.kicker.toLowerCase()}: ${slide.title}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.level3(cs.shadow),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Material(
            color: Colors.black,
            child: InkWell(
              onTap: slide.onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Paralaks: kaydırılırken fotoğraf karttan biraz yavaş kayar.
                  Transform.translate(
                    offset: Offset(parallax * 40, 0),
                    child: Transform.scale(
                      scale: 1.15,
                      child: OptimizedCachedImage(
                        imageUrl: slide.imageUrl,
                        fit: BoxFit.cover,
                        borderRadius: 0,
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [Color(0x33FFFFFF), Color(0x00000000)],
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0.35, 1],
                        colors: [Color(0x00000000), Color(0xD9000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom: AppSpacing.lg,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 3),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            slide.kicker,
                            style: TextStyle(
                              color: cs.onPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          slide.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        if ((slide.subtitle ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            slide.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xCCFFFFFF), fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              slide.action,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: Colors.white, size: 18),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 2. Selamlama (saate göre, kullanıcının adıyla)
// ─────────────────────────────────────────────────────────────────────────

class HomeGreeting extends ConsumerWidget {
  const HomeGreeting({super.key});

  static String _part(final int h) {
    if (h >= 5 && h < 12) return 'Günaydın';
    if (h >= 12 && h < 18) return 'İyi günler';
    if (h >= 18 && h < 23) return 'İyi akşamlar';
    return 'İyi geceler';
  }

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final String? name =
        ref.watch(userProfileProvider).value?.firstName.trim();
    final String hello = _part(DateTime.now().hour);
    return Text(
      (name == null || name.isEmpty) ? hello : '$hello, $name',
      style: TextStyle(
        color: cs.onSurfaceVariant,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 3. Bu hafta — gerçek seanslardan tek satırlık nabız
// ─────────────────────────────────────────────────────────────────────────

class HomeWeekPulse extends StatelessWidget {
  final List<HomeSession> sessions;
  final VoidCallback onTap;
  const HomeWeekPulse({super.key, required this.sessions, required this.onTap});

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final week = sessions
        .where((final s) =>
            s.date.isAfter(now) &&
            s.day.isBefore(today.add(const Duration(days: 7))))
        .toList();
    if (week.isEmpty) return const SizedBox.shrink();
    final tonight = week.where((final s) => s.day == today).length;
    final stages = week
        .map((final s) => s.stage?.id ?? s.event.stageId)
        .where((final id) => id.isNotEmpty)
        .toSet()
        .length;
    final String title = tonight > 0
        ? 'Bu akşam $tonight seans var'
        : 'Bu hafta ${week.length} seans var';
    final String detail = stages > 1
        ? '$stages farklı sahnede. Yerini erkenden ayır.'
        : 'Yerini erkenden ayır.';

    return Semantics(
      button: true,
      label: '$title. $detail',
      excludeSemantics: true,
      child: Material(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                _Pulse(color: cs.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                            color: cs.onSecondaryContainer,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          )),
                      Text(detail,
                          style: TextStyle(
                              color: cs.onSecondaryContainer
                                  .withValues(alpha: 0.8),
                              fontSize: 12.5)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: cs.onSecondaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Son bakılan oyuna tek dokunuşla dönüş — gerçek id, uydurma öneri yok.
class HomeContinueTicket extends StatefulWidget {
  final List<Show> shows;
  final EdgeInsets padding;
  const HomeContinueTicket(
      {super.key, required this.shows, required this.padding});

  @override
  State<HomeContinueTicket> createState() => _HomeContinueTicketState();
}

class _HomeContinueTicketState extends State<HomeContinueTicket> {
  String? _id;
  String? _name;

  @override
  void initState() {
    super.initState();
    BrowseMemory.lastShow().then((final pair) {
      if (!mounted || pair == null) return;
      setState(() {
        _id = pair.$1;
        _name = pair.$2;
      });
    });
  }

  @override
  Widget build(final BuildContext context) {
    final String? id = _id;
    if (id == null) return const SizedBox.shrink();
    Show? match;
    for (final s in widget.shows) {
      if (s.id == id) {
        match = s;
        break;
      }
    }
    final String title = (match?.name ?? _name ?? '').trim();
    if (title.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: widget.padding,
      child: Semantics(
        button: true,
        label: 'Kaldığın yer: $title',
        excludeSemantics: true,
        child: Material(
          color: cs.surfaceContainerHigh,
          elevation: 0,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            onTap: () => NavigationHandler.goToShow(context, id, title),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    child: SizedBox(
                      width: 44,
                      height: 64,
                      child: match == null
                          ? ColoredBox(color: cs.primary.withValues(alpha: 0.2))
                          : OptimizedCachedImage(
                              imageUrl: match.imageUrl,
                              fit: BoxFit.cover,
                              borderRadius: 0,
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kaldığın yerden devam',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            color: cs.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.play_arrow_rounded, color: cs.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pulse extends StatefulWidget {
  final Color color;
  const _Pulse({required this.color});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MediaQuery.of(context).disableAnimations && !_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => SizedBox(
        width: 22,
        height: 22,
        child: AnimatedBuilder(
          animation: _c,
          builder: (final context, final _) => CustomPaint(
            painter: _PulsePainter(widget.color, _c.value),
          ),
        ),
      );
}

class _PulsePainter extends CustomPainter {
  final Color color;
  final double t;
  const _PulsePainter(this.color, this.t);

  @override
  void paint(final Canvas canvas, final Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(
        c,
        4 + t * 7,
        Paint()
          ..color = color.withValues(alpha: (1 - t) * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.drawCircle(c, 4.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant final _PulsePainter old) =>
      old.t != t || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────
// 4. Ruh hâline göre — sahnedeki oyunların gerçek türlerinden
// ─────────────────────────────────────────────────────────────────────────

class HomeMoodPicker extends StatefulWidget {
  final List<Show> shows;
  final EdgeInsets padding;
  final String? selected;
  final ValueChanged<String?> onSelected;
  const HomeMoodPicker({
    super.key,
    required this.shows,
    required this.padding,
    required this.selected,
    required this.onSelected,
  });

  @override
  State<HomeMoodPicker> createState() => _HomeMoodPickerState();
}

class _HomeMoodPickerState extends State<HomeMoodPicker> {
  static const Map<String, (String, IconData)> _moods = {
    'komedi': ('Kahkaha atmak', Icons.sentiment_very_satisfied_rounded),
    'dram': ('Derinden etkilenmek', Icons.water_drop_outlined),
    'müzikal': ('Müzikle coşmak', Icons.music_note_rounded),
    'çocuk': ('Ailece izlemek', Icons.family_restroom_rounded),
    'klasik': ('Klasiklere dönmek', Icons.auto_stories_outlined),
    'deneysel': ('Şaşırmak', Icons.bubble_chart_outlined),
    'trajedi': ('Sarsılmak', Icons.theater_comedy_outlined),
  };

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Map<String, int> counts = {};
    for (final s in widget.shows) {
      final c = s.category.trim();
      if (c.isNotEmpty) counts[c] = (counts[c] ?? 0) + 1;
    }
    if (counts.length < 2) return const SizedBox.shrink();
    final cats = counts.keys.toList()
      ..sort((final a, final b) => counts[b]!.compareTo(counts[a]!));

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: widget.padding,
        itemCount: cats.length,
        separatorBuilder: (final _, final __) =>
            const SizedBox(width: AppSpacing.md),
        itemBuilder: (final context, final i) {
          final String cat = cats[i];
          final mood = _moods[cat.toLowerCase()];
          // Her türe temadan türeyen farklı bir ton.
          final List<Color> tones = [
            cs.primaryContainer,
            cs.tertiaryContainer,
            cs.secondaryContainer,
          ];
          final List<Color> inks = [
            cs.onPrimaryContainer,
            cs.onTertiaryContainer,
            cs.onSecondaryContainer,
          ];
          final bool on = widget.selected == cat;
          final Color bg = on ? cs.primary : tones[i % 3];
          final Color ink = on ? cs.onPrimary : inks[i % 3];
          return Semantics(
            button: true,
            selected: on,
            label: '${mood?.$1 ?? cat}: $cat, ${counts[cat]} oyun',
            excludeSemantics: true,
            child: Material(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onSelected(on ? null : cat);
                },
                onLongPress: () =>
                    NavigationHandler.goToDiscoverWithCategory(context, cat),
                child: SizedBox(
                  width: 148,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(mood?.$2 ?? Icons.local_activity_outlined,
                            color: ink, size: 24),
                        const Spacer(),
                        Text(
                          mood?.$1 ?? cat,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$cat · ${counts[cat]} oyun',
                          style: TextStyle(
                              color: ink.withValues(alpha: 0.75),
                              fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 5. Sinematik afiş kartı (bilet değil): afiş tam kart, alt kısımda ad
// ─────────────────────────────────────────────────────────────────────────

class HomePosterCard extends StatefulWidget {
  final Show show;
  final VoidCallback onTap;
  const HomePosterCard({super.key, required this.show, required this.onTap});

  @override
  State<HomePosterCard> createState() => _HomePosterCardState();
}

class _HomePosterCardState extends State<HomePosterCard> {
  bool _pressed = false;

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Show show = widget.show;
    final String kind = show.hasExternalTicketing
        ? 'Başka platformda'
        : show.category.trim();
    return Semantics(
      button: true,
      label: show.name,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AnimatedScale(
              scale: _pressed ? 0.96 : 1,
              duration: const Duration(milliseconds: 420),
              curve: _pressed ? Curves.easeOut : Curves.elasticOut,
              child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.standard,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: const Color(0x40FFFFFF),
                  width: 1,
                ),
                boxShadow: AppShadows.poster(cs.shadow, lifted: !_pressed),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: Material(
                  color: cs.surfaceContainerHighest,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onTap();
                    },
                    onHighlightChanged: (final v) =>
                        setState(() => _pressed = v),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        StageHero(
                          tag: 'show_${show.id}',
                          child: OptimizedCachedImage(
                            imageUrl: show.imageUrl,
                            fit: BoxFit.cover,
                            borderRadius: 0,
                          ),
                        ),
                        const IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.center,
                                colors: [
                                  Color(0x33FFFFFF),
                                  Color(0x00000000),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (show.isRecentlyAdded)
                          Positioned(
                            top: AppSpacing.sm,
                            left: AppSpacing.sm,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text('Yeni',
                                  style: TextStyle(
                                    color: cs.onPrimaryContainer,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  )),
                            ),
                          ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: [0, 0.42, 1],
                                  colors: [
                                    Color(0x00000000),
                                    Color(0x8C000000),
                                    Color(0xE6000000),
                                  ],
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    14, 40, 14, 14),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(
                                      width: 22,
                                      height: 1.5,
                                      child: ColoredBox(
                                          color: Color(0xD9FFFFFF)),
                                    ),
                                    const SizedBox(height: 8),
                                    if (kind.isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 3),
                                        child: Text(
                                          kind,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Color(0xF2FFFFFF),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.15,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      show.name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.playfairDisplay(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        height: 1.05,
                                        shadows: const [
                                          Shadow(
                                            color: Color(0x99000000),
                                            blurRadius: 12,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 6. Günün repliği — kart değil, sayfaya nefes aldıran tipografi
// ─────────────────────────────────────────────────────────────────────────

class HomeQuoteOfDay extends StatelessWidget {
  const HomeQuoteOfDay({super.key});

  /// Telif sorunu olmayan klasik (Shakespeare) replikler; gün değiştikçe
  /// sırayla döner.
  static const List<(String, String)> _lines = [
    ('Bütün dünya bir sahnedir; bütün kadınlar ve erkekler yalnızca oyuncu.',
        'Shakespeare, Size Nasıl Geliyorsa'),
    ('Olmak ya da olmamak, işte bütün mesele bu.', 'Shakespeare, Hamlet'),
    ('Biz rüyaların yapıldığı kumaştanız.', 'Shakespeare, Fırtına'),
    ('Az konuşan, çok iş görür.', 'Shakespeare, V. Henry'),
    ('Her şeyin sonu iyi biterse, her şey iyidir.',
        'Shakespeare, Sonu İyi Biten Her Şey İyidir'),
    ('Aşk gözle değil, gönülle bakar.', 'Shakespeare, Bir Yaz Gecesi Rüyası'),
    ('Hayat yürüyen bir gölgeden, sahnede bir saat çalım satan zavallı bir '
        'oyuncudan başka nedir ki?', 'Shakespeare, Macbeth'),
  ];

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final int day = now.difference(DateTime(now.year)).inDays;
    final (String line, String source) = _lines[day % _lines.length];
    return Semantics(
      label: 'Günün repliği: $line — $source',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“',
            style: GoogleFonts.playfairDisplay(
              color: cs.primary,
              fontSize: 64,
              height: 0.8,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            line,
            style: GoogleFonts.playfairDisplay(
              color: cs.onSurface,
              fontSize: 22,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(width: 24, height: 1.5, color: cs.primary),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  'Günün repliği · $source',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// 7. Oyuncu hikâyeleri — hikâye biçiminde yuvarlak portreler
// ─────────────────────────────────────────────────────────────────────────

class HomePlayerStories extends ConsumerWidget {
  final EdgeInsets padding;
  const HomePlayerStories({super.key, required this.padding});

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final List<Player> players = (ref.watch(playersProvider()).value ??
            const <Player>[])
        .where((final p) => p.firstName.trim().isNotEmpty)
        .take(14)
        .toList();
    if (players.isEmpty) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: players.length,
        separatorBuilder: (final _, final __) =>
            const SizedBox(width: AppSpacing.lg),
        itemBuilder: (final context, final i) {
          final p = players[i];
          final String name = '${p.firstName} ${p.lastName}'.trim();
          final String initials = [
            if (p.firstName.isNotEmpty) p.firstName[0],
            if (p.lastName.isNotEmpty) p.lastName[0],
          ].join().toUpperCase();
          return Semantics(
            button: true,
            label: name,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => NavigationHandler.goToPlayer(context, p.id, name),
              child: SizedBox(
                width: 72,
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          transform: GradientRotation(i * math.pi / 5),
                          colors: [
                            cs.primary,
                            cs.tertiary,
                            cs.secondary,
                            cs.primary,
                          ],
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: cs.surface),
                        child: ClipOval(
                          child: ColoredBox(
                            color: cs.primaryContainer,
                            child: StageHero(
                              tag: 'player_${p.id}',
                              child: OptimizedCachedImage(
                                imageUrl: p.imageUrl,
                                fit: BoxFit.cover,
                                borderRadius: 0,
                                errorBuilder: (final _, final __, final ___) =>
                                    Center(
                                  child: Text(initials,
                                      style: TextStyle(
                                        color: cs.onPrimaryContainer,
                                        fontWeight: FontWeight.w800,
                                      )),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.firstName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Yakınımdakiler daveti — GPS uydurulmaz; gerçek konum sayfasında istenir
// ─────────────────────────────────────────────────────────────────────────

/// Ana sayfadan Yakınımdakiler'e tek dokunuş. Konum izni burada sorulmaz.
class HomeNearbyInvite extends StatelessWidget {
  const HomeNearbyInvite({super.key});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: 'Yakınımdakiler: çevrendeki sahneler ve seanslar',
      excludeSemantics: true,
      child: Material(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            NavigationHandler.goToNearby(context);
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(Icons.map_outlined,
                        color: cs.onPrimaryContainer),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yakınımdakiler',
                          style: GoogleFonts.playfairDisplay(
                            color: cs.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '50 km içindeki sahneler ve önümüzdeki seanslar. Konum izni haritada sorulur.',
                          style: TextStyle(
                            color: cs.onSurfaceVariant,
                            fontSize: 13.5,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: cs.primary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Afiş duvarı: solda/üstte bir büyük afiş, yanında gerçek sıradaki
/// oyunlar. Boş kenar yok; veri yoksa bölüm çizilmez.
class HomePlaybillBoard extends StatelessWidget {
  final List<Show> shows;
  final ValueChanged<Show> onOpen;
  final EdgeInsets padding;

  const HomePlaybillBoard({
    super.key,
    required this.shows,
    required this.onOpen,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(final BuildContext context) {
    final List<Show> items =
        shows.where((final s) => s.imageUrl.trim().isNotEmpty).take(5).toList();
    if (items.length < 3) return const SizedBox.shrink();
    return Padding(
      padding: padding.copyWith(bottom: padding.bottom + 20),
      child: LayoutBuilder(
        builder: (final context, final c) {
          final bool wide = c.maxWidth >= 768;
          if (!wide) {
            return Column(
              children: [
                SizedBox(
                  height: 320,
                  child: HomePosterCard(
                    show: items.first,
                    onTap: () => onOpen(items.first),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  height: 210,
                  child: Row(
                    children: [
                      for (int i = 1; i < items.length && i < 3; i++) ...[
                        if (i > 1) const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: HomePosterCard(
                            show: items[i],
                            onTap: () => onOpen(items[i]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }
          return SizedBox(
            height: 460,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: HomePosterCard(
                    show: items.first,
                    onTap: () => onOpen(items.first),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      for (int i = 1; i < items.length; i++) ...[
                        if (i > 1) const SizedBox(height: AppSpacing.lg),
                        Expanded(
                          child: HomePosterCard(
                            show: items[i],
                            onTap: () => onOpen(items[i]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
