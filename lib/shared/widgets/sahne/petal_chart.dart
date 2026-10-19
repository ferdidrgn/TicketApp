import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sahne_kit.dart';

/// Bir yaprağın verisi. [weight] 0..1 yaprağın uzunluğunu belirler.
class SkPetal {
  final String label;
  final String value;
  final double weight;
  final String? imageUrl;
  final String? openLabel;
  final VoidCallback? onOpen;

  const SkPetal({
    required this.label,
    required this.value,
    required this.weight,
    this.imageUrl,
    this.openLabel,
    this.onOpen,
  });
}

/// Veriyi çiçeğe çeviren etkileşimli yaprak grafiği.
///
/// Ortada bir fotoğraf/simge, çevresinde 2–6 yaprak. Yaprak uzunluğu veriyle
/// orantılı. Açılışta yapraklar sırayla açılır; dokununca yaprak büyür, diğerleri
/// söner ve altta ayrıntı + "aç" aksiyonu belirir (iki adımlı: önce önizle,
/// sonra git — yanlışlıkla gezinme yok). Renkler temadan (primary/tertiary);
/// azaltılmış harekette animasyon atlanır. Ekran okuyucu için her yaprak
/// ayrı etiketli bir düğme olarak da sunulur.
class SkPetalChart extends StatefulWidget {
  final List<SkPetal> petals;
  final Widget center;
  final double size;
  final String semanticLabel;
  final String hint;

  const SkPetalChart({
    super.key,
    required this.petals,
    required this.center,
    required this.semanticLabel,
    this.size = 340,
    this.hint = 'Bir yaprağa dokun',
  });

  @override
  State<SkPetalChart> createState() => _SkPetalChartState();
}

