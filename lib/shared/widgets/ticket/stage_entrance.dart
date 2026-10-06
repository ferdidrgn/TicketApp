import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../optimized_cached_image.dart';

/// Oyun / oyuncu detayının TEK sahne anı: perde iki yana açılır, gerçek
/// afiş veya portre ortadan büyür, iki yandan spot düşer, görsel üste
/// oturur, örtü solar. Azaltılmış harekette hiç oynamaz. Perde/spot
/// süs olarak kalmaz — yalnızca bu girişte.
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
  static const Duration _beat = Duration(milliseconds: 1800);

  late final AnimationController _c =
      AnimationController(vsync: this, duration: _beat);
  bool _reduce = false;
  bool _started = false;
  bool _done = false;
  bool _midHaptic = false;

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
    HapticFeedback.mediumImpact();
    _c.addListener(() {
      _entry?.markNeedsBuild();
      if (!mounted || _midHaptic) return;
      if (_c.value >= 0.36) {
        _midHaptic = true;
        HapticFeedback.lightImpact();
      }
    });
    final ThemeData theme = Theme.of(context);
    _entry = OverlayEntry(
      builder: (final _) => Theme(
        data: theme,
        child: Material(
          type: MaterialType.transparency,
          child: GestureDetector(
            onTap: _skip,
            child: _StagePaint(
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

double _interval(final double t, final double a, final double b) {
  if (t <= a) return 0;
  if (t >= b) return 1;
  return ((t - a) / (b - a)).clamp(0.0, 1.0);
}

class _StagePaint extends StatelessWidget {
  final double t;
  final String imageUrl;
  final String label;
  final bool portrait;

  const _StagePaint({
    required this.t,
    required this.imageUrl,
    required this.label,
    required this.portrait,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double open =
        Curves.easeInOutQuart.transform(_interval(t, 0.0, 0.38));
    final double spots = Curves.easeOut.transform(_interval(t, 0.22, 0.52));
    final double grow = AppMotion.overshoot.transform(_interval(t, 0.28, 0.68));
    final double rise =
        Curves.easeInOutCubic.transform(_interval(t, 0.55, 0.84));
    final double fade = Curves.easeIn.transform(_interval(t, 0.80, 1.0));
    final bool hasImage = imageUrl.isNotEmpty;

    final Color velvet = Color.lerp(cs.primary, cs.surface, 0.16)!;
    final Color floor = Color.lerp(cs.surface, Colors.black, 0.78)!;

    return Semantics(
      label: '$label sahneye çıkıyor',
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: floor.withValues(alpha: 1 - fade)),
          IgnorePointer(
            child: Opacity(
              opacity: (spots * (1 - fade)).clamp(0.0, 1.0),
              child: CustomPaint(
                painter: _TwinSpotsPainter(
                  left: cs.tertiary.withValues(alpha: 0.62),
                  right: cs.primary.withValues(alpha: 0.55),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          if (hasImage)
            Align(
              alignment: Alignment.lerp(
                    Alignment.center,
                    const Alignment(0, -0.68),
                    rise,
                  ) ??
                  Alignment.center,
              child: Opacity(
                opacity: ((grow * 1.2).clamp(0.0, 1.0) * (1 - fade)),
                child: Transform.scale(
                  scale: 0.08 + grow * 0.92,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _EntrancePortrait(
                        url: imageUrl,
                        label: label,
                        portrait: portrait,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        label,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.playfairDisplay(
                          color: cs.onPrimary.withValues(alpha: 0.95),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1.12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.54 * (1 - open),
              heightFactor: 1,
              child: Opacity(
                opacity: 1 - fade,
                child: _CurtainWing(color: velvet, left: true),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.54 * (1 - open),
              heightFactor: 1,
              child: Opacity(
                opacity: 1 - fade,
                child: _CurtainWing(color: velvet, left: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurtainWing extends StatelessWidget {
  final Color color;
  final bool left;

  const _CurtainWing({required this.color, required this.left});

  @override
  Widget build(final BuildContext context) => CustomPaint(
        painter: _FoldPainter(color: color, left: left),
        child: const SizedBox.expand(),
      );
}

class _FoldPainter extends CustomPainter {
  final Color color;
  final bool left;

  const _FoldPainter({required this.color, required this.left});

  @override
  void paint(final Canvas canvas, final Size size) {
    final Rect rect = Offset.zero & size;
    final Paint fill = Paint()
      ..shader = LinearGradient(
        begin: left ? Alignment.centerRight : Alignment.centerLeft,
        end: left ? Alignment.centerLeft : Alignment.centerRight,
        colors: [
          Color.lerp(color, Colors.black, 0.35)!,
          color,
          Color.lerp(color, Colors.black, 0.22)!,
          color,
        ],
        stops: const [0, 0.28, 0.62, 1],
      ).createShader(rect);
    canvas.drawRect(rect, fill);

    final Paint fold = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..strokeWidth = 1;
    const int n = 7;
    for (int i = 1; i < n; i++) {
      final double x = size.width * (i / n);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), fold);
    }
  }

  @override
  bool shouldRepaint(covariant final _FoldPainter old) =>
      old.color != color || old.left != left;
}

class _TwinSpotsPainter extends CustomPainter {
  final Color left;
  final Color right;

  const _TwinSpotsPainter({required this.left, required this.right});

  @override
  void paint(final Canvas canvas, final Size size) {
    void cone(final Offset c, final Color col) {
      final Paint p = Paint()
        ..shader = RadialGradient(
          colors: [
            col,
            col.withValues(alpha: 0.18),
            col.withValues(alpha: 0),
          ],
          stops: const [0, 0.42, 1],
        ).createShader(Rect.fromCircle(center: c, radius: size.shortestSide * 0.85));
      canvas.drawCircle(c, size.shortestSide * 0.85, p);
    }

    cone(Offset(size.width * 0.12, size.height * 0.18), left);
    cone(Offset(size.width * 0.88, size.height * 0.18), right);
  }

  @override
  bool shouldRepaint(covariant final _TwinSpotsPainter old) =>
      old.left != left || old.right != right;
}

class _EntrancePortrait extends StatelessWidget {
  final String url;
  final String label;
  final bool portrait;

  const _EntrancePortrait({
    required this.url,
    required this.label,
    required this.portrait,
  });

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final double w = portrait ? 200.0 : 176.0;
    final double h = portrait ? 268.0 : 252.0;
    return Semantics(
      image: true,
      label: label,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.level5(cs.shadow),
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

/// Afiş / portre arkasında iki yandan düşen, temaya bağlı spot (sürekli
/// dönmez; yalnızca hero çerçevesinde durur).
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
            child: CustomPaint(
              painter: _TwinSpotsPainter(
                left: cs.tertiary.withValues(alpha: 0.22),
                right: cs.primary.withValues(alpha: 0.18),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Oyun/oyuncu rotası: iki kanatlı perde (router geçişi). İçerik
/// [StageEntrance] ile büyür; bu yalnızca sahneye adım atma.
Widget partingCurtainTransition(
  final BuildContext context,
  final Animation<double> animation,
  final Animation<double> secondaryAnimation,
  final Widget child,
) {
  final ColorScheme cs = Theme.of(context).colorScheme;
  final Animation<double> open = CurvedAnimation(
    parent: animation,
    curve: AppMotion.dramatic,
  );
  if (MediaQuery.of(context).disableAnimations) return child;

  return AnimatedBuilder(
    animation: open,
    builder: (final context, final page) {
      final double t = open.value;
      final Color velvet = Color.lerp(cs.primary, cs.surface, 0.18)!;
      return Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(opacity: open, child: page),
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: 0.5 * (1 - t),
              heightFactor: 1,
              child: Opacity(
                opacity: (1 - t).clamp(0.0, 1.0),
                child: _CurtainWing(color: velvet, left: true),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5 * (1 - t),
              heightFactor: 1,
              child: Opacity(
                opacity: (1 - t).clamp(0.0, 1.0),
                child: _CurtainWing(color: velvet, left: false),
              ),
            ),
          ),
        ],
      );
    },
    child: child,
  );
}

