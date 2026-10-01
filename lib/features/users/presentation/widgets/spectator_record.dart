import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/util/date_formatter.dart';
import '../../../../shared/navigation/widgets/nav_handler.dart';
import '../../../../shared/widgets/ticket/ticket_kit.dart';
import '../../../../shared/widgets/ticket/ticket_listing.dart';
import '../../../settings/presentation/widgets/preference_widgets.dart';
import '../../../tickets/presentation/providers/my_ticket_provider.dart';

/// SEYİRCİ KARNESİ — profilin oyun katmanı.
///
/// İzlenen (tarihi geçmiş bileti olan) her oyun karneye bir mürekkep
/// damgası olarak basılır; damga sayısı seyircinin rütbesini belirler
/// (Yeni Seyirci → Seyirci → Müdavim → Tiyatro Kurdu → Sahne Tozu
/// Yutmuş). Bir sonraki rütbeye kalan oyunlar, kondüktör zımbasıyla
/// delinen bir sıra delik olarak gösterilir.
///
/// Her şey gerçek bilet verisinden (`myTicketsProvider`) hesaplanır —
/// uydurma rozet, puan ya da sayı yok. Aynı oyunu iki kez izlemek tek
/// damga sayılır. Veri gelmezse bölüm kendini gizler (ikincil bilgi).
class SpectatorRecord extends ConsumerWidget {
  final String userId;

  /// Kullanıcının hiç bileti yoksa sorgu atılmaz, boş karne gösterilir.
  final bool hasTickets;

  const SpectatorRecord({
    super.key,
    required this.userId,
    required this.hasTickets,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    Widget framed(final Widget child) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const PreferenceSectionTitle(
              'Seyirci karnem',
              caption: 'İzlediğin her oyun karnene bir damga olarak basılır.',
            ),
            child,
            const SizedBox(height: AppSpacing.huge),
          ],
        );

    if (!hasTickets) {
      return framed(const _RecordCard(seen: [], upcoming: 0));
    }

