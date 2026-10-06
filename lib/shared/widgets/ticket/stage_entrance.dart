import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../optimized_cached_image.dart';

/// Detayın tek sahne anı: karanlıkta duran gerçek afiş/portre, iki kanat
/// perspektif ile açılır, görsel yerinde kalır (büyümez — amatör "sticker"
/// hissi yok), sonra örtü sayfaya karışır.
class StageEntrance extends StatefulWidget {
  final String? imageUrl;
  final String label;
  final bool portrait;
  final Widget child;

  const StageEntrance({
    super.key,
    required this.label,
    required this.child,
    this.imageUrl,
    this.portrait = false,
  });

  @override
  State<StageEntrance> createState() => _StageEntranceState();
}

class _StageEntranceState extends State<StageEntrance>
    with SingleTickerProviderStateMixin {
  static const Duration _beat = Duration(milliseconds: 2100);

  late final AnimationController _c =
      AnimationController(vsync: this, duration: _beat);
  bool _reduce = false;
  bool _started = false;
  bool _done = false;

  OverlayEntry? _entry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.of(context).disableAnimations;
    if (_reduce) {
      _done = true;
      _c.value = 1;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((final _) => _play());
  }

  @override
  void dispose() {
    _dropOverlay();
    _c.dispose();
    super.dispose();
  }

  void _dropOverlay() {
    _entry?.remove();
    _entry = null;
  }

  void _play() {
    if (_started || !mounted) return;
    _started = true;
    if (_reduce) {
      setState(() => _done = true);
      return;
    }
    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      setState(() => _done = true);
      return;
    }
    HapticFeedback.lightImpact();
    _c.addListener(() => _entry?.markNeedsBuild());
    final ThemeData theme = Theme.of(context);
    _entry = OverlayEntry(
      builder: (final _) => Theme(
        data: theme,
        child: Material(
          type: MaterialType.transparency,
          child: GestureDetector(
            onTap: _skip,
            child: _Reveal(
              t: _c.value,
              imageUrl: widget.imageUrl?.trim() ?? '',
              label: widget.label,
              portrait: widget.portrait,
            ),
          ),
        ),
      ),
    );
    overlay.insert(_entry!);
    _c.forward().whenComplete(() {
      _dropOverlay();
      if (mounted) setState(() => _done = true);
    });
  }

  void _skip() {
    if (_done) return;
    _c.value = 1;
    _dropOverlay();
    setState(() => _done = true);
  }

  @override
  Widget build(final BuildContext context) => widget.child;
}

double _unit(final double t, final double a, final double b) {
  if (t <= a) return 0;
  if (t >= b) return 1;
  return ((t - a) / (b - a)).clamp(0.0, 1.0);
}

class _Reveal extends StatelessWidget {
  final double t;
  final String imageUrl;
  final String label;
  final bool portrait;

