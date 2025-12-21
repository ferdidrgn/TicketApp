import 'package:flutter/material.dart';
import '../../../../core/theme/theme_context_extension.dart';
import '../../../features/home/presentation/widgets/mobile/decorative_elements.dart';

class ImmersiveBackground extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Color? ambientColor;
  final Color? particleColor;

  const ImmersiveBackground({
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
