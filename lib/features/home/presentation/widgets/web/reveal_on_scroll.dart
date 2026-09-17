import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Basit, kendi kendine yeten "scroll'da beliren" (scroll-reveal) sarmalayıcı.
///
/// Bir bölüm ekrana yeterince girdiğinde hafif bir yukarı kayma + solma
/// animasyonuyla belirir. Sadece bir kez tetiklenir (tekrar yukarı/aşağı
/// kaydırıldığında yeniden oynamaz) — "restrained" / sakin bir web sitesi
/// hissi için tasarlandı, abartılı bir efekt değil.
///
/// Sadece Ana Sayfa (web) bölümleri için kullanılır, başka hiçbir feature'a
/// bağımlılığı yoktur.
class RevealOnScroll extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double offsetY;
  final double visibleThreshold;

  const RevealOnScroll({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 28,
    this.visibleThreshold = 0.12,
  });

  @override
  State<RevealOnScroll> createState() => _RevealOnScrollState();
}

class _RevealOnScrollState extends State<RevealOnScroll>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;
  bool _hasRevealed = false;

  // VisibilityDetector, paket genelinde benzersiz bir Key bekler.
  // State bir kez oluşturulduğunda üretiliyor, rebuild'lerde sabit kalıyor.
  final Key _visibilityKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(final VisibilityInfo info) {
    if (_hasRevealed || !mounted) return;
    if (info.visibleFraction > widget.visibleThreshold) {
      _hasRevealed = true;
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  Widget build(final BuildContext context) => VisibilityDetector(
        key: _visibilityKey,
        onVisibilityChanged: _onVisibilityChanged,
        child: AnimatedBuilder(
          animation: _progress,
          builder: (final context, final child) => Opacity(
            opacity: _progress.value,
            child: Transform.translate(
              offset: Offset(0, (1 - _progress.value) * widget.offsetY),
              child: child,
            ),
          ),
          child: widget.child,
        ),
      );
}
