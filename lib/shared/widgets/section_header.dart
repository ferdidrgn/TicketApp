import 'package:flutter/material.dart';
import '../../core/common/extentions/app_context_ui_extension.dart';
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
    this.fontSize = 10,
    this.alignment,
    this.fontWeight = FontWeight.bold,
    this.backgroundColor = Colors.transparent,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    final effectiveColor = textColor ?? context.primaryColor.withOpacity(0.8);

    final textStyle = context.textTheme.headlineMedium!.copyWith(
        color: effectiveColor, fontSize: fontSize, fontWeight: fontWeight);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5)
          .copyWith(top: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(width: 4, height: 24, color: context.colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null)
                  Text(subtitle!.toUpperCase(),
                      style: textStyle.copyWith(letterSpacing: 2.0)),
                Text(title,
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                        letterSpacing: -0.5)),
              ],
            ),
          ),
          if (onTap != null) NavigationButton(onTap: onTap),
        ],
      ),
    );
  }
}
