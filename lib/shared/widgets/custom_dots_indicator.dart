import 'package:flutter/material.dart';
import '../../core/common/extentions/app_context_ui_extension.dart';

class DotsIndicator extends StatelessWidget {
  final int itemCount;
  final int currentIndex;
  final ValueChanged<int> onPageSelected;

  const DotsIndicator({
    super.key,
    required this.itemCount,
    required this.currentIndex,
    required this.onPageSelected,
  });

  @override
  Widget build(final BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(itemCount, (final index) {
          final isSelected = index == currentIndex;
          return GestureDetector(
            onTap: () => onPageSelected(index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: isSelected ? 10 : 8,
              height: isSelected ? 10 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? context.colors.primary
                    : Colors.grey,
              ),
            ),
          );
        }),
      );
}
