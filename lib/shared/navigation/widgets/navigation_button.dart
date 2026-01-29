import 'package:flutter/material.dart';
import '../../../core/common/extentions/app_context_ui_extension.dart';

class NavigationButton extends StatelessWidget {
  final VoidCallback? onTap;

  const NavigationButton({super.key, this.onTap});

  @override
  Widget build(final BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
            ),
            color: context.primaryColor.withOpacity(0.1),
          ),
          child: Icon(
            Icons.arrow_forward,
            size: 16,
            color: context.colors.primary,
          ),
        ),
      );
}
