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
    // 💡 Sadece içerik varsa çizim yap
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showBackButton)
                const GlassmorphismBackButton()
              else
                const SizedBox(height: 44),
              if (rightIcon != null)
                Icon(rightIcon,
                    color: context.colors.primary.withOpacity(0.5), size: 28),
            ],
          ),
          if (hasTitle) ...[
            const SizedBox(height: 16),
            ShaderMask(
              shaderCallback: (final Rect bounds) => LinearGradient(
                colors: context.appGradient(isActive: true),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Serif',
                  letterSpacing: -1.5,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          if (hasSubtitle) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant.withOpacity(0.7),
                    fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}
