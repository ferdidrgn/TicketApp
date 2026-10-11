import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sahne_kit.dart';

/// Yaprak (çiçek) kenarlı portre — oyuncu kartı.
///
/// Material 3 Expressive'in "çiçek / kurabiye" şekil dilinden esinlenir:
/// kenar [lobes] adet yumuşak yapraktan oluşur. Hareket:
/// - boşta: yapraklar çok yavaş döner (portre dik kalır) — [live] ise;
/// - üstüne gelince/basınca: yapraklar derinleşir, bir tur atar, kart
///   hafifçe küçülür; bırakınca yaylanarak döner.
/// Azaltılmış harekette (`disableAnimations`) dönme ve nabız durur.
/// Renkler temadan; fotoğraf yoksa `primaryContainer` zemin + kişi ikonu.
class SkFlowerPortrait extends StatefulWidget {
  final String imageUrl;
  final double size;
  final int lobes;
  final bool live;
  final VoidCallback? onTap;
  final String semanticLabel;

  /// Portre üstüne binen üst rozet (ör. "3 oyun") ve alt rozet ("Sahnede").
  final String? topChip;
  final String? bottomChip;
  final bool bottomChipAccent;

  /// Portrenin altındaki ad (vurgulu arama için özel widget verilebilir).
  final Widget title;
  final String? subtitle;

  /// Hero uçuşu için sarmalayıcı (ör. `TiyatrolHero`) — verilirse portre
  /// bununla sarılır.
  final Widget Function(Widget child)? heroWrap;

  const SkFlowerPortrait({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.semanticLabel,
    this.size = 128,
    this.lobes = 8,
    this.live = true,
    this.onTap,
    this.topChip,
    this.bottomChip,
    this.bottomChipAccent = false,
    this.subtitle,
    this.heroWrap,
  });

  @override
  State<SkFlowerPortrait> createState() => _SkFlowerPortraitState();
}

class _SkFlowerPortraitState extends State<SkFlowerPortrait>
    with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 22),
  );
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  bool _down = false;
  bool _hover = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.live && !Sk.reduceMotion(context)) {
      if (!_idle.isAnimating) _idle.repeat();
    } else {
      _idle.stop();
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _press.dispose();
    super.dispose();
  }

  void _setDown(final bool v) {
    if (_down == v) return;
    setState(() => _down = v);
    if (v && !Sk.reduceMotion(context)) {
      _press.forward(from: 0);
    }
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double s = widget.size;
    final bool reduce = Sk.reduceMotion(context);

    final Widget flower = AnimatedBuilder(
      animation: Listenable.merge([_idle, _press]),
      builder: (final context, _) {
        final double press = Curves.easeOutBack.transform(_press.value);
        final double phase = _idle.value * 2 * math.pi +
            (reduce ? 0 : press * math.pi / widget.lobes * 2);
        final double depth = 0.24 + (_hover || _down ? 0.07 : 0);
        final Path shadowPath =
            flowerPath(Size.square(s), phase, widget.lobes, depth);
        return Transform.scale(
          scale: _down ? 0.95 : 1,
          child: SizedBox(
            width: s,
            height: s,
            child: CustomPaint(
              painter: _FlowerShadow(
                path: shadowPath,
                color: Colors.black.withValues(alpha: 0.28),
              ),
              child: ClipPath(
                clipper: _FlowerClipper(phase, widget.lobes, depth),
                child: Container(
                  color: cs.primaryContainer,
                  child: SkImage(
                    url: widget.imageUrl,
                    width: s,
                    height: s,
                    fallbackIcon: Icons.person_rounded,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    final Widget portrait = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        widget.heroWrap != null ? widget.heroWrap!(flower) : flower,
        if (widget.topChip != null)
          Positioned(
            top: -9,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
              decoration: BoxDecoration(
                color: cs.inverseSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(widget.topChip!,
                  style: Sk.ui(context,
                      size: 11,
                      color: cs.onInverseSurface,
                      weight: FontWeight.w800)),
            ),
          ),
        if (widget.bottomChip != null)
          Positioned(
            bottom: -11,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: widget.bottomChipAccent ? cs.primary : cs.surface,
                borderRadius: BorderRadius.circular(11),
                boxShadow: skSoftShadow(context, strength: 0.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (widget.bottomChipAccent) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color: cs.onPrimary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 5),
                ],
                Text(widget.bottomChip!,
                    style: Sk.ui(context,
                        size: 11,
                        color: widget.bottomChipAccent
                            ? cs.onPrimary
                            : cs.onSurface,
                        weight: FontWeight.w800)),
              ]),
            ),
          ),
      ],
    );

    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: widget.onTap == null
            ? MouseCursor.defer
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setDown(true),
          onTapCancel: () => _setDown(false),
          onTapUp: (_) => _setDown(false),
          onTap: widget.onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  widget.onTap!();
                },
          child: SizedBox(
            width: s + 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                portrait,
                SizedBox(height: widget.bottomChip != null ? 20 : 12),
                DefaultTextStyle.merge(
                  textAlign: TextAlign.center,
                  child: widget.title,
                ),
                if (widget.subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(widget.subtitle!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Sk.ui(context,
                            size: 11.5,
                            color: cs.onSurfaceVariant,
                            weight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Yapraklı kapalı yol: yarıçap `R * (1 - depth/2 * (1 - cos(lobes*t + phase)))`.
Path flowerPath(final Size size, final double phase, final int lobes,
    final double depth) {
  final Offset c = size.center(Offset.zero);
  final double r = size.shortestSide / 2;
  const int steps = 200;
  final Path p = Path();
  for (int i = 0; i <= steps; i++) {
    final double t = i / steps * 2 * math.pi;
    final double k = math.cos(lobes * t + phase);
    final double rad = r * (1 - depth / 2 * (1 - k));
    final Offset o = c + Offset(math.cos(t) * rad, math.sin(t) * rad);
    if (i == 0) {
      p.moveTo(o.dx, o.dy);
    } else {
      p.lineTo(o.dx, o.dy);
    }
  }
  return p..close();
}

class _FlowerClipper extends CustomClipper<Path> {
  final double phase;
  final int lobes;
  final double depth;

  const _FlowerClipper(this.phase, this.lobes, this.depth);

  @override
  Path getClip(final Size size) => flowerPath(size, phase, lobes, depth);

  @override
  bool shouldReclip(covariant final _FlowerClipper old) =>
      old.phase != phase || old.lobes != lobes || old.depth != depth;
}

class _FlowerShadow extends CustomPainter {
  final Path path;
  final Color color;

  const _FlowerShadow({required this.path, required this.color});

  @override
  void paint(final Canvas canvas, final Size size) {
    canvas.drawShadow(path, color, 8, true);
  }

  @override
  bool shouldRepaint(covariant final _FlowerShadow old) => old.path != path;
}
