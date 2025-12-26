import 'package:flutter/material.dart';

enum MagicMode {
  discovery, // Fener Modu: Parmağın altını aydınlatır.
  reveal, // Pus Silme: Parmağın altındaki katmanı siler.
  shine // Işıltı: Otomatik bir parlama efekti ekler.
}

class MagicBox extends StatefulWidget {
  final Widget foreground; // Üstteki gizleyen katman
  final Widget background; // Alttaki gerçek katman
  final MagicMode mode; // Çalışma modu
  final double radius; // Etki alanı büyüklüğü
  final VoidCallback? onTap; // Dokunma eylemi

  const MagicBox({
    super.key,
    required this.foreground,
    required this.background,
    this.mode = MagicMode.reveal,
    this.radius = 0.3,
    this.onTap,
  });

  @override
  State<MagicBox> createState() => _MagicBoxState();
}

class _MagicBoxState extends State<MagicBox> {
  final ValueNotifier<Offset?> _pointerPos = ValueNotifier(null);
  Offset _startPos = Offset.zero;

  @override
  Widget build(final BuildContext context) {
    // 3. Mod: SHINE (Işıltı) Modu ise farklı bir yapı kullanıyoruz
    if (widget.mode == MagicMode.shine) return _buildShineEffect();

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
      onPointerCancel: (final _) => _pointerPos.value = null,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.background,
          ValueListenableBuilder<Offset?>(
            valueListenable: _pointerPos,
            builder: (final context, final pos, final child) {
              if (pos == null) return widget.foreground;

              return ShaderMask(
                blendMode: widget.mode == MagicMode.reveal
                    ? BlendMode.dstOut
                    : BlendMode.dstIn,
                shaderCallback: (final rect) {
                  return RadialGradient(
                    center: FractionalOffset(
                        pos.dx / rect.width, pos.dy / rect.height),
                    radius: widget.radius,
                    colors: const [Colors.black, Colors.transparent],
                    stops: const [0.7, 1.0],
                  ).createShader(rect);
                },
                child: widget.mode == MagicMode.reveal
                    ? widget.foreground
                    : widget.background,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShineEffect() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: -2.0, end: 2.0),
      duration: const Duration(seconds: 3),
      builder: (final context, final value, final child) {
        return ShaderMask(
          shaderCallback: (final rect) => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [value - 0.2, value, value + 0.2],
            colors: [
              Colors.white.withOpacity(0),
              Colors.white.withOpacity(0.4),
              Colors.white.withOpacity(0)
            ],
          ).createShader(rect),
          child: widget.background,
        );
      },
    );
  }
}

/*1. Ana Sayfa: "Geleceği Gör" Banner
Mod: MagicMode.discovery

Kullanım: foreground kısmına bulanık (blur) bir görsel, background kısmına ise net ve renkli konser görselini koy. Kullanıcı banner'ın üzerinde parmağını gezdirdiğinde sanki fenerle karanlıkta bir hazine buluyormuş gibi hissedecek.

2. Arama Sayfası: "Odaklanma" Kartları
Mod: MagicMode.reveal

Kullanım: Arama sonuçlarını listeleyen kartların üzerine foreground olarak hafif bir pus (grey + blur) ekle. Kullanıcı karta dokunduğunda o pus silinsin ve biletin tüm canlı detayları (isim, mekan) ortaya çıksın.

3. Ayarlar Sayfası: "Gizli Güvenlik"
Mod: MagicMode.reveal

Kullanım: Kullanıcının telefon numarasını veya mailini gösteren Text widget'ını foreground olarak buzlu bir cam (BackdropFilter) arkasına sakla. Sadece basılı tuttuğunda bilgiyi görebilsin.

4. Favoriler: "Premium Işıltı"
Mod: MagicMode.shine

Kullanım: Favori etkinlik kartlarını sadece bu moda al. Kartın üzerinden periyodik olarak şık bir metalik parlama geçsin. Hiç dokunmasa bile kartın "özel" olduğunu anlasın.

5. Geçmiş Biletler: "Tozlu Raflar"
Mod: MagicMode.discovery

Kullanım: Eski biletleri foreground katmanında siyah-beyaz ve sepya tonlarında göster. Dokunduğunda o anın renklerini "aydınlatarak" hatırlasın.*/
