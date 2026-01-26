import 'dart:ui';
import 'package:flutter/material.dart';

class ScrollUpButton extends StatelessWidget {
  final ScrollController scrollController;
  final double showOffset;

  /// Mixin kullanılıyorsa bu notifier performans sağlar.
  /// Eğer boş bırakılırsa buton kendi offset kontrolünü yapar.
  final ValueNotifier<bool>? visibleNotifier;

  const ScrollUpButton({
    super.key,
    required this.scrollController,
    this.visibleNotifier,
    this.showOffset = 300,
  });

  @override
  Widget build(final BuildContext context) {
    // 1. Durum: Mixin'den gelen bir notifier varsa onu dinle (Yüksek Performans)
    if (visibleNotifier != null)
      return ValueListenableBuilder<bool>(
        valueListenable: visibleNotifier!,
        builder: (final context, final isVisible, final _) =>
            _buildPositioned(isVisible),
      );

    // 2. Durum: Standalone kullanım (Mixin yoksa controller'ı dinle)
    return AnimatedBuilder(
      animation: scrollController,
      builder: (final _, final __) {
        final visible =
            scrollController.hasClients && scrollController.offset > showOffset;
        return _buildPositioned(visible);
      },
    );
  }

  Widget _buildPositioned(final bool isVisible) => AnimatedPositioned(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        // Giriş çıkışlar daha canlı ve sanatsal
        right: 20,
        bottom: isVisible ? 20 : -100,
        child: _GlassFab(
          onTap: () => scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
          ),
        ),
      );
}

class _GlassFab extends StatelessWidget {
  final VoidCallback onTap;

  const _GlassFab({required this.onTap});

  @override
  Widget build(final BuildContext context) => GestureDetector(
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
                border: Border.all(color: Colors.white.withOpacity(0.25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
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
