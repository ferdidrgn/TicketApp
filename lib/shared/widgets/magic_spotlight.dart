import 'dart:ui';
import 'package:flutter/material.dart';

class MagicDiscoveryWrapper extends StatefulWidget {
  final Widget darkLayer;
  final Widget brightLayer;
  final bool isEffectActive;
  final ScrollController scrollController; // Kaydırmayı takip etmek için şart

  const MagicDiscoveryWrapper({
    super.key,
    required this.darkLayer,
    required this.brightLayer,
    required this.isEffectActive,
    required this.scrollController,
  });

  @override
  State<MagicDiscoveryWrapper> createState() => _MagicDiscoveryWrapperState();
}

class _MagicDiscoveryWrapperState extends State<MagicDiscoveryWrapper> {
  final ValueNotifier<Offset> _spotlightPos =
      ValueNotifier(const Offset(-1000, -1000));

  @override
  Widget build(BuildContext context) {
    if (!widget.isEffectActive) return widget.brightLayer;

    return Stack(
      children: [
        // 1. KATMAN: Arka plandaki karanlık içerik
        widget.darkLayer,

        // 2. KATMAN: Hareketli Fener
        ValueListenableBuilder<Offset>(
          valueListenable: _spotlightPos,
          builder: (context, position, _) {
            return ShaderMask(
              shaderCallback: (rect) {
                // Scroll miktarını koordinatlara ekliyoruz ki fener içerikle beraber kaysın
                final scrollOffset = widget.scrollController.hasClients
                    ? widget.scrollController.offset
                    : 0.0;

                return RadialGradient(
                  center: FractionalOffset(
                    position.dx / rect.width,
                    (position.dy + scrollOffset) / (rect.height + scrollOffset),
                  ),
                  radius: 0.3,
                  colors: const [Colors.white, Colors.transparent],
                  stops: const [0.5, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: widget.brightLayer,
            );
          },
        ),

        // 3. KATMAN: Dokunma Yakalayıcı (Transparan)
        // Bu katman en üstte durur, dokunmayı alır ama aşağıya (scroll'a) iletir
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (details) {
              _spotlightPos.value = details.localPosition;
            },
            onPanEnd: (_) => _spotlightPos.value = const Offset(-1000, -1000),
          ),
        ),
      ],
    );
  }
}