    return ref.watch(myTicketsProvider(userId)).when(
          loading: () => framed(const TicketRowSkeleton(height: 220)),
          error: (final err, final stack) => const SizedBox.shrink(),
          data: (final tickets) => framed(_RecordCard(
            seen: _seenShows(tickets),
            upcoming: tickets.upcoming.length,
          )),
        );
  }

  /// Tarihi geçmiş biletlerden oyun başına bir damga (en son izleme
  /// tarihiyle), en yeni önce.
  static List<_Stamp> _seenShows(final List<DetailedTicket> tickets) {
    final byShow = <String, _Stamp>{};
    for (final t in tickets.past) {
      final show = t.show;
      if (show == null || show.name.trim().isEmpty) continue;
      final DateTime? at = DateFormatter.parseDateString(t.event?.date);
      final existing = byShow[show.id];
      if (existing == null ||
          (at != null && (existing.at == null || at.isAfter(existing.at!)))) {
        byShow[show.id] = _Stamp(show.id, show.name.trim(), at);
      }
    }
    final list = byShow.values.toList()
      ..sort((final a, final b) {
        if (a.at == null && b.at == null) return 0;
        if (a.at == null) return 1;
        if (b.at == null) return -1;
        return b.at!.compareTo(a.at!);
      });
    return list;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Rütbeler
// ─────────────────────────────────────────────────────────────────────────

class _Rank {
  final int min;
  final String title;
  final String line;
  const _Rank(this.min, this.title, this.line);
}

const List<_Rank> _ranks = [
  _Rank(0, 'Yeni Seyirci', 'Perde henüz açılmadı; ilk damgan seni bekliyor.'),
  _Rank(1, 'Seyirci', 'Salona ilk adımı attın. Alkışın eksik olmasın.'),
  _Rank(3, 'Müdavim', 'Gişedekiler artık seni tanıyor.'),
  _Rank(6, 'Tiyatro Kurdu', 'Sezonun programını ezbere biliyorsun.'),
  _Rank(10, 'Sahne Tozu Yutmuş', 'Kulis kapısı sana hep aralık.'),
];

class _Stamp {
  final String showId;
  final String name;
  final DateTime? at;
  const _Stamp(this.showId, this.name, this.at);
}

// ─────────────────────────────────────────────────────────────────────────
// Karne
// ─────────────────────────────────────────────────────────────────────────

class _RecordCard extends StatefulWidget {
  final List<_Stamp> seen;
  final int upcoming;

  const _RecordCard({required this.seen, required this.upcoming});

  @override
  State<_RecordCard> createState() => _RecordCardState();
}

class _RecordCardState extends State<_RecordCard>
    with SingleTickerProviderStateMixin {
  /// En yeni damga oturum başına bir kez "güm" diye basılır; sayfaya her
  /// dönüşte tekrar oynamaz.
  static bool _stampedThisSession = false;

  late final AnimationController _slam = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final bool reduce = MediaQuery.of(context).disableAnimations;
    if (reduce || _stampedThisSession || widget.seen.isEmpty) {
      _slam.value = 1;
      return;
    }
    _stampedThisSession = true;
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _slam.forward().whenComplete(() {});
      Future<void>.delayed(
        Duration(milliseconds: (AppMotion.slow.inMilliseconds * 0.55).round()),
        () {
          if (mounted) HapticFeedback.mediumImpact();
        },
      );
    });
  }

  @override
  void dispose() {
    _slam.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final int count = widget.seen.length;
    final int rankIndex =
        _ranks.lastIndexWhere((final r) => count >= r.min).clamp(0, 99);
    final _Rank rank = _ranks[rankIndex];
    final _Rank? next =
        rankIndex + 1 < _ranks.length ? _ranks[rankIndex + 1] : null;

    return Semantics(
      container: true,
      label: 'Seyirci karnesi: ${rank.title}, $count oyun izlendi'
          '${next == null ? '' : ', ${next.title} rütbesine ${next.min - count} oyun kaldı'}',
      child: AdmitTicket(
        direction: Axis.vertical,
        shadows: AppShadows.level2(WebColors.veryDarkBlue),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const TicketHeaderStrip(kind: 'SEYİRCİ KARNESİ'),
              const SizedBox(height: AppSpacing.lg),
              Text('RÜTBE', style: TicketInk.label()),
              const SizedBox(height: AppSpacing.xs),
              Text(rank.title, style: TicketInk.headline(30)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                rank.line,
                style: TextStyle(
                  color: TicketInk.inkSoft(0.7),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _StampBoard(seen: widget.seen, slam: _slam),
            ],
          ),
        ),
        stub: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.lg),
          child: _PunchProgress(count: count, rank: rank, next: next,
              upcoming: widget.upcoming),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Damgalar
// ─────────────────────────────────────────────────────────────────────────

class _StampBoard extends StatelessWidget {
  final List<_Stamp> seen;
  final Animation<double> slam;

  const _StampBoard({required this.seen, required this.slam});

  static const int _maxShown = 8;

  @override
  Widget build(final BuildContext context) {
    if (seen.isEmpty) {
      return Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            const _GhostStamp(),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: TicketTextLink(
              label: 'Oyun keşfet',
              emphasize: true,
              onTap: () => NavigationHandler.goToDiscover(context),
            ),
          ),
        ],
      );
    }

    final List<_Stamp> shown = seen.take(_maxShown).toList();
    final int rest = seen.length - shown.length;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (int i = 0; i < shown.length; i++)
          _InkStampDisc(
            stamp: shown[i],
            // Sadece en yeni damga basılma anını oynar.
            slam: i == 0 ? slam : const AlwaysStoppedAnimation<double>(1),
          ),
        if (rest > 0)
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: Text('+$rest oyun', style: TicketInk.value(size: 13)),
          ),
      ],
    );
  }
}

/// Oyuna ait yuvarlak mürekkep damgası: çift halka, oyun adının baş
/// harfleri (Playfair) ve izleme ayı. Her oyunun eğimi kimliğinden
/// türetilir — her açılışta aynı durur, el ile basılmış gibi.
class _InkStampDisc extends StatelessWidget {
  final _Stamp stamp;
  final Animation<double> slam;

  const _InkStampDisc({required this.stamp, required this.slam});

  static const double _size = 64;
  static const List<String> _months = [
    'OCA', 'ŞUB', 'MAR', 'NİS', 'MAY', 'HAZ',
    'TEM', 'AĞU', 'EYL', 'EKİ', 'KAS', 'ARA',
  ];

  String get _initials {
    final words = stamp.name
        .split(RegExp(r'\s+'))
        .where((final w) => w.isNotEmpty)
        .toList();
    final String s = words.take(2).map((final w) => w.characters.first).join();
    return s.toUpperCase();
  }

  double get _tilt {
    final int h = stamp.showId.codeUnits.fold(7, (final a, final c) => a * 31 + c);
    return ((h % 1000) / 1000 - 0.5) * 0.6; // ±0.3 rad
  }

