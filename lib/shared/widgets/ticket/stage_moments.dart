import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_spacing.dart';

/// Sahne anları — kullanıcının bir aksiyonuna cevap veren, tiyatro
/// geleneğinden gelen tek seferlik küçük keyif animasyonları. Kendiliğinden
/// oynamazlar; azaltılmış hareket açıksa hiç oynamazlar.

/// Favoriye eklerken sahneye gül atılır (seyircinin sanatçıya çiçek atma
/// geleneği). Gül, [origin] widget'ının bulunduğu yerden yukarı doğru bir
/// yay çizerek sahneye (ekranın üst ortasına) uçar, dönerek küçülür;
/// ardından birkaç yaprak savrulur.
void tossRose(final BuildContext origin) {
  if (MediaQuery.maybeOf(origin)?.disableAnimations ?? false) return;
  final OverlayState? overlay = Overlay.maybeOf(origin, rootOverlay: true);
  final RenderObject? box = origin.findRenderObject();
  if (overlay == null || box is! RenderBox || !box.hasSize) return;

  final Offset start = box.localToGlobal(box.size.center(Offset.zero));
  final Color rose = Theme.of(origin).colorScheme.primary;
  HapticFeedback.lightImpact();

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (final context) => _RoseFlight(
      start: start,
      color: rose,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _RoseFlight extends StatefulWidget {
  final Offset start;
  final Color color;
  final VoidCallback onDone;

  const _RoseFlight({
    required this.start,
    required this.color,
    required this.onDone,
  });

  @override
  State<_RoseFlight> createState() => _RoseFlightState();
}

class _RoseFlightState extends State<_RoseFlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);
    // Sahne: ekranın üst üçte birinin ortası.
    final Offset stage = Offset(screen.width / 2, screen.height * 0.28);
    final Offset start = widget.start;
    // Yayın tepe noktası: iki noktanın ortasının epey üstü.
    final Offset control = Offset(
      (start.dx + stage.dx) / 2,
      math.min(start.dy, stage.dy) - screen.height * 0.18,
    );

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (final context, final _) {
          final double t = _c.value;
          final double flight = Curves.easeOutCubic
              .transform((t / 0.72).clamp(0.0, 1.0));
          final Offset p = _bezier(start, control, stage, flight);
          final double fade = t < 0.72 ? 1 : 1 - (t - 0.72) / 0.28;
          final double scale = 1.25 - 0.55 * flight;

          return Stack(
            children: [
              // Gül
              Positioned(
                left: p.dx - 23,
                top: p.dy - 23,
                child: Opacity(
                  opacity: fade.clamp(0.0, 1.0),
                  child: Transform.rotate(
                    angle: -math.pi * 1.6 * flight,
                    child: Transform.scale(
                      scale: scale,
                      child: Icon(Icons.local_florist_rounded,
                          size: 46, color: widget.color),
                    ),
                  ),
                ),
              ),
              // Sahneye değdiğinde savrulan yapraklar
              if (t > 0.66)
                for (int i = 0; i < 6; i++)
                  _petal(stage, i, ((t - 0.66) / 0.34).clamp(0.0, 1.0)),
            ],
          );
        },
      ),
    );
  }

  Widget _petal(final Offset at, final int i, final double k) {
    final double angle = -math.pi / 2 + (i - 2.5) * 0.55;
    final double dist = AppSpacing.huge * Curves.easeOut.transform(k);
    final Offset p = at +
        Offset(math.cos(angle), math.sin(angle)) * dist +
        Offset(0, 30 * k * k); // yerçekimi
    return Positioned(
      left: p.dx - 4,
      top: p.dy - 3,
      child: Opacity(
        opacity: (1 - k).clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: angle + k * 3,
          child: Container(
            width: 8,
            height: 5,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: const BorderRadius.all(Radius.elliptical(8, 5)),
            ),
          ),
        ),
      ),
    );
  }

  static Offset _bezier(
      final Offset a, final Offset b, final Offset c, final double t) {
    final double u = 1 - t;
    return a * (u * u) + b * (2 * u * t) + c * (t * t);
  }
}

/// ÜÇ GONG — Türk tiyatrosunda oyun üç gongla başlar. Belirsiz süreli
/// bekleme göstergesi: gonglar sırayla çalar (dolar, halkası yayılır),
/// üçüncüsünden sonra kısa bir "PERDE" anı ve döngü baştan. Bilet
/// kağıdına basılı durur ([color] mürekkep/vurgu rengi). Azaltılmış
/// harekette üç gong sabit dolu görünür.
class ThreeGongIndicator extends StatefulWidget {
  final Color color;
  final Color? labelColor;

  const ThreeGongIndicator({super.key, required this.color, this.labelColor});

  @override
  State<ThreeGongIndicator> createState() => _ThreeGongIndicatorState();
}

class _ThreeGongIndicatorState extends State<ThreeGongIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 0.8;
    } else {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final Color label = widget.labelColor ?? widget.color;
    return Semantics(
      label: 'Yükleniyor',
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (final context, final _) {
            // 0–3: gonglar sırayla, 3–4: perde anı (üçü dolu).
            final double phase = _c.value * 4;
            final int struck = phase.floor().clamp(0, 3);
            final String text = struck >= 3 ? 'PERDE' : '${struck + 1}. GONG';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CustomPaint(
                      painter: _GongPainter(
                        color: widget.color,
                        lit: phase >= i,
                        // Bu gongun çaldığı saniyedeki halka yayılımı.
                        ring: phase >= i && phase < i + 1 ? phase - i : null,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: AppSpacing.md),
                SizedBox(
                  width: 64,
                  child: Text(
                    text,
                    style: TextStyle(
                      color: label,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GongPainter extends CustomPainter {
  final Color color;
  final bool lit;
  final double? ring;

  const _GongPainter({required this.color, required this.lit, this.ring});

  @override
  void paint(final Canvas canvas, final Size size) {
    final Offset c = size.center(Offset.zero);
    const double r = 6;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = lit ? color : color.withValues(alpha: 0.18)
        ..style = lit ? PaintingStyle.fill : PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    final double? k = ring;
    if (k != null) {
      final double e = Curves.easeOutCubic.transform(k.clamp(0.0, 1.0));
      canvas.drawCircle(
        c,
        r + e * (size.shortestSide / 2 - r),
        Paint()
          ..color = color.withValues(alpha: (1 - e) * 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
  }

  @override
  bool shouldRepaint(covariant final _GongPainter old) =>
      old.lit != lit || old.ring != ring || old.color != color;
}
