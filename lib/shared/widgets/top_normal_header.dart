import 'package:flutter/material.dart';
import '../../core/common/extentions/app_context_ui_extension.dart';
import 'button/back_button_glassmorphism.dart';

class TopNormalHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData rightIcon;
  final bool showBackButton;

  const TopNormalHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.rightIcon = Icons.theater_comedy_rounded,
    this.showBackButton = true,
  });

  @override
  Widget build(final BuildContext context) {
    final themeColors = context.colors;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (showBackButton)
                  const GlassmorphismBackButton()
                else
                  const SizedBox(height: 44), // Hizayı bozmamak için
                Icon(
                  rightIcon,
                  color: themeColors.primary.withOpacity(0.5),
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: context.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: themeColors.onSurface,
                letterSpacing: -1,
              ),
            ),
            Text(
              subtitle,
              style: context.textTheme.bodyLarge?.copyWith(
                color: themeColors.onSurfaceVariant.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
