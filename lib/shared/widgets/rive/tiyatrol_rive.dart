import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

/// Ortak Rive yükleyici — asset yolu + isteğe bağlı artboard/state machine.
/// Temaya dokunmaz; sadece animasyonu gösterir.
class TiyatrolRive extends StatefulWidget {
  final String asset;
  final BoxFit fit;
  final String? artboard;
  final String? stateMachine;
  final double? height;
  final double? width;
  final bool hitTest;
  final VoidCallback? onTap;
  final Widget? placeholder;
  final ValueChanged<RiveWidgetController>? onReady;

  const TiyatrolRive({
    super.key,
    required this.asset,
    this.fit = BoxFit.contain,
    this.artboard,
    this.stateMachine,
    this.height,
    this.width,
    this.hitTest = true,
    this.onTap,
    this.placeholder,
    this.onReady,
  });

  @override
  State<TiyatrolRive> createState() => _TiyatrolRiveState();
}

class _TiyatrolRiveState extends State<TiyatrolRive> {
  late final FileLoader _loader = FileLoader.fromAsset(
    widget.asset,
    riveFactory: Factory.rive,
  );

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    Widget body = RiveWidgetBuilder(
      fileLoader: _loader,
      artboardSelector: widget.artboard == null
          ? const ArtboardDefault()
          : ArtboardNamed(widget.artboard!),
      stateMachineSelector: widget.stateMachine == null
          ? const StateMachineDefault()
          : StateMachineNamed(widget.stateMachine!),
      onLoaded: (final RiveLoaded state) {
        widget.onReady?.call(state.controller);
      },
      builder: (final context, final state) => switch (state) {
        RiveLoading() =>
          widget.placeholder ??
              Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: cs.primary,
                  ),
                ),
              ),
        RiveFailed() => Center(
            child: Icon(Icons.animation_outlined,
                color: cs.onSurfaceVariant, size: 36),
          ),
        RiveLoaded(:final controller) => RiveWidget(
            controller: controller,
            fit: _mapFit(widget.fit),
            hitTestBehavior: widget.hitTest
                ? RiveHitTestBehavior.opaque
                : RiveHitTestBehavior.none,
          ),
      },
    );

    if (widget.onTap != null) {
      body = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: body,
      );
    }

    return SizedBox(
      height: widget.height,
      width: widget.width,
      child: body,
    );
  }

  Fit _mapFit(final BoxFit fit) {
    switch (fit) {
      case BoxFit.cover:
        return Fit.cover;
      case BoxFit.fill:
        return Fit.fill;
      case BoxFit.fitWidth:
        return Fit.fitWidth;
      case BoxFit.fitHeight:
        return Fit.fitHeight;
      case BoxFit.none:
        return Fit.none;
      case BoxFit.scaleDown:
        return Fit.scaleDown;
      case BoxFit.contain:
        return Fit.contain;
    }
  }
}

/// Liquid UI Rive — Smart_home tarzı yuvarlak/aksyon buton kabuğu.
/// Renkler dışarıdan [ColorScheme] ile gelir; Rive sadece hareket sağlar.
class LiquidRiveButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  const LiquidRiveButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.size = 72,
  });

  static const String asset = 'assets/20920-39319-liquid-ui-demo.riv';

  @override
  Widget build(final BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipOval(
                  child: ColoredBox(
                    color: cs.primaryContainer.withValues(alpha: 0.55),
                    child: TiyatrolRive(
                      asset: asset,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      hitTest: false,
                    ),
                  ),
                ),
                Icon(icon, color: cs.onPrimaryContainer, size: size * 0.34),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
