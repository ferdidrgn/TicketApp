import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

class GradientStrip extends StatelessWidget {
  final bool isAlignmentCenterLeft;

  const GradientStrip({super.key, required this.isAlignmentCenterLeft});

  @override
  Widget build(final BuildContext context) => Positioned.fill(
        child: Align(
          alignment: isAlignmentCenterLeft
              ? Alignment.centerLeft
              : Alignment.centerRight,
          child: Container(
            width: 10,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  // Temanın gölge tonu (sabit siyah yerine).
                  Theme.of(context).colorScheme.shadow.withOpacity(0.3),
                ],
                begin: isAlignmentCenterLeft
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                end: isAlignmentCenterLeft
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
              ),
            ),
          ),
        ),
      );
}
