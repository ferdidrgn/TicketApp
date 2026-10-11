import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../shared/widgets/sahne/sahne_kit.dart';

// ═════════════════════════════════════════════════════════════════════════════
// PERDE SAATİ — 14 günlük segmentli kadran + canlı geri sayım
// ═════════════════════════════════════════════════════════════════════════════

/// Önümüzdeki 14 günü 14 yuvarlak segment olarak çizer; seansı olan günler
/// dolu (renkli), diğerleri sönük. Ortada seçili (yoksa en yakın) seansa
/// canlı geri sayım. Segmente dokununca [onDay] çağrılır (seansı olan
/// günlerde). Açılışta segmentler sırayla dolar. Hepsi gerçek seans
/// tarihlerinden; renkler temadan.
class ShowCountdownGauge extends StatefulWidget {
  final List<DateTime> sessions;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onDay;

  const ShowCountdownGauge({
    super.key,
    required this.sessions,
    required this.selectedDay,
    required this.onDay,
  });

  @override
  State<ShowCountdownGauge> createState() => _ShowCountdownGaugeState();
}

class _ShowCountdownGaugeState extends State<ShowCountdownGauge>
    with SingleTickerProviderStateMixin {
  static const int _days = 14;
  late final AnimationController _bloom = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300));
  Timer? _tick;
  DateTime _now = DateTime.now();
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Sk.reduceMotion(context)) {
      _bloom.value = 1;
    } else {
      Future<void>.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _bloom.forward();
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _bloom.dispose();
    super.dispose();
  }

  List<DateTime> get _dayList {
    final DateTime today = skDay(DateTime.now());
    return [for (int i = 0; i < _days; i++) today.add(Duration(days: i))];
  }

  DateTime? get _target {
    final List<DateTime> up = [
      for (final DateTime d in widget.sessions)
        if (d.isAfter(_now)) d,
    ]..sort();
    if (widget.selectedDay != null) {
      for (final DateTime d in up) {
        if (skDay(d) == widget.selectedDay) return d;
      }
    }
    return up.isEmpty ? null : up.first;
  }

  void _tap(final Offset p, final double size) {
    final Offset c = Offset(size / 2, size / 2);
    final Offset d = p - c;
    if (d.distance < size * 0.26) return;
    const double start = 150 * math.pi / 180;
    const double sweep = 240 * math.pi / 180;
    double a = d.direction;
    if (a < 0) a += 2 * math.pi;
    double rel = a - start;
    if (rel < 0) rel += 2 * math.pi;
    if (rel > sweep) return;
    final int i = (rel / (sweep / _days)).floor().clamp(0, _days - 1);
    final DateTime day = _dayList[i];
    final bool has = widget.sessions.any((final s) => skDay(s) == day);
    if (!has) return;
    HapticFeedback.selectionClick();
    widget.onDay(day);
  }

  String _countdown(final Duration left) {
    if (left.inDays >= 1) {
      return '${left.inDays}g ${(left.inHours % 24).toString().padLeft(2, '0')}sa';
    }
    String two(final int v) => v.toString().padLeft(2, '0');
    return '${two(left.inHours)}:${two(left.inMinutes % 60)}:${two(left.inSeconds % 60)}';
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final List<DateTime> days = _dayList;
    final Set<DateTime> has = {for (final DateTime s in widget.sessions) skDay(s)};
    final DateTime? target = _target;
    final Duration? left = target?.difference(_now);

    return LayoutBuilder(builder: (final context, final box) {
      final double size = math.min(box.maxWidth, 330);
      return Column(
        children: [
          Semantics(
            label:
                'Seans takvimi: önümüzdeki 14 günde ${has.where((d) => days.contains(d)).length} gün seans var',
            child: SizedBox(
              width: size,
              height: size * 0.86,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (final d) => _tap(d.localPosition, size),
                child: AnimatedBuilder(
                  animation: _bloom,
                  builder: (final context, _) => Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size(size, size * 0.86),
                        painter: _SegPainter(
                          days: days,
                          has: has,
                          selected: widget.selectedDay,
                          bloom: _bloom.value,
                          on1: cs.primary,
                          on2: cs.tertiary,
                          off: cs.surfaceContainerHighest,
                          ring: cs.surface,
                        ),
                      ),
                      Positioned(
                        top: size * 0.30,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.theater_comedy_rounded,
                                color: cs.primary, size: 22),
                            const SizedBox(height: 4),
                            Text(
                              target == null
                                  ? 'Seans yok'
                                  : (widget.selectedDay != null &&
                                          skDay(target) == widget.selectedDay
                                      ? 'Seçili seansa'
                                      : 'Sıradaki perdeye'),
                              style: Sk.ui(context,
                                  size: 12,
                                  color: cs.onSurfaceVariant,
                                  weight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                left == null ? '—' : _countdown(left),
                                key: ValueKey<bool>(
                                    left != null && left.inDays >= 1),
                                style: Sk.display(context,
                                    size: size * 0.115,
                                    height: 1.05,
                                    weight: FontWeight.w800),
                              ),
                            ),
                            if (target != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${kDaysTr[target.weekday - 1]}, ${target.day} ${kMonthsTr[target.month - 1]} · ${skClock(target)}',
                                style: Sk.ui(context,
                                    size: 12.5,
                                    color: cs.onSurface,
                                    weight: FontWeight.w700),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: cs.primary, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 6),
              Text('seans var',
                  style: Sk.ui(context,
                      size: 12,
                      color: cs.onSurfaceVariant,
                      weight: FontWeight.w600)),
              const SizedBox(width: 16),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 6),
              Text('boş gün',
                  style: Sk.ui(context,
                      size: 12,
                      color: cs.onSurfaceVariant,
                      weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Dolu bir segmente dokun: o günün seansı seçilir',
              style: Sk.ui(context,
                  size: 12,
                  color: cs.onSurfaceVariant,
                  weight: FontWeight.w500)),
        ],
      );
    });
  }
}

class _SegPainter extends CustomPainter {
  final List<DateTime> days;
  final Set<DateTime> has;
  final DateTime? selected;
  final double bloom;
  final Color on1;
  final Color on2;
  final Color off;
  final Color ring;

  const _SegPainter({
    required this.days,
    required this.has,
    required this.selected,
    required this.bloom,
    required this.on1,
    required this.on2,
    required this.off,
    required this.ring,
  });

  @override
  void paint(final Canvas canvas, final Size size) {
    final int n = days.length;
    const double start = 150 * math.pi / 180;
    const double sweep = 240 * math.pi / 180;
    final double w = size.width;
    final Offset c = Offset(w / 2, w / 2);
    final double thick = w * 0.105;
    final double rMid = w / 2 - thick * 0.9;
    final double stepA = sweep / n;
    final double arcLen = rMid * stepA * 0.80;

    for (int i = 0; i < n; i++) {
      final DateTime d = days[i];
      final bool on = has.contains(d);
      final bool isSel = selected != null && selected == d;
      final double t = Interval(i * 0.045, 0.55 + i * 0.045,
              curve: Curves.easeOutBack)
          .transform(bloom);
      if (t <= 0) continue;
      final double a = start + stepA * (i + 0.5);
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(a);
      final double th = thick * (isSel ? 1.28 : 1.0) * (0.55 + 0.45 * t);
      final RRect rr = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(rMid, 0), width: th, height: arcLen * t.clamp(0, 1.1)),
        Radius.circular(arcLen * 0.28),
      );
      if (on) {
        final Color col = Color.lerp(on1, on2, i / (n - 1))!;
        if (isSel) {
          canvas.drawShadow(Path()..addRRect(rr), col, 10, true);
        }
        canvas.drawRRect(rr, Paint()..color = col);
        if (isSel) {
          canvas.drawRRect(
            rr,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5
              ..color = ring,
          );
        }
      } else {
        canvas.drawRRect(rr, Paint()..color = off.withValues(alpha: 0.85));
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant final _SegPainter old) =>
      old.bloom != bloom ||
      old.selected != selected ||
      old.on1 != on1 ||
      old.off != off ||
      old.has != has;
}

// ═════════════════════════════════════════════════════════════════════════════
// AFİŞ ÜSTÜ İŞARETLİ ETİKETLER (pin + çizgi animasyonu)
// ═════════════════════════════════════════════════════════════════════════════

class ShowCallout {
  final IconData icon;
  final String text;
  const ShowCallout(this.icon, this.text);
}

/// Afişin üst yarısında, çizgiyle bir noktaya bağlanan cam etiketler.
/// Açılışta çizgi uzar, etiket belirir (sırayla). Dokunmaya kapalı; tamamen
/// bilgilendirici ve gerçek veriden (süre, seans sayısı, fiyat).
class ShowPosterCallouts extends StatefulWidget {
  final List<ShowCallout> items;
  final double top;

  const ShowPosterCallouts({super.key, required this.items, this.top = 96});

  @override
  State<ShowPosterCallouts> createState() => _ShowPosterCalloutsState();
}

class _ShowPosterCalloutsState extends State<ShowPosterCallouts>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Sk.reduceMotion(context)) {
      _c.value = 1;
    } else {
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // (sol oranı, üst ofset, çizgi uzunluğu) — organik dağılım
  static const List<(double, double, double)> _slots = [
    (0.06, 0, 70),
    (0.60, 26, 92),
    (0.34, 62, 54),
  ];

  @override
  Widget build(final BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: LayoutBuilder(builder: (final context, final box) {
        return AnimatedBuilder(
          animation: _c,
          builder: (final context, _) {
            final List<Widget> kids = [];
            for (int i = 0; i < widget.items.length && i < _slots.length; i++) {
              final (double fx, double dy, double len) = _slots[i];
              final double t = Interval(i * 0.22, 0.6 + i * 0.2,
                      curve: Curves.easeOutCubic)
                  .transform(_c.value);
              final ShowCallout it = widget.items[i];
              final double left = (box.maxWidth - 150) * fx + 14;
              kids.add(Positioned(
                left: left,
                top: widget.top + dy,
                child: Opacity(
                  opacity: t,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkGlass(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(it.icon, size: 15, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(it.text,
                              style: Sk.ui(context,
                                  size: 13,
                                  color: Colors.white,
                                  weight: FontWeight.w800)),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 18),
                        child: Column(
                          children: [
                            Container(
                              width: 1.6,
                              height: len * t,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                            Transform.scale(
                              scale: t,
                              child: Container(
                                width: 9,
                                height: 9,
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ));
            }
            return Stack(children: kids);
          },
        );
      }),
    );
  }
}
