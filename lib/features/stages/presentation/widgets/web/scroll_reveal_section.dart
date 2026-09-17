import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Masaüstü/web sayfalarında bir bölümü, kullanıcı sayfayı aşağı kaydırıp
/// bölüm görünür hale geldiğinde yumuşak bir fade + slide-up animasyonuyla
/// ortaya çıkarır (editoryal siteler için tipik "scroll reveal" efekti).
///
/// Animasyon her bölüm için yalnızca bir kez, ilk görünür olduğunda
/// tetiklenir; kullanıcı yukarı geri kaydırsa bile tekrar oynatılmaz.
class ScrollRevealSection extends StatefulWidget {
  /// [VisibilityDetector] için benzersiz olması gereken kimlik.
  final String id;
  final Widget child;

  /// Bölüm görünür olduktan sonra animasyonun başlamadan önce bekleyeceği
  /// süre (kademeli/staggered giriş efekti için kullanılır).
  final Duration delay;
  final Duration duration;

  /// [SlideTransition] için, çocuğun kendi boyutuna oranla başlangıç
  /// kayması (ör. 0.08 => çocuğun yüksekliğinin %8'i kadar aşağıdan gelir).
  final double slideFraction;

  /// Bölümün ne kadarı görünür olunca animasyonun tetikleneceği eşik.
  final double visibleThreshold;

  const ScrollRevealSection({
    super.key,
    required this.id,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 650),
    this.slideFraction = 0.08,
    this.visibleThreshold = 0.12,
  });

  @override
  State<ScrollRevealSection> createState() => _ScrollRevealSectionState();
}

class _ScrollRevealSectionState extends State<ScrollRevealSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.slideFraction),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  void _reveal() {
    if (_revealed) return;
    _revealed = true;
    if (widget.delay == Duration.zero) {
      if (mounted) _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) => VisibilityDetector(
        key: Key('scroll-reveal-${widget.id}'),
        onVisibilityChanged: (final info) {
          if (info.visibleFraction >= widget.visibleThreshold) _reveal();
        },
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(position: _slide, child: widget.child),
        ),
      );
}
