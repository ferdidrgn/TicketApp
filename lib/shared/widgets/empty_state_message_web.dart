import 'package:flutter/material.dart';

class EmptyStateMessage extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Color? iconColor;

  const EmptyStateMessage({
    super.key,
    required this.message,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(final BuildContext context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e).withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD4AF37).withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.info_outline,
              color: iconColor ?? Colors.white.withOpacity(0.3),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
}
