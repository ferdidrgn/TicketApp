import 'package:flutter/material.dart';

class MagicDiscoveryWrapper extends StatefulWidget {
  final Widget darkLayer; // Siyah-beyaz / Eskiz hali
  final Widget brightLayer; // Renkli / Canlı hali
  final bool isEffectActive;

  const MagicDiscoveryWrapper({
    super.key,
    required this.darkLayer,
    required this.brightLayer,
    required this.isEffectActive,
  });

  @override
  State<MagicDiscoveryWrapper> createState() => _MagicDiscoveryWrapperState();
}

class _MagicDiscoveryWrapperState extends State<MagicDiscoveryWrapper> {
  Offset _pointerPos = const Offset(-500, -500); // Başlangıçta ekran dışında

  @override
  Widget build(final BuildContext context) {
    if (!widget.isEffectActive) return widget.brightLayer;

    return GestureDetector(
      onPanUpdate: (final details) =>
          setState(() => _pointerPos = details.localPosition),
      onPanEnd: (final _) =>
          setState(() => _pointerPos = const Offset(-500, -500)),
      child: Stack(
        children: [
          // Arka Plan: Tozlu/Eski Görüntü
          widget.darkLayer,

          // Ön Plan: Sihirli Aydınlanma (Sadece parmak ucunda)
          ShaderMask(
            shaderCallback: (final rect) {
              return RadialGradient(
                center: FractionalOffset(
                  _pointerPos.dx / rect.width,
                  _pointerPos.dy / rect.height,
                ),
                radius: 0.25, // Fenerin genişliği
                colors: [Colors.white, Colors.transparent],
                stops: const [0.6, 1.0],
              ).createShader(rect);
            },
            blendMode: BlendMode.dstIn,
            child: widget.brightLayer,
          ),
        ],
      ),
    );
  }
}
