import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';

class ImmersiveBackground extends StatelessWidget {
  /// Işık toplarının renkleri (3 adet renk bekler)
  final List<Color> lightColors;

  /// Parçacık yoğunluğu
  final int particleCount;

  /// Blur miktarı
  final double blurAmount;

  const ImmersiveBackground({
    super.key,
    required this.lightColors,
    this.particleCount = 15,
    this.blurAmount = 30,
  });

  // --- FABRIKA KURUCULARI (Kolay Kullanım İçin) ---

  /// Search Sayfası için "Mistik" varyasyon
  static Widget search(final BuildContext context) => ImmersiveBackground(
        particleCount: 15, // Daha sakin
        blurAmount: 30,
        lightColors: [
          context.isDarkMode
              ? const Color(0xFF4A148C)
              : const Color(0xFFE1BEE7), // Mor
          context.isDarkMode
              ? const Color(0xFF1A237E)
              : const Color(0xFFBBDEFB), // Mavi
          context.isDarkMode
              ? const Color(0xFF004D40)
              : const Color(0xFFB2DFDB), // Turkuaz
        ],
      );

  /// Home Sayfası için "Canlı" varyasyon
  static Widget home(final BuildContext context) => ImmersiveBackground(
        particleCount: 25, // Daha canlı
        blurAmount: 20,
        lightColors: [
          context.primaryColor.withOpacity(0.5),
          context.colors.secondary.withOpacity(0.4),
          context.colors.tertiary.withOpacity(0.4),
        ],
      );

  @override
  Widget build(final BuildContext context) => Stack(
        children: [
          // 1. Ana Zemin
          Container(color: context.scaffoldBackgroundColor),

          // 2. Ortam Işıkları
          _AmbientLights(colors: lightColors),

          // 3. Uçuşan Parçacıklar
          _FloatingParticles(count: particleCount),

          // 4. Blur Efekti (Cam hissiyatı)
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurAmount, sigmaY: blurAmount),
            child: Container(color: Colors.transparent),
          ),

          // 5. Hafif Karartma/Dengeleme
          Container(color: context.scaffoldBackgroundColor.withOpacity(0.3)),
        ],
      );
}

// --- ALT BİLEŞENLER (Private) ---

class _AmbientLights extends StatelessWidget {
  final List<Color> colors;

  const _AmbientLights({required this.colors});

  @override
  Widget build(final BuildContext context) {
    // Eğer renk listesi eksikse fallback yap
    final c1 = colors.isNotEmpty ? colors[0] : Colors.blue;
    final c2 = colors.length > 1 ? colors[1] : Colors.purple;
    final c3 = colors.length > 2 ? colors[2] : Colors.teal;

    return Stack(
      children: [
        // Sol Üst
        Positioned(
          top: -100,
          left: -100,
          child: _LightOrb(color: c1, size: 400),
        ),
        // Sağ Orta
        Positioned(
          top: 300,
          right: -150,
          child: _LightOrb(color: c2, size: 500),
        ),
        // Sol Alt
        Positioned(
          bottom: -100,
          left: -50,
          child: _LightOrb(color: c3, size: 350),
        ),
      ],
    );
  }
}

class _LightOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _LightOrb({required this.color, required this.size});

  @override
  Widget build(final BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withOpacity(0.4), Colors.transparent],
            radius: 0.6,
          ),
        ),
      );
}

class _FloatingParticles extends StatefulWidget {
  final int count;

  const _FloatingParticles({required this.count});

  @override
  State<_FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<_FloatingParticles>
    with SingleTickerProviderStateMixin {
  late final _controller =
      AnimationController(vsync: this, duration: const Duration(minutes: 2))
        ..repeat();
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.count; i++) _particles.add(_Particle());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (final _, final __) => CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(
              particles: _particles,
              progress: _controller.value,
              color: context.colors.onSurface.withOpacity(0.07)),
        ),
      );
}

class _Particle {
  late double x, y, speed, size, opacity;

  _Particle() {
    reset(true);
  }

  void reset(final bool randomY) {
    final r = math.Random();
    x = r.nextDouble();
    y = randomY ? r.nextDouble() : 1.1;
    speed = 0.1 + r.nextDouble() * 0.2;
    size = 2.0 + r.nextDouble() * 4.0;
    opacity = 0.1 + r.nextDouble() * 0.4;
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter(
      {required this.particles, required this.progress, required this.color});

  @override
  void paint(final Canvas canvas, final Size size) {
    final paint = Paint()..color = color;
    for (var p in particles) {
      double dy = p.y - (progress * p.speed * 10);
      dy = dy % 1.2;
      if (dy < -0.2) dy = 1.1;
      final dx = p.x + math.sin(progress * 2 * math.pi + p.y) * 0.05;
      paint.color = color.withOpacity(p.opacity);
      canvas.drawCircle(
          Offset(dx * size.width, dy * size.height), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant final CustomPainter old) => true;
}
