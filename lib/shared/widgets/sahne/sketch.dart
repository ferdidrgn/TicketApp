import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'sahne_kit.dart';

/// "Kalemle çizilmiş" dil: elle çizilmiş çizgiler, karalama ayraçlar ve
/// el yazısı notlar. Çizgiler açılışta kalem hareketiyle çizilir; azaltılmış
/// harekette doğrudan görünür. Renkler temadan (onSurface / primary).
abstract final class Sketch {
  /// El yazısı not — Caveat (Türkçe karakterleri destekler).
  static TextStyle hand(
    final BuildContext context, {
    final double size = 20,
    final Color? color,
    final FontWeight weight = FontWeight.w600,
    final double height = 1.1,
  }) =>
      GoogleFonts.caveat(
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      );
}

/// Dalgalı, "titrek" bir kalem yolu üretir (a → b). [amp] sapma miktarı.
Path _pencilPath(final Offset a, final Offset b, final int seed,
    {final double amp = 1.6, final int segments = 22}) {
  final math.Random r = math.Random(seed);
  final Offset d = b - a;
  final double len = d.distance;
  if (len == 0) return Path();
  final Offset n = Offset(-d.dy / len, d.dx / len);
  final double phase = r.nextDouble() * math.pi * 2;
  final List<Offset> pts = [];
  for (int i = 0; i <= segments; i++) {
    final double t = i / segments;
    final double wob = math.sin(t * math.pi * 3.1 + phase) * amp * 0.7 +
        (r.nextDouble() - 0.5) * amp * 0.9;
    pts.add(a + d * t + n * wob);
  }
  final Path p = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (int i = 1; i < pts.length - 1; i++) {
    final Offset mid = (pts[i] + pts[i + 1]) / 2;
    p.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
  }
  p.lineTo(pts.last.dx, pts.last.dy);
  return p;
}

class _DrawIn extends StatefulWidget {
  final Widget Function(double t) builder;
  final Duration duration;
  final int index;

  const _DrawIn({
    required this.builder,
    this.duration = const Duration(milliseconds: 700),
    this.index = 0,
  });

  @override
  State<_DrawIn> createState() => _DrawInState();
}

class _DrawInState extends State<_DrawIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.duration);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Sk.reduceMotion(context)) {
      _c.value = 1;
    } else {
      Future<void>.delayed(Duration(milliseconds: 120 + 90 * widget.index), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (final context, _) =>
            widget.builder(Curves.easeOutCubic.transform(_c.value)),
      );
}

/// Elle çizilmiş (kurşun kalem) çizgi. Yatayda [width] kadar; [vertical]
/// ise bulunduğu alanın yüksekliğini doldurur (zaman çizgisi için).
class SkPencilLine extends StatelessWidget {
  final double width;
  final double thickness;
  final bool vertical;
  final Color? color;
  final int seed;

  const SkPencilLine({
    super.key,
    this.width = 80,
    this.thickness = 8,
    this.vertical = false,
    this.color,
    this.seed = 7,
  });

  @override
  Widget build(final BuildContext context) {
    final Color c = color ?? Theme.of(context).colorScheme.primary;
    return ExcludeSemantics(
      child: _DrawIn(
        builder: (final t) => vertical
            ? CustomPaint(
                size: Size(thickness, double.infinity),
                painter: _LinePainter(t, c, seed, true),
              )
            : CustomPaint(
                size: Size(width, thickness),
                painter: _LinePainter(t, c, seed, false),
              ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final double t;
  final Color color;
  final int seed;
  final bool vertical;

  const _LinePainter(this.t, this.color, this.seed, this.vertical);

  @override
  void paint(final Canvas canvas, final Size size) {
    if (t <= 0) return;
    final double w = size.width;
    final double h = size.height.isFinite ? size.height : 0;
    final Offset a = vertical ? Offset(w / 2, 0) : Offset(0, h / 2);
    final Offset b = vertical ? Offset(w / 2, h) : Offset(w, h / 2);
    final List<(double, double, double)> strokes = [
      (1.8, 0.85, 0),
      (1.1, 0.45, 1.6),
    ];
    for (int i = 0; i < strokes.length; i++) {
      final (double sw, double alpha, double off) = strokes[i];
      final Offset shift = vertical ? Offset(off, 0) : Offset(0, off);
      final Path p = _pencilPath(a + shift, b + shift, seed + i * 11,
          amp: vertical ? 1.4 : 1.7);
      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = sw
        ..color = color.withValues(alpha: alpha);
      for (final m in p.computeMetrics()) {
        canvas.drawPath(m.extractPath(0, m.length * t), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant final _LinePainter old) =>
      old.t != t || old.color != color;
}

/// Karalama ayracı: dalgalı kalem çizgisi + ortada küçük çizgi yıldız.
class SkSquiggle extends StatelessWidget {
  final double width;
  final int seed;
  final Color? color;

  const SkSquiggle({super.key, this.width = 110, this.seed = 3, this.color});

  @override
  Widget build(final BuildContext context) {
    final Color c =
        color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return ExcludeSemantics(
      child: _DrawIn(
        duration: const Duration(milliseconds: 900),
        builder: (final t) => CustomPaint(
          size: Size(width, 18),
          painter: _SquigglePainter(t, c, seed),
        ),
      ),
    );
  }
}

class _SquigglePainter extends CustomPainter {
  final double t;
  final Color color;
  final int seed;

  const _SquigglePainter(this.t, this.color, this.seed);

  @override
  void paint(final Canvas canvas, final Size size) {
    if (t <= 0) return;
    final math.Random r = math.Random(seed);
    final double w = size.width;
    final double cy = size.height / 2;
    final Path wave = Path()..moveTo(0, cy);
    const double step = 6;
    for (double x = step; x <= w - 26; x += step) {
      final double y = cy + math.sin(x / 7) * 3 + (r.nextDouble() - 0.5) * 1.2;
      wave.lineTo(x, y);
    }
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.7
      ..color = color.withValues(alpha: 0.75);
    for (final m in wave.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * t), paint);
    }
    // Çizgi yıldız (kalemle iki çapraz + bir dikey)
    if (t > 0.7) {
      final double k = ((t - 0.7) / 0.3).clamp(0.0, 1.0);
      final Offset c = Offset(w - 12, cy);
      final double len = 7 * k;
      final Paint star = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.6
        ..color = color.withValues(alpha: 0.8);
      canvas.drawLine(c + Offset(-len, 0), c + Offset(len, 0), star);
      canvas.drawLine(c + Offset(0, -len), c + Offset(0, len), star);
      canvas.drawLine(
          c + Offset(-len * 0.7, -len * 0.7), c + Offset(len * 0.7, len * 0.7), star);
      canvas.drawLine(
          c + Offset(-len * 0.7, len * 0.7), c + Offset(len * 0.7, -len * 0.7), star);
    }
  }

  @override
  bool shouldRepaint(covariant final _SquigglePainter old) =>
      old.t != t || old.color != color;
}
