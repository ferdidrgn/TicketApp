// PARTİKÜL DECORATION WIDGET
import 'dart:math';
import 'package:flutter/material.dart';

class ParticleDecoration extends StatefulWidget {
  final bool isPast;
  final ThemeData theme;

  const ParticleDecoration({super.key, required this.isPast, required this.theme});

  @override
  State<ParticleDecoration> createState() => _ParticleDecorationState();
}

class _ParticleDecorationState extends State<ParticleDecoration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);

    // Partikülleri oluştur
    for (int i = 0; i < 8; i++) _particles.add(Particle());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (final context, final child) {
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: widget.isPast
                  ? [Colors.grey.shade400, Colors.grey.shade600]
                  : [
                      widget.theme.colorScheme.primary,
                      widget.theme.colorScheme.primaryContainer,
                    ],
            ),
            boxShadow: [
              BoxShadow(
                  color: widget.isPast
                      ? Colors.grey.withOpacity(0.5)
                      : widget.theme.colorScheme.primary.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 2)
            ],
          ),
          child: Stack(
            children: [
              // Partiküller
              ..._particles.map((final particle) {
                final angle = particle.angle + _controller.value * 2 * pi;
                final distance = 12 + particle.distance * _controller.value * 8;
                final x = distance * cos(angle);
                final y = distance * sin(angle);

                return Positioned(
                    left: 20 + x,
                    top: 20 + y,
                    child: Container(
                      width: particle.size,
                      height: particle.size,
                      decoration: BoxDecoration(
                          color: widget.isPast
                              ? Colors.white.withOpacity(0.7)
                              : Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle),
                    ));
              }),

              // Merkez icon
              Center(
                  child: Icon(
                      widget.isPast
                          ? Icons.history_rounded
                          : Icons.celebration_rounded,
                      color: Colors.white,
                      size: 18))
            ],
          ),
        );
      },
    );
  }
}

class Particle {
  final double angle = Random().nextDouble() * 2 * pi;
  final double distance = Random().nextDouble();
  final double size = 2 + Random().nextDouble() * 3;
}
