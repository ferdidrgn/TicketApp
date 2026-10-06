import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_motion.dart';

/// Karttaki afişin detay tepesine büyümesi. Köşe yayı yerine merkez yayı:
/// oran uçuşta ezilmez (Flutter radial/shared-element önerisi).
Tween<Rect?> stageHeroRectTween(final Rect? begin, final Rect? end) {
  if (begin == null || end == null) {
    return RectTween(begin: begin, end: end);
  }
  return MaterialRectCenterArcTween(begin: begin, end: end);
}

class StageHero extends StatelessWidget {
  final String tag;
  final Widget child;
  const StageHero({super.key, required this.tag, required this.child});

  @override
  Widget build(final BuildContext context) => Hero(
        tag: tag,
        createRectTween: stageHeroRectTween,
        child: child,
      );
}

/// Detaya geçiş: perde yok. Görsel [StageHero] ile karttan sayfanın tepesine
/// uçar. Bu örtü yalnızca iki sahne spotunu kısa süre yakar, sonra solar.
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
  late final AnimationController _c =
      AnimationController(vsync: this, duration: AppMotion.slow);
  bool _reduce = false;
  bool _started = false;
  OverlayEntry? _entry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.of(context).disableAnimations;
    if (_reduce) {
      _c.value = 1;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((final _) => _play());
  }

  @override
  void dispose() {
    _drop();
    _c.dispose();
    super.dispose();
  }

  void _drop() {
    _entry?.remove();
    _entry = null;
  }

  void _play() {
    if (_started || !mounted) {
      return;
    }
    _started = true;
    if (_reduce) {
      return;
    }
    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return;
    }
    HapticFeedback.selectionClick();
    _c.addListener(() => _entry?.markNeedsBuild());
    final ColorScheme cs = Theme.of(context).colorScheme;
    _entry = OverlayEntry(
      builder: (final _) {
        final double t = _c.value;
        final double in_ = Curves.easeOut.transform((t / 0.35).clamp(0.0, 1.0));
        final double out_ = t < 0.55
            ? 1
            : (1 - ((t - 0.55) / 0.45).clamp(0.0, 1.0));
        final double a = in_ * out_;
        return IgnorePointer(
          child: CustomPaint(
            painter: _SpotPainter(
              left: cs.tertiary.withValues(alpha: 0.38 * a),
              right: cs.primary.withValues(alpha: 0.32 * a),
            ),
            child: const SizedBox.expand(),
          ),
        );
      },
    );
    overlay.insert(_entry!);
    _c.forward().whenComplete(_drop);
  }

  @override
  Widget build(final BuildContext context) => widget.child;
}

class _SpotPainter extends CustomPainter {
  final Color left;
  final Color right;

  const _SpotPainter({required this.left, required this.right});

  @override
  void paint(final Canvas canvas, final Size size) {
    void beam(final Offset origin, final Color col) {
      final double r = size.longestSide * 0.72;
      canvas.drawCircle(
        origin,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [col, col.withValues(alpha: 0)],
            stops: const [0, 1],
          ).createShader(Rect.fromCircle(center: origin, radius: r)),
      );
    }

    beam(Offset(size.width * 0.18, -size.height * 0.02), left);
    beam(Offset(size.width * 0.82, -size.height * 0.02), right);
  }

  @override
  bool shouldRepaint(covariant final _SpotPainter old) =>
      old.left != left || old.right != right;
}

/// Afiş arkasında duran, temaya bağlı iki koni — sürekli yanıp sönmez.
class StageSpotFrame extends StatelessWidget {
  final Widget child;
  const StageSpotFrame({super.key, required this.child});

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _SpotPainter(
                left: cs.tertiary.withValues(alpha: 0.16),
                right: cs.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

/// Oyun/oyuncu rotası: sade solma — [Hero] afişi karttan tepeye taşır.
Widget partingCurtainTransition(
  final BuildContext context,
  final Animation<double> animation,
  final Animation<double> secondaryAnimation,
  final Widget child,
) =>
    FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: AppMotion.standard),
      child: child,
    );
