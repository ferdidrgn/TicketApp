import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Giriş akışının (`login_screen.dart`/`phone_login_page.dart`) sahne
/// panelinde statik bir logo görseli yerine geçen, tamamen programatik
/// ("The Digital Stage" felsefesine uygun — yeni bir görsel asset İCAT
/// EDİLMEDİ) canlı bir kompozisyon: yavaşça süpüren sahne ışığı parıltısı,
/// yukarı doğru süzülen toz/parçacık alanı ve nefes alır gibi kabaran bir
/// ışık halesi içindeki tiyatro maskesi ikonu. `AuthCurtainStage`'in perde
/// açılışıyla ortaya çıkan katmanına (`revealChild`) geçiyor.
///
/// Tüm hareket TEK bir büyük panelde, sürekli ve YAVAŞ (8-14sn döngüler) —
/// "her yere rastgele animasyon" değil, bu akışın tek atmosferik anı.
class AnimatedStageMotif extends StatefulWidget {
  const AnimatedStageMotif({super.key});

  @override
  State<AnimatedStageMotif> createState() => _AnimatedStageMotifState();
}

class _AnimatedStageMotifState extends State<AnimatedStageMotif>
    with TickerProviderStateMixin {
  late final AnimationController _sweepController;
  late final AnimationController _pulseController;
  late final AnimationController _driftController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _pulseController.dispose();
    _driftController.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  WebColors.darkBlueAccent,
                  WebColors.darkBlueBackground,
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _sweepController,
            builder: (final context, final _) => CustomPaint(
              painter: _SpotlightPainter(progress: _sweepController.value),
            ),
          ),
          AnimatedBuilder(
            animation: _driftController,
            builder: (final context, final _) => CustomPaint(
              painter: _ParticleFieldPainter(progress: _driftController.value),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (final context, final child) {
                final scale = 1.0 + (_pulseController.value * 0.05);
                final glow = 0.22 + (_pulseController.value * 0.22);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: WebColors.primaryGold.withOpacity(glow),
                          blurRadius: 90,
                          spreadRadius: 16,
                        ),
                      ],
                    ),
                    child: child,
                  ),
                );
              },
              child: Icon(
                Icons.theater_comedy_rounded,
                size: 120,
                color: WebColors.primaryGold.withOpacity(0.92),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 56,
            child: CustomPaint(painter: _CurtainFoldPainter(fromLeft: true)),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 56,
            child: CustomPaint(painter: _CurtainFoldPainter(fromLeft: false)),
          ),
        ],
      );
}

/// Yavaşça sağa-sola süpüren, yumuşak (bulanık) altın ışık parıltısı —
/// gerçek bir sahne spot ışığının hareketini andırır.
class _SpotlightPainter extends CustomPainter {
  final double progress;
  const _SpotlightPainter({required this.progress});

  @override
  void paint(final Canvas canvas, final Size size) {
    final baseCenter = Offset(size.width / 2, size.height * 0.18);
    for (var i = 0; i < 2; i++) {
      final angle = (progress * 2 * math.pi) + (i * math.pi);
      final sweep = math.sin(angle) * 0.45;
      final beamCenter = Offset(
        baseCenter.dx + sweep * size.width * 0.55,
        baseCenter.dy + (i * size.height * 0.35),
      );
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            WebColors.primaryGold.withOpacity(0.10),
            WebColors.primaryGold.withOpacity(0.0),
          ],
        ).createShader(
            Rect.fromCircle(center: beamCenter, radius: size.width * 0.65));
      canvas.drawRect(Offset.zero & size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant final _SpotlightPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Işığın içinde süzülen toz zerrecikleri gibi, yavaşça yukarı süzülüp
/// alttan sürekli yeniden beliren (döngüsel) küçük altın noktalar.
class _ParticleFieldPainter extends CustomPainter {
  final double progress;
  const _ParticleFieldPainter({required this.progress});

  static final List<_Particle> _particles = List.generate(22, (final i) {
    final rnd = math.Random(i * 97 + 13);
    return _Particle(
      dx: rnd.nextDouble(),
      startY: rnd.nextDouble(),
      speed: 0.4 + rnd.nextDouble() * 0.6,
      radius: 1.0 + rnd.nextDouble() * 1.6,
      opacity: 0.12 + rnd.nextDouble() * 0.3,
    );
  });

  @override
  void paint(final Canvas canvas, final Size size) {
    for (final p in _particles) {
      final y = (p.startY - progress * p.speed) % 1.0;
      final paint = Paint()
        ..color = WebColors.primaryGoldLight.withOpacity(p.opacity);
      canvas.drawCircle(
          Offset(p.dx * size.width, y * size.height), p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant final _ParticleFieldPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _Particle {
  final double dx, startY, speed, radius, opacity;
  const _Particle({
    required this.dx,
    required this.startY,
    required this.speed,
    required this.radius,
    required this.opacity,
  });
}

/// Panelin sol/sağ kenarında, gerçek bir tiyatro perdesinin kıvrımlarını
/// çağrıştıran ince, statik bir karartma + çizgi deseni.
class _CurtainFoldPainter extends CustomPainter {
  final bool fromLeft;
  const _CurtainFoldPainter({required this.fromLeft});

  @override
  void paint(final Canvas canvas, final Size size) {
    final rect = Offset.zero & size;
    final shadePaint = Paint()
      ..shader = LinearGradient(
        begin: fromLeft ? Alignment.centerLeft : Alignment.centerRight,
        end: fromLeft ? Alignment.centerRight : Alignment.centerLeft,
        colors: [
          Colors.black.withOpacity(0.32),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, shadePaint);

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    for (var i = 1; i <= 3; i++) {
      final x = fromLeft ? size.width * (i / 4) : size.width * (1 - i / 4);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant final _CurtainFoldPainter oldDelegate) => false;
}
