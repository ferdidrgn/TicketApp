import 'package:flutter/material.dart';

class DotsIndicator extends StatelessWidget {
  final PageController controller;
  final int itemCount;
  final ValueChanged<int> onPageSelected;

  const DotsIndicator({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.onPageSelected,
  });

  @override
  Widget build(final BuildContext context) {
    return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(itemCount, (final index) {
          return _buildDot(index);
        }));
  }

  Widget _buildDot(final int index) {
    return GestureDetector(
      onTap: () => onPageSelected(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        width: 8.0,
        height: 8.0,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                controller.page?.round() == index ? Colors.red : Colors.grey),
      ),
    );
  }
}