class _SkPetalChartState extends State<SkPetalChart>
    with TickerProviderStateMixin {
  late final AnimationController _bloom = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100));
  late final AnimationController _sel = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 380));
  int? _selected;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (Sk.reduceMotion(context)) {
      _bloom.value = 1;
    } else {
      Future<void>.delayed(const Duration(milliseconds: 150), () {
        if (mounted) _bloom.forward();
      });
    }
  }

  @override
  void dispose() {
    _bloom.dispose();
    _sel.dispose();
    super.dispose();
  }

  int get _n => widget.petals.length;
  double get _step => 2 * math.pi / _n;
  double _angle(final int i) => -math.pi / 2 + _step * i;

  void _pick(final int? i) {
    if (i == _selected) {
      // Aynı yaprağa tekrar dokun → kapat.
      setState(() => _selected = null);
      _sel.reverse();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _selected = i);
    if (Sk.reduceMotion(context)) {
      _sel.value = 1;
    } else {
      _sel.forward(from: 0);
    }
  }

  void _tap(final Offset p) {
    final double s = widget.size;
    final Offset c = Offset(s / 2, s / 2);
    final Offset d = p - c;
    if (d.distance < s * 0.16) {
      _pick(null);
      return;
    }
    double a = d.direction + math.pi / 2; // 0 = yukarı
    a = (a % (2 * math.pi) + 2 * math.pi) % (2 * math.pi);
    final int i = ((a + _step / 2) % (2 * math.pi) / _step).floor() % _n;
    _pick(i);
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double s = widget.size;
    final SkPetal? sel = _selected == null ? null : widget.petals[_selected!];

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: s,
            height: s,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (final d) => _tap(d.localPosition),
              child: AnimatedBuilder(
                animation: Listenable.merge([_bloom, _sel]),
                builder: (final context, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size.square(s),
                        painter: _PetalPainter(
                          petals: widget.petals,
                          bloom: _bloom.value,
                          selected: _selected,
                          sel: Curves.easeOutBack.transform(_sel.value),
                          primary: cs.primary,
                          tertiary: cs.tertiary,
                          base: cs.surfaceContainerHigh,
                          rim: cs.outlineVariant,
                          shadow: Colors.black,
                        ),
                      ),
                      for (int i = 0; i < _n; i++) _label(context, i, cs),
                      // Merkez
                      Container(
                        width: s * 0.26,
                        height: s * 0.26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.surface,
                          boxShadow: skSoftShadow(context),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: ClipOval(child: widget.center),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (final c, final a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween<Offset>(
                        begin: const Offset(0, 0.15), end: Offset.zero)
                    .animate(a),
                child: c,
              ),
            ),
            child: sel == null
                ? Padding(
                    key: const ValueKey<String>('hint'),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(widget.hint,
                        style: Sk.ui(context,
                            size: 13,
                            color: cs.onSurfaceVariant,
                            weight: FontWeight.w600)),
                  )
                : Column(
                    key: ValueKey<String>(sel.label),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(sel.label,
                          textAlign: TextAlign.center,
                          style: Sk.display(context, size: 22, height: 1.1)),
                      const SizedBox(height: 2),
                      Text(sel.value,
                          style: Sk.ui(context,
                              size: 13,
                              color: cs.onSurfaceVariant,
                              weight: FontWeight.w700)),
                      if (sel.onOpen != null) ...[
                        const SizedBox(height: 10),
                        FilledButton.tonal(
                          onPressed: sel.onOpen,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 44),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(sel.openLabel ?? 'Aç'),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _label(
      final BuildContext context, final int i, final ColorScheme cs) {
    final double s = widget.size;
    final SkPetal p = widget.petals[i];
    final double a = _angle(i);
    final double r = s * 0.34;
    final Offset o = Offset(math.cos(a) * r, math.sin(a) * r);
    final double t = Interval(0.35 + i * 0.07, 0.9,
            curve: Curves.easeOut)
        .transform(_bloom.value);
    final bool dim = _selected != null && _selected != i;
    final bool on = _selected == i;
    final bool hasImg = (p.imageUrl ?? '').startsWith('http');
    return Positioned(
      left: s / 2 + o.dx - 44,
      top: s / 2 + o.dy - 40,
      width: 88,
      height: 80,
      child: IgnorePointer(
        child: Opacity(
          opacity: t * (dim ? 0.45 : 1),
          child: Transform.scale(
            scale: 0.8 + 0.2 * t + (on ? 0.1 * Curves.easeOutBack.transform(_sel.value) : 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasImg) ...[
                  ClipOval(
                    child: SkImage(
                        url: p.imageUrl!,
                        width: 34,
                        height: 34,
                        fallbackIcon: Icons.person_rounded),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(p.value,
                    maxLines: 1,
                    style: Sk.display(context,
                        size: hasImg ? 14 : 20,
                        height: 1.0,
                        weight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(p.label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: Sk.ui(context,
                        size: 11,
                        color: cs.onSurfaceVariant,
                        weight: FontWeight.w700,
                        height: 1.15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PetalPainter extends CustomPainter {
  final List<SkPetal> petals;
  final double bloom;
  final int? selected;
  final double sel;
  final Color primary;
  final Color tertiary;
  final Color base;
  final Color rim;
  final Color shadow;

  const _PetalPainter({
    required this.petals,
    required this.bloom,
    required this.selected,
    required this.sel,
    required this.primary,
    required this.tertiary,
    required this.base,
    required this.rim,
    required this.shadow,
  });

  @override
  void paint(final Canvas canvas, final Size size) {
    final int n = petals.length;
    final double step = 2 * math.pi / n;
    final Offset c = size.center(Offset.zero);
    final double R = size.width / 2;
    final double inner = R * 0.14;
    final double halfSpan = math.min(step * 0.47, 55 * math.pi / 180);

    for (int pass = 0; pass < 2; pass++) {
      for (int i = 0; i < n; i++) {
        final bool isSel = selected == i;
        // Seçili yaprak en üstte çizilsin.
        if ((pass == 0) == isSel) continue;

        final double t = Interval(i * 0.07, 0.62 + i * 0.07,
                curve: Curves.easeOutBack)
            .transform(bloom);
        final double w = petals[i].weight.clamp(0.0, 1.0);
        final double len = (R * (0.62 + 0.38 * w) * t) *
            (isSel ? 1 + 0.07 * sel : 1);
        if (len <= inner) continue;
        final double a0 = -math.pi / 2 + step * i;

        final Path path = Path();
        const int pts = 64;
        for (int k = 0; k <= pts; k++) {
          final double f = k / pts * 2 - 1; // -1..1
          final double phi = f * halfSpan;
          final double shape = math.pow(math.cos(f * math.pi / 2), 0.55)
              .toDouble();
          final double rad = inner + (len - inner) * shape;
          final Offset o = c + Offset.fromDirection(a0 + phi, rad);
          if (k == 0) {
            path.moveTo(o.dx, o.dy);
          } else {
            path.lineTo(o.dx, o.dy);
          }
        }
        path.close();

        final Color tint = i.isEven ? primary : tertiary;
        final double dim = selected != null && !isSel ? 0.55 : 1;

        if (isSel) {
          canvas.drawShadow(path, shadow.withValues(alpha: 0.45), 14, true);
        } else {
          canvas.drawShadow(path, shadow.withValues(alpha: 0.18), 5, true);
        }
        canvas.drawPath(path, Paint()..color = base.withValues(alpha: dim));
        canvas.drawPath(
          path,
          Paint()
            ..shader = RadialGradient(
              center: Alignment.center,
              radius: 0.62 + 0.38 * w,
              colors: [
                tint.withValues(alpha: (isSel ? 0.85 : 0.6) * dim),
                tint.withValues(alpha: (isSel ? 0.35 : 0.2) * dim),
                tint.withValues(alpha: 0),
              ],
              stops: const [0.0, 0.45, 1.0],
            ).createShader(Rect.fromCircle(center: c, radius: R)),
        );
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSel ? 2 : 1
            ..color = (isSel ? tint : rim).withValues(alpha: isSel ? 0.9 : 0.35),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant final _PetalPainter old) =>
      old.bloom != bloom ||
      old.selected != selected ||
      old.sel != sel ||
      old.petals != petals ||
      old.primary != primary ||
      old.base != base;
}