  const _Reveal({
    required this.t,
    required this.imageUrl,
    required this.label,
    required this.portrait,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double open = Curves.easeInOutCubic.transform(_unit(t, 0.02, 0.58));
    final double settle = AppMotion.elegant.transform(_unit(t, 0.08, 0.7));
    final double nameIn = AppMotion.elegant.transform(_unit(t, 0.42, 0.7));
    final double fade = Curves.easeIn.transform(_unit(t, 0.72, 1.0));
    final bool hasImage = imageUrl.isNotEmpty;
    final Color cloth = Color.lerp(cs.surface, cs.primary, 0.42)!;
    final Color floor = Color.lerp(cs.surface, Colors.black, 0.82)!;
    final Color titleColor =
        floor.computeLuminance() < 0.4 ? cs.onInverseSurface : cs.onSurface;

    return Semantics(
      label: '$label sahneye çıkıyor',
      child: LayoutBuilder(
        builder: (final context, final box) {
          final double w = box.maxWidth;
          final double h = box.maxHeight;
          final double posterH = math.min(h * 0.58, portrait ? 420 : 380);
          final double posterW = posterH * (portrait ? 0.72 : 0.68);

          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: floor.withValues(alpha: 1 - fade)),
              if (hasImage)
                Align(
                  alignment: const Alignment(0, -0.08),
                  child: Opacity(
                    opacity: (1 - fade).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 1.06 - 0.06 * settle,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Poster(
                            url: imageUrl,
                            label: label,
                            width: posterW,
                            height: posterH,
                          ),
                          const SizedBox(height: 20),
                          Opacity(
                            opacity: nameIn,
                            child: SizedBox(
                              width: math.min(w - 48, 320),
                              child: Text(
                                label,
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.playfairDisplay(
                                      color: titleColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              IgnorePointer(
                child: Opacity(
                  opacity: ((1 - open) * 0.35 + 0.12) * (1 - fade),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.35),
                        radius: 0.85,
                        colors: [
                          cs.primary.withValues(alpha: 0.22),
                          cs.tertiary.withValues(alpha: 0.06),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Sol kanat
              _Wing(
                left: true,
                open: open,
                fade: fade,
                cloth: cloth,
                width: w * 0.52,
                height: h,
              ),
              _Wing(
                left: false,
                open: open,
                fade: fade,
                cloth: cloth,
                width: w * 0.52,
                height: h,
              ),
              // Ortadaki ışık çizgisi — perde aralandıkça solar.
              IgnorePointer(
                child: Opacity(
                  opacity: ((1 - open) * 0.9).clamp(0.0, 1.0) * (1 - fade),
                  child: Align(
                    child: Container(
                      width: 2,
                      height: h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            cs.primary.withValues(alpha: 0.85),
                            cs.onPrimary.withValues(alpha: 0.4),
                            cs.primary.withValues(alpha: 0.85),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cs.primary.withValues(alpha: 0.45),
                            blurRadius: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Wing extends StatelessWidget {
  final bool left;
  final double open;
  final double fade;
  final Color cloth;
  final double width;
  final double height;

  const _Wing({
    required this.left,
    required this.open,
    required this.fade,
    required this.cloth,
    required this.width,
    required this.height,
  });

  @override
  Widget build(final BuildContext context) {
    final double slide = open * width * 0.98;
    final Matrix4 m = Matrix4.identity()
      ..setEntry(3, 2, 0.0009)
      ..translate(left ? -slide : slide)
      ..rotateY(left ? -open * 0.42 : open * 0.42);
    return Positioned(
      left: left ? 0 : null,
      right: left ? null : 0,
      top: 0,
      bottom: 0,
      child: Opacity(
        opacity: 1 - fade,
        child: Transform(
          alignment: left ? Alignment.centerLeft : Alignment.centerRight,
          transform: m,
          child: SizedBox(
            width: width,
            height: height,
            child: CustomPaint(painter: _ClothPainter(color: cloth, left: left)),
          ),
        ),
      ),
    );
  }
}

/// Kumaş: üç geniş kıvrım, çizgi çizilmez.
class _ClothPainter extends CustomPainter {
  final Color color;
  final bool left;

  const _ClothPainter({required this.color, required this.left});

  @override
  void paint(final Canvas canvas, final Size size) {
    final Rect rect = Offset.zero & size;
    final Color deep = Color.lerp(color, Colors.black, 0.55)!;
    final Color mid = Color.lerp(color, Colors.black, 0.22)!;
    final Color lift = Color.lerp(color, Colors.white, 0.06)!;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: left ? Alignment.centerRight : Alignment.centerLeft,
          end: left ? Alignment.centerLeft : Alignment.centerRight,
          colors: [deep, mid, lift, mid, deep],
          stops: const [0, 0.22, 0.48, 0.74, 1],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.28),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.38),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant final _ClothPainter old) =>
      old.color != color || old.left != left;
}

class _Poster extends StatelessWidget {
  final String url;
  final String label;
  final double width;
  final double height;

  const _Poster({
    required this.url,
    required this.label,
    required this.width,
    required this.height,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      image: true,
      label: label,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.lift(cs.shadow, bloom: cs.primary),
        ),
        clipBehavior: Clip.antiAlias,
        child: OptimizedCachedImage(
          imageUrl: url,
          fit: BoxFit.cover,
          borderRadius: 0,
        ),
      ),
    );
  }
}

class StageSpotFrame extends StatelessWidget {
  final Widget child;
  const StageSpotFrame({super.key, required this.child});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.4),
                  radius: 1.1,
                  colors: [
                    cs.primary.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

Widget partingCurtainTransition(
  final BuildContext context,
  final Animation<double> animation,
  final Animation<double> secondaryAnimation,
  final Widget child,
) {
  if (MediaQuery.of(context).disableAnimations) return child;
  final ColorScheme cs = Theme.of(context).colorScheme;
  final Animation<double> open = CurvedAnimation(
    parent: animation,
    curve: AppMotion.dramatic,
  );
  return AnimatedBuilder(
    animation: open,
    builder: (final context, final page) {
      final double t = open.value;
      final Color cloth = Color.lerp(cs.surface, cs.primary, 0.42)!;
      return LayoutBuilder(
        builder: (final context, final box) => Stack(
          fit: StackFit.expand,
          children: [
            FadeTransition(opacity: open, child: page),
            _Wing(
              left: true,
              open: t,
              fade: 0,
              cloth: cloth,
              width: box.maxWidth * 0.52,
              height: box.maxHeight,
            ),
            _Wing(
              left: false,
              open: t,
              fade: 0,
              cloth: cloth,
              width: box.maxWidth * 0.52,
              height: box.maxHeight,
            ),
          ],
        ),
      );
    },
    child: child,
  );
}
