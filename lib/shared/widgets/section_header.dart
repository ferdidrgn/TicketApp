import 'package:flutter/material.dart';
import '../../core/theme/theme_context_extension.dart';
import '../navigation/widgets/navigation_button.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final double? fontSize;
  final Alignment? alignment;
  final FontWeight? fontWeight;
  final Color backgroundColor;
  final Color? textColor;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.fontSize,
    this.alignment,
    this.fontWeight = FontWeight.bold,
    this.backgroundColor = Colors.transparent,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final effectiveColor = textColor ?? context.textColor;

    final textStyle = Theme.of(context).textTheme.headlineMedium!.copyWith(
        fontSize: fontSize, color: effectiveColor, fontWeight: fontWeight);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(width: 4, height: 24, color: context.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          NavigationButton(onTap: onTap),
        ],
      ),
    );
  }
}
