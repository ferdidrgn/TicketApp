import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';

class AnimatedTitle extends StatelessWidget {
  final Animation<double> glowAnimation;
  final String text;

  const AnimatedTitle({
    super.key,
    required this.glowAnimation,
    required this.text,
  });

  @override
  Widget build(final BuildContext context) {
    return AnimatedBuilder(
      animation: glowAnimation,
      builder: (final context, final child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: WebColors.primaryGold.withOpacity(glowAnimation.value),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: WebColors.primaryGold,
              shadows: [
                Shadow(
                  blurRadius: 20,
                  color: WebColors.primaryGold.withOpacity(0.8),
                ),
                const Shadow(
                  blurRadius: 4,
                  color: Colors.black,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
