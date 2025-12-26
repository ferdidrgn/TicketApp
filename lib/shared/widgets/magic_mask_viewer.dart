import 'package:flutter/material.dart';

class MagicMaskViewer extends StatefulWidget {
  final Widget foreground; // Üstte duran (silinen/maskelenen) katman
  final Widget background; // Altta duran (açığa çıkan) katman
  final double radius; // Maske genişliği (0.3 idealdir)
  final bool showCursor; // Parmak altında bir halka görünsün mü?

  const MagicMaskViewer({
    super.key,
    required this.foreground,
    required this.background,
    this.radius = 0.25,
    this.showCursor = false,
  });

  @override
  State<MagicMaskViewer> createState() => _MagicMaskViewerState();
}

class _MagicMaskViewerState extends State<MagicMaskViewer> {
  // ValueNotifier kullanarak sadece maskeyi güncelliyoruz, tüm sayfayı değil.
  final ValueNotifier<Offset?> _pointerPos = ValueNotifier(null);

  @override
  Widget build(final BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (final event) => _pointerPos.value = event.localPosition,
      onPointerMove: (final event) => _pointerPos.value = event.localPosition,
      onPointerUp: (final event) => _pointerPos.value = null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. KATMAN: Alttaki gizli gerçeklik
          widget.background,

          // 2. KATMAN: Üstteki katman ve maskeleme işlemi
          ValueListenableBuilder<Offset?>(
            valueListenable: _pointerPos,
            builder: (final context, final pos, final child) {
              // Eğer dokunma yoksa maske uygulama, direkt ön planı göster
              if (pos == null) return widget.foreground;

              return ShaderMask(
                // Bu mod, gradientin olduğu yeri "delip" alttakini gösterir
                blendMode: BlendMode.dstOut,
                shaderCallback: (final rect) {
                  return RadialGradient(
                    center: FractionalOffset(
                      pos.dx / rect.width,
                      pos.dy / rect.height,
                    ),
                    radius: widget.radius,
                    colors: const [Colors.black, Colors.transparent],
                    stops: const [0.7, 1.0], // Kenar yumuşaklığı
                  ).createShader(rect);
                },
                child: widget.foreground,
              );
            },
          ),

          // Opsiyonel: Parmak ucunda sanatsal bir halka
          if (widget.showCursor)
            ValueListenableBuilder<Offset?>(
              valueListenable: _pointerPos,
              builder: (final context, final pos, final _) {
                if (pos == null) return const SizedBox.shrink();
                return Positioned(
                  left: pos.dx - 40,
                  top: pos.dy - 40,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pointerPos.dispose();
    super.dispose();
  }
}

///EXAMPLE
/*
*
* A. Bilet Detayda "Gizli QR" Modu
QR kodun olduğu yere buzlu bir cam koy, parmakla temizlensin.

Dart

MagicMaskViewer(
  radius: 0.2,
  background: QrImageView(data: ticketId), // Net QR
  foreground: ClipRRect( // Buzlu Cam
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(color: Colors.white.withOpacity(0.1)),
    ),
  ),
)
B. Home Kartında "Atmosfer Değişimi"
Gündüz ve gece afişleri arasında geçiş.

Dart

MagicMaskViewer(
  background: Image.asset("gece_afisi.jpg"),
  foreground: Image.asset("gunduz_afisi.jpg"),
)
C. Profil Sayfasında "Sanatsal İmza"
Profil fotoğrafının üzerinden parmakla geçince fotoğrafın renklenmesi.

Dart

MagicMaskViewer(
  background: ProfilePhoto(isColor: true),
  foreground: ProfilePhoto(isGrayscale: true),
)*/