import 'package:flutter/material.dart';
import '../../../core/common/extentions/app_context_ui_extension.dart';
import '../../../core/util/decorative_elements.dart';

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
              color: backgroundColor ??
                  (context.isDarkMode
                      ? const Color(0xFF0F0F0F)
                      : const Color(0xFFFAFAFA)),
            ),
          ),

          // 2. Işık Efekti (Parametreli)
          AmbientLightEffect(color: ambientColor),

          // 3. Parçacıklar (Parametreli)
          FloatingParticles(color: particleColor),

          // 4. İçerik
          child,
        ],
      );
}
