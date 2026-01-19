import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../../../core/common/extentions/app_context_ui_extension.dart';

// Ambient light effect in the background
class AmbientLightEffect extends StatelessWidget {
  final Color? color;

  const AmbientLightEffect({super.key, this.color});

  @override
  Widget build(final BuildContext context) => Positioned(
        top: -100,
        right: -100,
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Eğer renk gelirse onu kullan, gelmezse temadaki rengi kullan
            color: (color ?? context.primaryColor).withOpacity(0.15),
          ),
        ),
      );
}

// Floating particles for ambient effect
class FloatingParticles extends StatelessWidget {
  final Color? color;

  const FloatingParticles({super.key, this.color});

  @override
  Widget build(final BuildContext context) {
    // Burada işlem olduğu için süslü parantez kalmak zorunda
    final random = math.Random(1);
    final screenSize = MediaQuery.of(context).size;

    return SizedBox.expand(
      child: Stack(
        children: List.generate(15, (final index) {
          return Positioned(
            left: random.nextDouble() * screenSize.width,
            top: random.nextDouble() * screenSize.height,
            child: Container(
              width: random.nextDouble() * 3 + 1,
              height: random.nextDouble() * 3 + 1,
              decoration: BoxDecoration(
                // Dışarıdan gelen rengi kullan
                color: (color ?? context.primaryColor)
                    .withOpacity(random.nextDouble() * 0.3 + 0.1),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// Hero section with artistic text
class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.rotate(
              angle: -0.03,
              child: Text(
                "SANAT",
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: context.primaryColor.withOpacity(0.7),
                  letterSpacing: -2,
                  shadows: [
                    Shadow(
                      color: context.isDarkMode
                          ? Colors.white.withOpacity(0.1)
                          : Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(30, -15),
              child: Text(
                "DUVARI",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color:
                      context.isDarkMode ? Colors.grey[400] : Colors.grey[700],
                  fontStyle: FontStyle.italic,
                  letterSpacing: 3,
                ),
              ),
            ),
          ],
        ),
      );
}

// Divider with accent
class DividerWithAccent extends StatelessWidget {
  const DividerWithAccent({super.key});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          children: [
            Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    context.primaryColor.withOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(20, -1),
              child: Container(
                height: 1,
                width: 100,
                color: context.isDarkMode ? Colors.grey[600] : Colors.grey[300],
              ),
            ),
          ],
        ),
      );
}

// Bottom quote
class BottomQuote extends StatelessWidget {
  const BottomQuote({super.key});

  @override
  Widget build(final BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    context.primaryColor.withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "\"Sanat, hayatın kendisidir\"",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: context.isDarkMode
                    ? Colors.white.withOpacity(0.6)
                    : Colors.black.withOpacity(0.5),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.primaryColor.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Her gün yeni bir keşif",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.primaryColor.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}
