import 'package:flutter/material.dart';

class CustomSectionTitle extends StatelessWidget {
  final String title;
  final double? fontSize;
  final Alignment? alignment;
  final FontWeight? fontWeight;
  final Color backgroundColor;
  final Color? textColor;

  // Constructor
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
    TextStyle textStyle;

    // TextStyle'ı ayarlıyoruz
    textStyle = Theme.of(context)
        .textTheme
        .headlineMedium!
        .copyWith(fontSize: fontSize, color: textColor, fontWeight: fontWeight);

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      alignment: alignment ?? Alignment.centerLeft,
      child: Text(title, style: textStyle),
    );
  }
}
