import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_shadows.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../shared/widgets/optimized_cached_image.dart';
import '../../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../../shows/domain/entities/show.dart';
import '../../providers/home_sessions_provider.dart';
import 'home_ui.dart';

/// Ana sayfanın "bilet dili" parçaları — giriş ekranındaki onaylı dilin
/// ana sayfadaki karşılığı, ama sadece ANLAM taşıdığı yerde:
///
/// * [HomeFeaturedTicket] — sıradaki gerçek seans, büyük bir giriş bileti
///   (gövde + delikli koçan). Birincil aksiyon koçandaki damga butonu;
///   basınca koçan yırtılır, sonra oyun sayfası açılır.
/// * [HomeSessionBoard] — yaklaşan seanslar: gün şeridi (temanın renkleriyle
///   takvim sekmeleri) + seçili günün seansları (her biri kağıt bir koçan).

String _lang(final BuildContext context) =>
    Localizations.localeOf(context).languageCode;

String _dayMonth(final BuildContext context, final DateTime d) =>
    DateFormat('d MMMM', _lang(context)).format(d);

String _weekdayShort(final BuildContext context, final DateTime d) =>
    DateFormat('EEE', _lang(context)).format(d);

String _weekdayLong(final BuildContext context, final DateTime d) =>
    DateFormat('EEEE', _lang(context)).format(d);

String _monthShort(final BuildContext context, final DateTime d) =>
    DateFormat('MMM', _lang(context)).format(d);

String _time(final DateTime d) => ticketTime(d);

bool _sameDay(final DateTime a, final DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "Bugün" / "Yarın" ya da kısa gün adı.
String _relativeDay(final BuildContext context, final DateTime day) {
  final now = DateTime.now();
  if (_sameDay(day, now)) return homeText(context, 'Bugün', 'Today');
  if (_sameDay(day, now.add(const Duration(days: 1))))
    return homeText(context, 'Yarın', 'Tomorrow');
  return _weekdayShort(context, day);
}

// ─────────────────────────────────────────────────────────────────────────
// Öne çıkan bilet
// ─────────────────────────────────────────────────────────────────────────

/// Öne çıkan biletin yerleşimi: [wide] geniş web (yatay bilet, büyük afiş),
/// [medium] tablet (yatay bilet, küçük afiş), [compact] telefon (dikey
/// bilet, koçan altta — damga butonu başparmak bölgesinde).
enum HomeTicketLayout { wide, medium, compact }

class HomeFeaturedTicket extends StatefulWidget {
  final HomeFeatured featured;
  final HomeTicketLayout layout;
  final VoidCallback onOpen;

  const HomeFeaturedTicket({
    super.key,
    required this.featured,
    required this.layout,
    required this.onOpen,
  });

  @override
  State<HomeFeaturedTicket> createState() => _HomeFeaturedTicketState();
}

class _HomeFeaturedTicketState extends State<HomeFeaturedTicket>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tear =
      AnimationController(vsync: this, duration: AppMotion.slow);
  late final Animation<double> _tearCurve =
      CurvedAnimation(parent: _tear, curve: Curves.easeInCubic);
  bool _busy = false;

  @override
  void dispose() {
    _tear.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    if (_busy) return;
    _busy = true;
    HapticFeedback.mediumImpact();
    // Koçan yırtılır → oyun sayfası. Ana sayfa sekmede canlı kaldığı için
    // (IndexedStack) geri dönüldüğünde koçan yerine takılı olsun diye geçiş
    // bittikten sonra sessizce sıfırlanır.
    if (!MediaQuery.of(context).disableAnimations)
      await _tear.forward(from: 0);
    if (!mounted) return;
    widget.onOpen();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      _tear.value = 0;
      _busy = false;
    });
  }

  @override
  Widget build(final BuildContext context) {
    final bool vertical = widget.layout == HomeTicketLayout.compact;
    final show = widget.featured.show;
    return Semantics(
      container: true,
      label: homeText(context, 'Öne çıkan bilet: ${show.name}',
          'Featured ticket: ${show.name}'),
      child: AdmitTicket(
        direction: vertical ? Axis.vertical : Axis.horizontal,
        tear: _tearCurve,
        stubExtent: widget.layout == HomeTicketLayout.wide ? 240 : 200,
        body: _FeaturedBody(
            featured: widget.featured, layout: widget.layout),
        stub: _FeaturedStub(
          featured: widget.featured,
          layout: widget.layout,
          onOpen: _open,
        ),
      ),
    );
  }
}

String _kindLabel(final BuildContext context, final HomeFeatured f) {
  if (f.session != null)
    return homeText(context, 'SIRADAKİ SEANS', 'NEXT PERFORMANCE');
  if (f.show.hasExternalTicketing)
    return homeText(context, 'BAŞKA PLATFORMDA', 'SOLD ELSEWHERE');
  return homeText(context, 'REPERTUVARDA', 'IN REPERTOIRE');
}

