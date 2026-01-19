import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';
import '../../../../../core/common/constants/app_constants.dart';
import '../../../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../../../core/util/responsive_utils.dart';
import '../../../domain/entities/show.dart';

class ShowDetailHero extends StatelessWidget {
  final Show showData;
  final ValueNotifier<double> scrollNotifier;
  final Animation<double> fadeAnimation;
  final Animation<Offset> slideAnimation;
  final AnimationController floatingAnimation;

  const ShowDetailHero({
    super.key,
    required this.showData,
    required this.scrollNotifier,
    required this.fadeAnimation,
    required this.slideAnimation,
    required this.floatingAnimation,
  });

  @override
  Widget build(final BuildContext context) {
    final height = context.responsive(mobile: 500.0, tablet: 600.0, desktop: 700.0);

    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              // Parallax efektli görsel
              ValueListenableBuilder<double>(
                valueListenable: scrollNotifier,
                builder: (final context, final scrollOffset, final child) {
                  return Positioned(
                    top: -(scrollOffset * 0.25),
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: height + 200,
                      child: OptimizedCachedImage(
                        imageUrl: showData.imageUrl,
                        fit: BoxFit.cover,
                        width: MediaQuery.of(context).size.width,
                      ),
                    ),
                  );
                },
              ),

              // Gradient overlay
              _HeroGradientOverlay(),

              // Başlık ve içerik
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    const _HeroDivider(),
                    _HeroTitle(title: showData.name),
                    const SizedBox(height: 20),
                    _AnimatedUnderline(animation: floatingAnimation),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroGradientOverlay extends StatelessWidget {
  const _HeroGradientOverlay();

  @override
  Widget build(final BuildContext context) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0a0a1a).withOpacity(0.3),
              Colors.transparent,
              Color(0xFF0a0a1a).withOpacity(0.9),
              Color(0xFF0a0a1a),
            ],
            stops: const [0.0, 0.3, 0.8, 1.0],
          ),
        ),
      ),
    );
  }
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider();

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: 60,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Color(0xFFD4AF37),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

class _HeroTitle extends StatelessWidget {
  final String title;

  const _HeroTitle({required this.title});

  @override
  Widget build(final BuildContext context) {
    return ShaderMask(
      shaderCallback: (final bounds) => LinearGradient(
        colors: [Colors.white, Color(0xFFF5E6A3)],
      ).createShader(bounds),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: context.responsive(mobile: 36.0, desktop: 64.0),
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 8,
          shadows: [
            BoxShadow(
              color: Color(0xFFD4AF37).withOpacity(0.5),
              blurRadius: 40,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _AnimatedUnderline extends StatelessWidget {
  final Animation<double> animation;

  const _AnimatedUnderline({required this.animation});

  @override
  Widget build(final BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (final _, final __) {
        return Container(
          height: 4,
          width: 120 + math.sin(animation.value * math.pi) * 20,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFD4AF37),
                Color(0xFFF5E6A3),
                Color(0xFFD4AF37),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFD4AF37).withOpacity(0.6),
                blurRadius: 15,
              ),
            ],
          ),
        );
      },
    );
  }
}