  @override
  Widget build(final BuildContext context) {
    final Color ink = TicketInk.accentOf(context);
    final String when = stamp.at == null
        ? ''
        : '${_months[stamp.at!.month - 1]} ${stamp.at!.year % 100}';

    final Widget disc = SizedBox(
      width: _size,
      height: _size,
      child: CustomPaint(
        painter: _StampRingPainter(ink),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _initials,
                style: GoogleFonts.playfairDisplay(
                  color: ink,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              if (when.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  when,
                  style: TextStyle(
                    color: ink,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: '${stamp.name} damgası',
      excludeSemantics: true,
      child: Tooltip(
        message: stamp.name,
        child: InkResponse(
          onTap: () =>
              NavigationHandler.goToShow(context, stamp.showId, stamp.name),
          radius: _size / 2 + 4,
          child: AnimatedBuilder(
            animation: slam,
            builder: (final context, final child) {
              final double t = slam.value;
              if (t == 0) return const SizedBox(width: _size, height: _size);
              // Damga yukarıdan iner (büyükten gerçek boya), kağıda
              // değdiği an mürekkep koyulaşır.
              final double eased = Curves.easeInCubic.transform(t.clamp(0, 1));
              final double scale = t < 0.55
                  ? 1.9 - 0.9 * (eased / Curves.easeInCubic.transform(0.55))
                  : 1 + 0.05 * math.sin((t - 0.55) / 0.45 * math.pi);
              return Opacity(
                opacity: (t * 2.2).clamp(0.0, 0.88),
                child: Transform.rotate(
                  angle: _tilt,
                  child: Transform.scale(scale: scale, child: child),
                ),
              );
            },
            child: disc,
          ),
        ),
      ),
    );
  }
}

class _StampRingPainter extends CustomPainter {
  final Color ink;
  const _StampRingPainter(this.ink);

  @override
  void paint(final Canvas canvas, final Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.shortestSide / 2;
    final Paint p = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(c, r - 1.5, p..strokeWidth = 2.4);
    canvas.drawCircle(c, r - 6, p..strokeWidth = 0.9);
    // Halkanın iç çevresinde küçük yıldızlar — posta/gişe damgası izi.
    final Paint dot = Paint()..color = ink;
    for (int i = 0; i < 12; i++) {
      final double a = i * math.pi / 6;
      canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * (r - 3.8), 0.7, dot);
    }
  }

  @override
  bool shouldRepaint(covariant final _StampRingPainter old) => old.ink != ink;
}

/// Henüz basılmamış damga yeri (boş karne).
class _GhostStamp extends StatelessWidget {
  const _GhostStamp();

  @override
  Widget build(final BuildContext context) => ExcludeSemantics(
        child: SizedBox(
          width: 52,
          height: 52,
          child: CustomPaint(
            painter: _DashedCirclePainter(TicketInk.inkSoft(0.3)),
            child: Center(
              child: Icon(Icons.theater_comedy_outlined,
                  size: 20, color: TicketInk.inkSoft(0.3)),
            ),
          ),
        ),
      );
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  const _DashedCirclePainter(this.color);

  @override
  void paint(final Canvas canvas, final Size size) {
    final Offset c = size.center(Offset.zero);
    final double r = size.shortestSide / 2 - 1;
    final Paint p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    const int dashes = 18;
    for (int i = 0; i < dashes; i++) {
      final double a0 = i * 2 * math.pi / dashes;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a0,
          math.pi / dashes, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant final _DashedCirclePainter old) =>
      old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────
// Koçan: zımba delikleriyle sonraki rütbeye ilerleme
// ─────────────────────────────────────────────────────────────────────────

class _PunchProgress extends StatelessWidget {
  final int count;
  final _Rank rank;
  final _Rank? next;
  final int upcoming;

  const _PunchProgress({
    required this.count,
    required this.rank,
    required this.next,
    required this.upcoming,
  });

  @override
  Widget build(final BuildContext context) {
    final _Rank? n = next;
    final String headline = n == null
        ? 'En yüksek rütbedesin'
        : '${n.title} rütbesine ${n.min - count} oyun kaldı';
    final String? note = upcoming > 0
        ? 'Sırada $upcoming biletin var — izleyince damgası basılır.'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('SONRAKİ PERDE', style: TicketInk.label()),
                  const SizedBox(height: 3),
                  Text(headline, style: TicketInk.value(size: 14)),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            TicketField(
              label: 'İZLENEN',
              value: '$count oyun',
              align: CrossAxisAlignment.end,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (n != null)
          _PunchRow(
            total: n.min - rank.min,
            punched: count - rank.min,
          ),
        if (note != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            note,
            style: TextStyle(
              color: TicketInk.inkSoft(0.65),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

/// Kondüktör zımbası: her izlenen oyun bir delik deler. Delinen delik
/// temanın vurgu rengiyle mürekkeplenir, kalanlar boş halka.
class _PunchRow extends StatelessWidget {
  final int total;
  final int punched;

  const _PunchRow({required this.total, required this.punched});

  @override
  Widget build(final BuildContext context) {
    final Color ink = TicketInk.accentOf(context);
    return ExcludeSemantics(
      child: Row(
        children: [
          for (int i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < punched ? ink : Colors.transparent,
                border: Border.all(
                  color: i < punched ? ink : TicketInk.inkSoft(0.28),
                  width: 1.2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