/// Bilet alanları — sadece gerçek veriden. Seans varsa TARİH/SAAT/SAHNE;
/// yoksa oyunun kendi bilgileri (tür, süre, yaş sınırı) — boş olan atlanır.
List<Widget> _fieldsOf(final BuildContext context, final HomeFeatured f) {
  final s = f.session;
  if (s != null)
    return [
      TicketField(
        label: homeText(context, 'TARİH', 'DATE'),
        value: '${_dayMonth(context, s.date)}, ${_weekdayShort(context, s.date)}',
      ),
      TicketField(label: homeText(context, 'SAAT', 'TIME'), value: _time(s.date)),
      if (s.stage != null && s.stage!.name.trim().isNotEmpty)
        TicketField(
            label: homeText(context, 'SAHNE', 'STAGE'), value: s.stage!.name),
    ];
  final show = f.show;
  return [
    if (show.category.trim().isNotEmpty)
      TicketField(
          label: homeText(context, 'TÜR', 'GENRE'), value: show.category.trim()),
    if (show.duration.trim().isNotEmpty)
      TicketField(
          label: homeText(context, 'SÜRE', 'LENGTH'),
          value: show.duration.trim()),
    if (show.ageLimit.trim().isNotEmpty)
      TicketField(
          label: homeText(context, 'YAŞ', 'AGE'), value: show.ageLimit.trim()),
  ];
}

class _FeaturedBody extends StatelessWidget {
  final HomeFeatured featured;
  final HomeTicketLayout layout;

  const _FeaturedBody({required this.featured, required this.layout});

