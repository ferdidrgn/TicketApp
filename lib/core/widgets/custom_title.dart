import 'package:flutter/material.dart';

class CustomSectionTitle extends StatelessWidget {
  final String title;
  final double fontSize;
  final Color backgroundColor;
  final Color? textColor;

  // Constructor
  const CustomSectionTitle({
    super.key,
    required this.title,
    this.fontSize = 24,
    this.backgroundColor = Colors.transparent,
    this.textColor,
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
