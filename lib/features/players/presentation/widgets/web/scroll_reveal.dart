import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:ticketapp/core/theme/app_motion.dart';

/// 🎬 SCROLL-TRIGGERED REVEAL
///
/// Sayfa masaüstünde aşağı kaydırıldıkça bölümlerin "canlanarak" (fade + hafif
/// kayma) belirmesini sağlayan hafif sarmalayıcı. `visibility_detector` zaten
/// projede bağımlı olduğu için (bkz. `hero_video_section.dart`) burada da onu
/// kullanıyoruz: widget ekranın görünür alanına girdiği an animasyonu bir kez
/// tetikler, tekrar tetiklemez (kullanıcı yukarı-aşağı kaydırdıkça flash
/// yapmaz).
///
/// Her çağrıda benzersiz bir [VisibilityDetector] key'i gerekiyor; bunu widget
/// kendi içinde otomatik üretir (`UniqueKey`), çağıran tarafın bir key
/// yönetmesine gerek yok.
class ScrollReveal extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;
  final double visibleThreshold;

  const ScrollReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.slow,
    this.beginOffset = const Offset(0, 0.12),
    this.visibleThreshold = 0.1,
  });

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  final Key _visibilityKey = UniqueKey();
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: widget.beginOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: AppMotion.standard));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(final VisibilityInfo info) {
    if (_revealed || !mounted) return;
    if (info.visibleFraction < widget.visibleThreshold) return;
    _revealed = true;
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  Widget build(final BuildContext context) {
    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: _onVisibilityChanged,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _slide, child: widget.child),
      ),
    );
  }
}