  @override
  Widget build(final BuildContext context) {
    final show = featured.show;
    final fields = _fieldsOf(context, featured);

    final Widget name = Text(
      show.name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TicketInk.headline(switch (layout) {
        HomeTicketLayout.wide => 44,
        HomeTicketLayout.medium => 32,
        HomeTicketLayout.compact => 28,
      }),
    );

    final Widget fieldRow = fields.isEmpty
        ? const SizedBox.shrink()
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < fields.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.md),
                Expanded(child: fields[i]),
              ],
            ],
          );

    final Widget poster = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: ColoredBox(
        color: TicketInk.inkSoft(0.08),
        child: OptimizedCachedImage(
          imageUrl: show.imageUrl,
          fit: BoxFit.cover,
          borderRadius: 0,
        ),
      ),
    );

    if (layout == HomeTicketLayout.compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TicketHeaderStrip(kind: _kindLabel(context, featured)),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(height: 188, child: poster),
            const SizedBox(height: AppSpacing.lg),
            name,
            if (fields.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              fieldRow,
            ],
          ],
        ),
      );
    }

    final bool wide = layout == HomeTicketLayout.wide;
    final double posterW = wide ? 200 : 136;
    return Padding(
      padding: EdgeInsets.all(wide ? AppSpacing.xxxl : AppSpacing.xxl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: posterW, height: posterW * 4 / 3, child: poster),
          SizedBox(width: wide ? AppSpacing.xxxl : AppSpacing.xl),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                TicketHeaderStrip(kind: _kindLabel(context, featured)),
                SizedBox(height: wide ? AppSpacing.xxl : AppSpacing.lg),
                name,
                if (fields.isNotEmpty) ...[
                  SizedBox(height: wide ? AppSpacing.xxl : AppSpacing.lg),
                  fieldRow,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedStub extends StatelessWidget {
  final HomeFeatured featured;
  final HomeTicketLayout layout;
  final VoidCallback onOpen;

  const _FeaturedStub({
    required this.featured,
    required this.layout,
    required this.onOpen,
  });

  @override
  Widget build(final BuildContext context) {
    final show = featured.show;
    final session = featured.session;
    final bool hasSession = session != null;

    // Koçan bilgisi: gerçek fiyat varsa FİYAT, harici satışsa SATIŞ; ikisi
    // de yoksa sadece barkod (bilgi uydurulmaz).
    final String? price = session?.priceLabel;
    final Widget? info = price != null
        ? TicketField(label: homeText(context, 'FİYAT', 'PRICE'), value: price)
        : show.hasExternalTicketing
            ? TicketField(
                label: homeText(context, 'SATIŞ', 'SALES'),
                value: homeText(context, 'Başka platformda', 'Elsewhere'))
            : null;

    final String seed = session?.event.id ?? show.id;
    final Widget button = TicketStampButton(
      label: hasSession || show.hasExternalTicketing
          ? homeText(context, 'BİLET AL', 'GET TICKETS')
          : homeText(context, 'OYUNU İNCELE', 'SEE THE SHOW'),
      leading: Icon(show.hasExternalTicketing
          ? Icons.open_in_new_rounded
          : Icons.local_activity_outlined),
      onTap: onOpen,
    );

    if (layout == HomeTicketLayout.compact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: info ?? const SizedBox.shrink()),
                const SizedBox(width: AppSpacing.lg),
                SizedBox(
                  width: 104,
                  child: TicketBarcode(seed: seed, height: 36),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            button,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (info != null) info,
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: Center(
              child: TicketBarcode(
                seed: seed,
                direction: Axis.vertical,
                height: 48,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          button,
        ],
      ),
    );
  }
}

/// Öne çıkan biletin yükleniyor hâli — biletin kaba şeklinde parıltı.
class HomeFeaturedTicketSkeleton extends StatelessWidget {
  final HomeTicketLayout layout;
  const HomeFeaturedTicketSkeleton({super.key, required this.layout});

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        height: switch (layout) {
          HomeTicketLayout.wide => 330,
          HomeTicketLayout.medium => 250,
          HomeTicketLayout.compact => 520,
        },
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Yaklaşan seanslar panosu
// ─────────────────────────────────────────────────────────────────────────

/// Gün şeridi + seçili günün seansları. [columns] seans koçanlarının sütun
/// sayısı (telefon 1, tablet 2, masaüstü 3); [dayArrows] masaüstünde gün
/// şeridine ok butonları ekler. En fazla [maxDays] farklı gün gösterilir.
class HomeSessionBoard extends StatefulWidget {
  final List<HomeSession> sessions;
  final void Function(Show show) onOpenShow;
  final int columns;
  final bool dayArrows;
  final int maxDays;

  /// Gün şeridinin iç boşluğu (şerit ekran kenarına kadar akabilsin diye
  /// dışarıdan değil burada verilir).
  final EdgeInsetsGeometry stripPadding;

  /// Seans koçanlarının dış boşluğu.
  final EdgeInsetsGeometry listPadding;

  const HomeSessionBoard({
    super.key,
    required this.sessions,
    required this.onOpenShow,
    this.columns = 1,
    this.dayArrows = false,
    this.maxDays = 14,
    this.stripPadding = EdgeInsets.zero,
    this.listPadding = EdgeInsets.zero,
  });

  @override
  State<HomeSessionBoard> createState() => _HomeSessionBoardState();
}

class _HomeSessionBoardState extends State<HomeSessionBoard> {
  DateTime? _selectedDay;

  LinkedHashMap<DateTime, List<HomeSession>> _groupByDay() {
    final map = LinkedHashMap<DateTime, List<HomeSession>>();
    for (final s in widget.sessions) {
      final day = s.day;
      if (!map.containsKey(day) && map.length >= widget.maxDays) break;
      map.putIfAbsent(day, () => []).add(s);
    }
    return map;
  }

  @override
  Widget build(final BuildContext context) {
    final byDay = _groupByDay();
    if (byDay.isEmpty) return const SizedBox.shrink();
    final days = byDay.keys.toList();
    final DateTime selected =
        (_selectedDay != null && byDay.containsKey(_selectedDay))
            ? _selectedDay!
            : days.first;
    final daySessions = byDay[selected]!;
    final bool reduce = MediaQuery.of(context).disableAnimations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        HomeRail(
          height: 88,
          itemWidth: 72,
          gap: AppSpacing.sm,
          showArrows: widget.dayArrows,
          padding: widget.stripPadding,
          itemCount: days.length,
          itemBuilder: (final context, final i) => _DayTab(
            day: days[i],
            count: byDay[days[i]]!.length,
            selected: days[i] == selected,
            onTap: () => setState(() => _selectedDay = days[i]),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Padding(
          padding: widget.listPadding,
          child: AnimatedSwitcher(
            duration: reduce ? Duration.zero : AppMotion.fast,
            switchInCurve: AppMotion.standard,
            switchOutCurve: AppMotion.standard,
            layoutBuilder: (final current, final previous) => Stack(
              alignment: Alignment.topLeft,
              children: [...previous, if (current != null) current],
            ),
            child: SizedBox(
              key: ValueKey(selected),
              width: double.infinity,
              child: _SessionGrid(
                sessions: daySessions,
                columns: widget.columns,
                onOpenShow: widget.onOpenShow,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionGrid extends StatelessWidget {
  final List<HomeSession> sessions;
  final int columns;
  final void Function(Show show) onOpenShow;

  const _SessionGrid({
    required this.sessions,
    required this.columns,
    required this.onOpenShow,
  });

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
        builder: (final context, final constraints) {
          const double gap = AppSpacing.lg;
          final int cols = columns.clamp(1, 4);
          final double w =
              (constraints.maxWidth - gap * (cols - 1)) / cols;
          return Wrap(
            spacing: gap,
            runSpacing: AppSpacing.md,
            children: [
              for (final s in sessions)
                SizedBox(
                  width: w,
                  child: HomeSessionStub(
                    session: s,
                    onTap: () => onOpenShow(s.show),
                  ),
                ),
            ],
          );
        },
      );
}

/// Gün sekmesi — temanın renkleriyle küçük bir takvim yaprağı (kağıt değil:
/// bilet değil, sadece bir seçim). Seçili gün vurgu renginde.
class _DayTab extends StatefulWidget {
  final DateTime day;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _DayTab({
    required this.day,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_DayTab> createState() => _DayTabState();
}

class _DayTabState extends State<_DayTab> {
  bool _focused = false;

  @override
  Widget build(final BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bool sel = widget.selected;
    final Color bg = sel ? cs.primary : cs.surfaceContainerHigh;
    final Color fg = sel ? cs.onPrimary : cs.onSurface;
    final Color sub = sel ? cs.onPrimary.withOpacity(0.8) : cs.onSurfaceVariant;
    final String semantic = homeText(
      context,
      '${_dayMonth(context, widget.day)} ${_weekdayLong(context, widget.day)}, ${widget.count} seans',
      '${_weekdayLong(context, widget.day)} ${_dayMonth(context, widget.day)}, ${widget.count} performances',
    );

    return Semantics(
      button: true,
      selected: sel,
      label: semantic,
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          side: BorderSide(
            color: _focused
                ? (sel ? cs.onPrimary : cs.primary)
                : (sel ? Colors.transparent : cs.outlineVariant),
            width: _focused ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          onFocusChange: (final v) => setState(() => _focused = v),
          mouseCursor: SystemMouseCursors.click,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _relativeDay(context, widget.day),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: sub,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.day.day}',
                  style: GoogleFonts.playfairDisplay(
                    color: fg,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                Text(
                  _monthShort(context, widget.day),
                  maxLines: 1,
                  style: TextStyle(
                    color: sub,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tek bir seans = kağıt bir koçan: solda SAAT, delik çizgisi, sağda afiş +
/// oyun adı + sahne + (gerçekse) fiyat. Dokununca oyun sayfası.
class HomeSessionStub extends StatefulWidget {
  final HomeSession session;
  final VoidCallback onTap;

  const HomeSessionStub(
      {super.key, required this.session, required this.onTap});

  @override
  State<HomeSessionStub> createState() => _HomeSessionStubState();
}

class _HomeSessionStubState extends State<HomeSessionStub> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(final BuildContext context) {
    final s = widget.session;
    final String? stageName =
        (s.stage?.name.trim().isNotEmpty ?? false) ? s.stage!.name : null;
    final String? price = s.priceLabel;
    final Color accent = TicketInk.accentOf(context);
    final bool active = _hovered || _focused;

    return Semantics(
      button: true,
      label: [
        s.show.name,
        '${_dayMonth(context, s.date)} ${_time(s.date)}',
        if (stageName != null) stageName,
        if (price != null) price,
      ].join(', '),
      excludeSemantics: true,
      child: AnimatedSlide(
        offset: active ? const Offset(0, -0.02) : Offset.zero,
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        child: TicketPiece(
          perforated: TicketEdge.left,
          notch: 10,
          corner: AppRadius.sm,
          shadows: active
              ? AppShadows.level3(TicketInk.ink)
              : AppShadows.level1(TicketInk.ink),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: widget.onTap,
              onHover: (final v) => setState(() => _hovered = v),
              onFocusChange: (final v) => setState(() => _focused = v),
              mouseCursor: SystemMouseCursors.click,
              splashColor: accent.withOpacity(0.10),
              highlightColor: accent.withOpacity(0.05),
              hoverColor: Colors.transparent,
              focusColor: accent.withOpacity(0.10),
              child: SizedBox(
                height: 104,
                child: Row(
                  children: [
                    SizedBox(
                      width: 84,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(homeText(context, 'SAAT', 'TIME'),
                              style: TicketInk.label()),
                          const SizedBox(height: 2),
                          Text(
                            _time(s.date),
                            style: GoogleFonts.playfairDisplay(
                              color: _focused ? accent : TicketInk.ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 2,
                      height: 104,
                      child: TicketPerforation(axis: Axis.vertical),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 54,
                      height: 72,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.xs / 2),
                        child: ColoredBox(
                          color: TicketInk.inkSoft(0.08),
                          child: OptimizedCachedImage(
                            imageUrl: s.show.imageUrl,
                            fit: BoxFit.cover,
                            borderRadius: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            s.show.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.playfairDisplay(
                              color: TicketInk.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          if (stageName != null || price != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              [
                                if (stageName != null) stageName,
                                if (price != null) price,
                              ].join('   '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: TicketInk.inkSoft(0.7),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
