import 'package:flutter/material.dart';

class GradientStrip extends StatelessWidget {
  final bool isAlignmentCenterLeft;

  const GradientStrip({
    super.key,
    required this.isAlignmentCenterLeft,
  });

  @override
  Widget build(final BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: isAlignmentCenterLeft
            ? Alignment.centerLeft
            : Alignment.centerRight,
        child: Container(
          width: 10,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
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
}
