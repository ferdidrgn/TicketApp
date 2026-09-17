import 'dart:async';
import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Web'de aşağı kaydırıldıkça içeriği yavaşça "ortaya çıkaran" (fade + hafif
/// yukarı kayma) sarmalayıcı widget.
///
/// `visibility_detector` paketiyle içerik ekrana girdiğinde (varsayılan
/// %12 görünürlük eşiği) animasyonu bir kez tetikler; landing sayfasındaki
/// (`landing/app.js`) scroll-reveal hissini masaüstü Flutter tarafına taşır.
/// Sadece masaüstü sayfalarda kullanılmak üzere tasarlandı — mobil akışı
/// etkilemez çünkü mobil ekranlar bu widget'ı hiç import etmiyor.
class ScrollReveal extends StatefulWidget {
  final Widget child;

  /// İçeriğin görünür olmasından sonra animasyonun başlamasından önceki
  /// bekleme süresi. Aynı bölümdeki kartları art arda (staggered) ortaya
  /// çıkarmak için kullanılır.
  final Duration delay;
  final Duration duration;

  /// Animasyon başlarken içeriğin bulunduğu dikey ofset (px). Animasyon
  /// bittiğinde içerik kendi doğal konumuna (0) gelir.
  final double offsetY;

  /// Tetiklenmesi için gereken minimum görünürlük oranı (0-1).
  final double visibleThreshold;

  const ScrollReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 550),
    this.offsetY = 28,
    this.visibleThreshold = 0.12,
  });

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _offset;
  final Key _visibilityKey = UniqueKey();
  bool _triggered = false;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offset = Tween<double>(begin: widget.offsetY, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _handleVisibility(final VisibilityInfo info) {
    if (_triggered || !mounted) return;
    if (info.visibleFraction < widget.visibleThreshold) return;
    _triggered = true;

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  Widget build(final BuildContext context) => VisibilityDetector(
        key: _visibilityKey,
        onVisibilityChanged: _handleVisibility,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (final context, final child) => Opacity(
            opacity: _fade.value,
            child: Transform.translate(
              offset: Offset(0, _offset.value),
              child: child,
            ),
          ),
          child: widget.child,
        ),
      );
}
