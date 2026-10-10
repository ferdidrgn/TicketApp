import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';

/// Smart_home'daki BounceFromBottom / ScaleFade şablonunun TiyatRol uyarlaması.
/// Renk yok — sadece giriş koreografisi. Azaltılmış harekette anında gösterir.
class StageEntrance extends StatefulWidget {
  final Widget child;
  final double delay;
  final Offset begin;
  final double beginScale;

  const StageEntrance({
    super.key,
    required this.child,
    this.delay = 0,
    this.begin = const Offset(0, 0.12),
    this.beginScale = 0.94,
  });

  /// Alttan bounce (Smart_home homescreen kartları).
  const StageEntrance.bounce({
    super.key,
    required this.child,
    this.delay = 0,
  })  : begin = const Offset(0, 0.18),
        beginScale = 0.96;

  /// Scale + fade (Smart_home grid kartları).
  const StageEntrance.scaleFade({
    super.key,
    required this.child,
    this.delay = 0,
  })  : begin = Offset.zero,
        beginScale = 0.86;

  @override
  State<StageEntrance> createState() => _StageEntranceState();
}

class _StageEntranceState extends State<StageEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: widget.begin,
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
  late final Animation<double> _scale = Tween<double>(
    begin: widget.beginScale,
    end: 1,
  ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));

  @override
  void initState() {
    super.initState();
    final int ms = (widget.delay * 80).round().clamp(0, 1200);
    Future<void>.delayed(Duration(milliseconds: ms), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }
}
