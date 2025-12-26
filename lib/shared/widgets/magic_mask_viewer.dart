import 'package:flutter/material.dart';

class MagicMaskViewer extends StatefulWidget {
  final Widget foreground;
  final Widget background;
  final double radius;
  final VoidCallback? onTap;

  const MagicMaskViewer({
    super.key,
    required this.foreground,
    required this.background,
    this.radius = 0.35,
    this.onTap,
  });

  @override
  State<MagicMaskViewer> createState() => _MagicMaskViewerState();
}

class _MagicMaskViewerState extends State<MagicMaskViewer> {
  final ValueNotifier<Offset?> _pointerPos = ValueNotifier(null);
  Offset _startPos = Offset.zero;

  @override
  Widget build(final BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (final e) {
        _startPos = e.localPosition;
        _pointerPos.value = e.localPosition;
      },
      onPointerMove: (final e) => _pointerPos.value = e.localPosition,
      onPointerUp: (final e) {
        final distance = (e.localPosition - _startPos).distance;
        if (distance < 10) widget.onTap?.call();
        _pointerPos.value = null;
      },
      onPointerCancel: (final e) => _pointerPos.value = null,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.background,
          ValueListenableBuilder<Offset?>(
            valueListenable: _pointerPos,
            builder: (final context, final pos, final child) {
              if (pos == null) return widget.foreground;
              return ShaderMask(
                blendMode: BlendMode.dstOut,
                shaderCallback: (final rect) {
                  return RadialGradient(
                    center: FractionalOffset(
                      pos.dx / rect.width,
                      pos.dy / rect.height,
                    ),
                    radius: widget.radius,
                    colors: const [Colors.black, Colors.transparent],
                    stops: const [
                      0.1,
                      0.9
                    ], // Daha keskin bir delik açar, böylece QR tertemiz görünür
                  ).createShader(rect);
                },
                child: widget.foreground,
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
* Uygulama Örnekleri (Examples)
Bu widget'ı projenin farklı yerlerine şu şekilde entegre ederek "premium" bir his yaratabilirsin:

1. Bilet Detayda "Gizli QR" (Güvenlik Efekti)
QR kodu direkt göstermek yerine buzlu bir camın arkasına saklayın. Kullanıcı dokunduğunda QR netleşsin.

Dart

ArtisticMaskViewer(
  radius: 0.2,
  background: QrImageView(data: "ticket_123", size: 200), // Net QR
  foreground: ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Buzlu Cam
      child: Container(
        width: 200,
        height: 200,
        color: Colors.white.withOpacity(0.1),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white54, size: 50),
      ),
    ),
  ),
)
2. Etkinlik Kartlarında "Atmosfer Geçişi"
Etkinliğin gündüz afişinden gece atmosferine pürüzsüz bir geçiş yapın.

Dart

ArtisticMaskViewer(
  radius: 0.4,
  background: Image.network("https://example.com/konser_gece.jpg", fit: BoxFit.cover),
  foreground: Image.network("https://example.com/konser_gunduz.jpg", fit: BoxFit.cover),
)
3. Bilet Listesinde "Fiyat/Koltuk Röntzeni"
Bilet kartının üzerinde gezerken biletin fiyatı veya koltuk numarası gibi teknik detayları şık bir şekilde açığa çıkarın.

Dart

ArtisticMaskViewer(
  background: Container(
    color: Colors.amber,
    child: const Center(child: Text("VIP - KOLTUK A1", style: TextStyle(fontWeight: FontWeight.bold))),
  ),
  foreground: Container(
    color: Colors.grey[900],
    child: const Center(child: Text("Bilet Detaylarını Gör", style: TextStyle(color: Colors.white))),
  ),
)
4. Profil Sayfasında "Sanatçı Ruhu"
Siyah-beyaz bir portrenin dokunulan yerlerinin renklenmesini sağlayarak sanatsal bir derinlik katın.

Dart

ArtisticMaskViewer(
  radius: 0.25,
  background: Image.asset("assets/profile_color.png"), // Renkli fotoğraf
  foreground: ColorFiltered( // Siyah Beyaz Filtre
    colorFilter: const ColorFilter.matrix([
      0.21, 0.72, 0.07, 0, 0,
      0.21, 0.72, 0.07, 0, 0,
      0.21, 0.72, 0.07, 0, 0,
      0, 0, 0, 1, 0,
    ]),
    child: Image.asset("assets/profile_color.png"),
  ),
)*/
