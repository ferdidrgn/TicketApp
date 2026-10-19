import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../shared/widgets/sahne/flower_portrait.dart' show flowerPath;
import '../../../../../shared/widgets/sahne/sahne_kit.dart';

/// Portrenin çevresinde süzülen gerçek veri çipi ("12 oyun", "3 ödül"…).
class LiveChip {
  final IconData icon;
  final String label;
  final bool accent;
  const LiveChip(this.icon, this.label, {this.accent = false});
}

/// CANLI PORTRE SAHNESİ — oyuncu sayfasının görsel kalbi.
///
/// - Portre yapraklı (çiçek) kenarlı; yapraklar yavaşça döner, portre
///   "nefes alır" ve fotoğraf içinde çok hafif Ken-Burns kayması yapar.
/// - Çevresinde ters yönde dönen iki kalem çizgisi halka (kesikli) durur.
/// - Üç veri çipi farklı fazlarda süzülür (gerçek veriden).
/// - Web/masaüstünde imleç portreyi 3B eğer; dokunmada yapraklar bir tur
///   atar ve hafif titreşim verilir; dokununca tam ekran görüntü açılır.
/// - [offset] verilirse kaydırmayla portre yavaşlar, küçülür ve söner.
/// Azaltılmış harekette (`disableAnimations`) her şey durağan çizilir.
class LivePortraitStage extends StatefulWidget {
  final String imageUrl;
  final double size;
  final List<LiveChip> chips;
  final ValueNotifier<double>? offset;
  final VoidCallback? onTap;
  final Widget Function(Widget child)? heroWrap;

  const LivePortraitStage({
    super.key,
    required this.imageUrl,
    required this.size,
    this.chips = const [],
    this.offset,
    this.onTap,
    this.heroWrap,
  });

  @override
  State<LivePortraitStage> createState() => _LivePortraitStageState();
}

class _LivePortraitStageState extends State<LivePortraitStage>
    with TickerProviderStateMixin {
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: const Duration(seconds: 24));
  late final AnimationController _spin =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  Offset _tilt = Offset.zero; // -1..1

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (Sk.reduceMotion(context)) {
      _loop.stop();
    } else if (!_loop.isAnimating) {
      _loop.repeat();
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _spin.dispose();
    super.dispose();
  }

  void _tap() {
    HapticFeedback.selectionClick();
    if (!Sk.reduceMotion(context)) _spin.forward(from: 0);
    widget.onTap?.call();
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final bool reduce = Sk.reduceMotion(context);
    final double s = widget.size;
    final double box = s * 1.42; // halkalar + çipler için alan

    Widget flower() => AnimatedBuilder(
          animation: Listenable.merge([_loop, _spin]),
          builder: (final context, _) {
            final double t = reduce ? 0 : _loop.value;
            final double spin = Curves.easeOutBack.transform(_spin.value);
            final double phase = t * 2 * math.pi + spin * math.pi / 4;
            final double breathe = 1 + 0.014 * math.sin(t * 2 * math.pi * 8);
            final double ken = 1.06 + 0.04 * math.sin(t * 2 * math.pi * 2);
            final double depth = 0.22 + 0.04 * math.sin(t * 2 * math.pi * 4);
            final Size sz = Size.square(s);
            final Matrix4 m = Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateX(-_tilt.dy * 0.16)
              ..rotateY(_tilt.dx * 0.2);
            return Transform(
              alignment: Alignment.center,
              transform: m,
              child: Transform.scale(
                scale: breathe,
                child: SizedBox(
                  width: s,
                  height: s,
                  child: CustomPaint(
                    painter: _ShadowPainter(flowerPath(sz, phase, 8, depth)),
                    child: ClipPath(
                      clipper: _Clip(phase, depth),
                      child: ColoredBox(
                        color: cs.primaryContainer,
                        child: Transform.scale(
                          scale: ken,
                          alignment: const Alignment(0, -0.25),
                          child: SkImage(
                            url: widget.imageUrl,
                            width: s,
                            height: s,
                            alignment: const Alignment(0, -0.3),
                            fallbackIcon: Icons.person_rounded,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );

    final Widget portrait = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _tap,
      child: widget.heroWrap == null ? flower() : widget.heroWrap!(flower()),
    );

    // Çip yerleşimi: (sol/sağ hizası, dikey oran, süzülme fazı)
    const List<(double, double, double)> slots = [
      (0.0, 0.12, 0.0),
      (1.0, 0.46, 2.1),
      (0.04, 0.80, 4.2),
    ];

    final Widget stage = SizedBox(
      width: box,
      height: box,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Kalem halkaları
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _loop,
                builder: (final context, _) => CustomPaint(
                  painter: _OrbitPainter(
                    t: reduce ? 0 : _loop.value,
                    color: cs.primary,
                    portrait: s,
                  ),
                ),
              ),
            ),
          ),
          portrait,
          // Süzülen çipler
          for (int i = 0; i < widget.chips.length && i < slots.length; i++)
            AnimatedBuilder(
              animation: _loop,
              builder: (final context, child) {
                final double t = reduce ? 0 : _loop.value;
                final double bob =
                    math.sin(t * 2 * math.pi * 8 + slots[i].$3) * 5;
                final double sway =
                    math.cos(t * 2 * math.pi * 6 + slots[i].$3) * 3 +
                        _tilt.dx * (i.isEven ? -8 : 8);
                return Positioned(
                  left: slots[i].$1 == 1.0 ? null : box * slots[i].$1,
                  right: slots[i].$1 == 1.0 ? 0 : null,
                  top: box * slots[i].$2 - 14 + bob,
                  child: Transform.translate(
                      offset: Offset(sway, 0), child: child),
                );
              },
              child: _ChipView(chip: widget.chips[i]),
            ),
        ],
      ),
    );

    final Widget interactive = MouseRegion(
      onHover: (final e) {
        final Size b = (context.size ?? Size(box, box));
        setState(() => _tilt = Offset(
              ((e.localPosition.dx / b.width) * 2 - 1).clamp(-1.0, 1.0),
              ((e.localPosition.dy / b.height) * 2 - 1).clamp(-1.0, 1.0),
            ));
      },
      onExit: (_) => setState(() => _tilt = Offset.zero),
      child: stage,
    );

    // Giriş + kaydırma parallax'ı
    final Widget entering = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (final context, final v, final child) => Opacity(
        opacity: v.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.82 + 0.18 * v, child: child),
      ),
      child: interactive,
    );

    if (widget.offset == null) return entering;
    return ValueListenableBuilder<double>(
      valueListenable: widget.offset!,
      builder: (final context, final o, final child) {
        final double k = (o / 420).clamp(0.0, 1.0);
        return Opacity(
          opacity: 1 - 0.8 * k,
          child: Transform.translate(
            offset: Offset(0, o.clamp(0, 600) * 0.32),
            child: Transform.scale(scale: 1 - 0.12 * k, child: child),
          ),
        );
      },
      child: entering,
    );
  }
}

