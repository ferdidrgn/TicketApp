import 'package:flutter/material.dart';

class CustomElevatedButton extends StatelessWidget {
  final String text;
  final IconData? iconData;
  final Widget? iconAsset;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final Color? arrowColor;
  final bool showArrow;

  const CustomElevatedButton({
    super.key,
    required this.text,
    this.iconData,
    this.iconAsset,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.arrowColor,
    this.showArrow = true,
  });

  @override
  Widget build(final BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 5,
      color: backgroundColor ?? theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.all(18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (iconData != null)
                Icon(iconData,
                    color: iconColor ??
                        theme.bottomNavigationBarTheme.selectedItemColor,
                    size: 24)
              else if (iconAsset != null)
                iconAsset!
              else
                const SizedBox(width: 0),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    text,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor ?? theme.textTheme.bodyLarge?.color),
                  ),
                ),
              ),
              if (showArrow)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 20,
                  color: arrowColor ?? theme.iconTheme.color?.withOpacity(0.6),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
