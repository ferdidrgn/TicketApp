import 'package:flutter/material.dart';
import '../../../core/common/extentions/app_context_ui_extension.dart';

/// Sayfaların ortak zemini: temanın yüzeyi, SADE.
///
/// Eskiden her sayfanın köşesinde bir "ortam ışığı" halkası ve ekrana
/// serpilmiş parlayan parçacıklar vardı — sahibi "her ekranda parlama/spot
/// süsü"nü reddetti (bkz. tiyatrol-design `history.md`). Bilet dilinde
/// zemin sakin, nesne (bilet) konuşur. `ambientColor`/`particleColor`
/// parametreleri mevcut çağıranlar bozulmasın diye duruyor ama artık bir şey
/// çizmiyor.
class CustomAppBackground extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? ambientColor;
  final Color? particleColor;

  const CustomAppBackground({
    super.key,
    required this.child,
    this.backgroundColor,
    this.ambientColor,
    this.particleColor,
  });

  @override
  Widget build(final BuildContext context) => Stack(
        children: [
          // 1. Zemin
          Positioned.fill(
            child: ColoredBox(
              color: backgroundColor ?? context.colors.surface,
            ),
          ),

          // 2. Yerleşim sabitleyici: eski parçacık katmanı (SizedBox.expand)
          // Stack'i tüm alana yayıyordu; içerik aynı (gevşek) kısıtlarla
          // aynı boyutta çizilmeye devam etsin diye korunuyor.
          const SizedBox.expand(),

          // 3. İçerik
          child,
        ],
      );
}