class _Clip extends CustomClipper<Path> {
  final double phase;
  final double depth;
  const _Clip(this.phase, this.depth);

  @override
  Path getClip(final Size size) => flowerPath(size, phase, 8, depth);

  @override
  bool shouldReclip(covariant final _Clip old) =>
      old.phase != phase || old.depth != depth;
}

class _ShadowPainter extends CustomPainter {
  final Path path;
  const _ShadowPainter(this.path);

  @override
  void paint(final Canvas canvas, final Size size) {
    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.5), 16, true);
  }

  @override
  bool shouldRepaint(covariant final _ShadowPainter old) => true;
}

/// Portreyi saran iki kesikli, ters dönen kalem halkası + yörünge noktaları.
class _OrbitPainter extends CustomPainter {
  final double t;
  final Color color;
  final double portrait;

  const _OrbitPainter(
      {required this.t, required this.color, required this.portrait});

  @override
  void paint(final Canvas canvas, final Size size) {
    final Offset c = size.center(Offset.zero);
    void ring(final double r, final double turns, final int dashes,
        final double alpha, final double width) {
      final Paint p = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width;
      final double step = 2 * math.pi / dashes;
      final double start = t * 2 * math.pi * turns;
      final Rect rect = Rect.fromCircle(center: c, radius: r);
      for (int i = 0; i < dashes; i++) {
        canvas.drawArc(rect, start + i * step, step * 0.58, false, p);
      }
    }

    ring(portrait * 0.62, 1, 26, 0.5, 1.6);
    ring(portrait * 0.69, -0.6, 18, 0.3, 1.2);

    // Yörüngede gezen küçük noktalar
    final Paint dot = Paint()..color = color.withValues(alpha: 0.85);
    for (int i = 0; i < 3; i++) {
      final double a = t * 2 * math.pi * 2 + i * 2 * math.pi / 3;
      canvas.drawCircle(
          c + Offset(math.cos(a), math.sin(a)) * (portrait * 0.62), 3, dot);
    }
  }

  @override
  bool shouldRepaint(covariant final _OrbitPainter old) =>
      old.t != t || old.color != color || old.portrait != portrait;
}

class _ChipView extends StatelessWidget {
  final LiveChip chip;
  const _ChipView({required this.chip});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final Color bg = chip.accent ? cs.primary : cs.surface.withValues(alpha: 0.88);
    final Color fg = chip.accent ? cs.onPrimary : cs.onSurface;
    return Semantics(
      label: chip.label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(chip.icon, size: 15, color: fg),
          const SizedBox(width: 6),
          Text(chip.label,
              style: Sk.ui(context, size: 12.5, color: fg, weight: FontWeight.w800)),
        ]),
      ),
    );
  }
}
