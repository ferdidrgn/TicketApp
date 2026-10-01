import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// İki bölmeli kalıcı ayrımın YAPIŞKAN tarafı: sayfa (tek bir
/// `CustomScrollView`) kayarken [child] satırın içinde aşağı kaydırılarak
/// görünür alanın üstünde (ya da panel ekrandan uzunsa altında) sabit
/// kalır; satırın sonuna gelince onunla birlikte yukarı çıkar. Böylece
/// footer tam genişlikte kalır, iki ayrı kaydırma alanı gerekmez.
///
/// [rowKey]: paneli içeren `Row`'un anahtarı (yüksekliği ölçülür).
/// [contentTop]: o satırın kaydırılan içerikteki üst konumu (sabit üst
/// boşluk). [gap]: yapışınca görünür alanın kenarına bırakılan boşluk.
class StickyAside extends StatefulWidget {
  final ScrollController controller;
  final GlobalKey rowKey;
  final double contentTop;
  final double gap;
  final Widget child;

  const StickyAside({
    super.key,
    required this.controller,
    required this.rowKey,
    required this.contentTop,
    required this.child,
    this.gap = 24,
  });

  @override
  State<StickyAside> createState() => _StickyAsideState();
}

class _StickyAsideState extends State<StickyAside> {
  final GlobalKey _paneKey = GlobalKey();
  double _dy = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant final StickyAside oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    // Yerleşim sırasında gelen bir bildirimde setState çağrılmaz; kareden
    // sonra hesaplanır.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((final _) => _update());
    } else {
      _update();
    }
  }

  void _update() {
    if (!mounted || !widget.controller.hasClients) return;
    final RenderObject? row = widget.rowKey.currentContext?.findRenderObject();
    final RenderObject? pane = _paneKey.currentContext?.findRenderObject();
    if (row is! RenderBox || pane is! RenderBox) return;
    if (!row.hasSize || !pane.hasSize) return;

    final double offset = widget.controller.offset;
    final double viewport = widget.controller.position.viewportDimension;
    final double paneHeight = pane.size.height;
    final double maxDy = math.max(0.0, row.size.height - paneHeight);

    final bool fits = paneHeight + widget.gap * 2 <= viewport;
    final double wanted = fits
        ? offset + widget.gap - widget.contentTop
        : offset + viewport - widget.gap - paneHeight - widget.contentTop;
    final double dy = wanted.clamp(0.0, maxDy);
    if ((dy - _dy).abs() > 0.5) setState(() => _dy = dy);
  }

  @override
  Widget build(final BuildContext context) {
    // İçerik (ör. görseller, benzer oyunlar) yüklenip satır yüksekliği
    // değişince konum yeniden hesaplansın.
    SchedulerBinding.instance.addPostFrameCallback((final _) => _update());
    return Transform.translate(
      offset: Offset(0, _dy),
      child: KeyedSubtree(key: _paneKey, child: widget.child),
    );
  }
}
