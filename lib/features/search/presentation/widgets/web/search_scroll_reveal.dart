import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Bir öğeyi ekranda ilk kez görünür olduğunda (scroll ile) yumuşak bir
/// "fade + yukarı kayma" animasyonuyla ortaya çıkarır.
///
/// `landing/app.js` içindeki `initReveal()` (IntersectionObserver tabanlı
/// `.reveal` sınıfı) davranışının Flutter tarafındaki karşılığıdır: sadece
/// bir kez tetiklenir, tekrar scroll edilse bile yeniden oynatılmaz.
///
/// Sadece masaüstü arama sonuçları için kullanılır; mobil tarafta hiçbir
/// yerde referans alınmaz.
class SearchRevealOnScroll extends StatefulWidget {
  final Widget child;

  /// Aynı listede art arda dizilen öğeler için kademeli (staggered) bir
  /// gecikme oluşturur (örn. bir grid'deki kartlar sırayla belirir).
  final int index;

  /// [index] başına eklenecek gecikme.
  final Duration staggerStep;

  /// Bu görünürlük oranından itibaren animasyon tetiklenir.
  final double visibleThreshold;

  const SearchRevealOnScroll({
    super.key,
    required this.child,
    this.index = 0,
    this.staggerStep = const Duration(milliseconds: 45),
    this.visibleThreshold = 0.08,
  });

  @override
  State<SearchRevealOnScroll> createState() => _SearchRevealOnScrollState();
}

class _SearchRevealOnScrollState extends State<SearchRevealOnScroll>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _slideY;
  final Key _visibilityKey = UniqueKey();
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideY = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(final VisibilityInfo info) {
    if (_triggered || !mounted) return;
    if (info.visibleFraction <= widget.visibleThreshold) return;

    _triggered = true;
    final delay = widget.staggerStep * (widget.index % 12);
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  Widget build(final BuildContext context) => VisibilityDetector(
        key: _visibilityKey,
        onVisibilityChanged: _onVisibilityChanged,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (final context, final child) => Opacity(
            opacity: _fade.value,
            child: Transform.translate(
              offset: Offset(0, _slideY.value),
              child: child,
            ),
          ),
          child: widget.child,
        ),
      );
}
