import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/theme_context_extension.dart';

class CustomSectionTitle extends StatelessWidget {
  final String title;
  final double? fontSize;
  final Alignment? alignment;
  final FontWeight? fontWeight;
  final Color backgroundColor;
  final Color? textColor;

  const CustomSectionTitle({
    super.key,
    required this.title,
    this.fontSize,
    this.alignment,
    this.fontWeight,
    this.backgroundColor = Colors.transparent,
    this.textColor,
  });

  @override
  Widget build(final BuildContext context) {
    final isDarkMode = context.isDarkMode;

    final effectiveColor =
        textColor ?? (isDarkMode ? Colors.white : Colors.black);

    final textStyle = Theme.of(context).textTheme.headlineMedium!.copyWith(
        fontSize: fontSize, color: effectiveColor, fontWeight: fontWeight);

    return Row(children: [
      Container(width: 4, height: 24, color: context.primaryColor),
      const SizedBox(width: 10),
      Container(
        color: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
        alignment: alignment ?? Alignment.centerLeft,
        child: Text(title, style: textStyle),
      )
    ]);
  }
}
