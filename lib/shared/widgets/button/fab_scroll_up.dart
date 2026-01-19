import 'dart:ui';
import 'package:flutter/material.dart';

class ScrollUpButton extends StatelessWidget {
  final ScrollController scrollController;
  final double showOffset;

  const ScrollUpButton({
    super.key,
    required this.scrollController,
    this.showOffset = 300,
  });

  @override
  Widget build(final BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (final _, final __) {
        final visible =
            scrollController.hasClients && scrollController.offset > showOffset;

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          right: 20,
          bottom: visible ? 20 : -90,
          child: _GlassFab(
            onTap: () {
              scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
              );
            },
          ),
        );
      },
    );
  }
}

class _GlassFab extends StatelessWidget {
  final VoidCallback onTap;

  const _GlassFab({required this.onTap});

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: Colors.black.withOpacity(0.35),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.keyboard_arrow_up_rounded,
              size: 30,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
