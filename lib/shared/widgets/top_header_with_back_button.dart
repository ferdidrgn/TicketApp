import 'package:flutter/material.dart';
import '../../core/common/extentions/app_context_ui_extension.dart';
import 'button/back_button_glassmorphism.dart';

class TopHeaderWithBackButton extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final IconData? rightIcon;
  final bool showBackButton;

  const TopHeaderWithBackButton({
    super.key,
    this.title,
    this.subtitle,
    this.rightIcon,
    this.showBackButton = true,
  });

  @override
  Widget build(final BuildContext context) {
    final bool hasTitle = title != null && title!.isNotEmpty;
    final bool hasSubtitle = subtitle != null && subtitle!.isNotEmpty;
    if (!hasTitle && !hasSubtitle && !showBackButton)
      return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 💡 Row'u CrossAxisAlignment.center yaparak tüm elemanları
          // dikeyde tek bir çizgiye (merkeze) oturtuyoruz.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Sol Kısım: Geri Butonu
              if (showBackButton)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: GlassmorphismBackButton(),
                ),

              // 2. Orta Kısım: Başlık
              if (hasTitle)
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (final Rect bounds) => LinearGradient(
                      colors: context.appGradient(isActive: true),
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      title!,
                      // 💡 Center hizalamada yazının alt/üst boşlukları (leading)
                      // dengeyi bozmaması için height: 1.0 kritik.
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Serif',
                        letterSpacing: -1.5,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),

              // 3. Sağ Kısım: İkon
              if (rightIcon != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Icon(
                    rightIcon,
                    color: context.colors.primary.withOpacity(0.5),
                    size: 28,
                  ),
                ),
            ],
          ),

          // Alt Başlık (Subtitle)
          if (hasSubtitle) ...[
            const SizedBox(height: 12),
            // Boşluğu biraz artırarak ferahlık sağladık
            Padding(
              padding: EdgeInsets.only(left: showBackButton ? 52 : 0),
              child: Text(
                subtitle!,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
