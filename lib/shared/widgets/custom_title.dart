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
    this.fontWeight = FontWeight.bold,
    this.backgroundColor = Colors.transparent,
    this.textColor,
  });

  @override
  Widget build(final BuildContext context) {
    final effectiveColor = textColor ?? context.textColor;

    final textStyle = Theme.of(context).textTheme.headlineMedium!.copyWith(
        fontSize: fontSize, color: effectiveColor, fontWeight: fontWeight);

    return Container(
      margin: EdgeInsets.only(top: 15),
      child: Row(children: [
        Container(width: 4, height: 24, color: context.primaryColor),
        const SizedBox(width: 10),
        Container(
            color: backgroundColor,
            alignment: alignment ?? Alignment.centerLeft,
            child: Text(title, style: textStyle))
      ]),
    );
  }
}
