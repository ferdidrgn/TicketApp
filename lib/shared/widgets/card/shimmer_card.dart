import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/theme_context_extension.dart';

class ShimmerCard extends StatelessWidget {
  final double width;
  final double height;
  final bool showTextLine;

  const ShimmerCard({
    super.key,
    this.width = 220,
    this.height = 150,
    this.showTextLine = true,
  });

  @override
  Widget build(final BuildContext context) => Container(
        width: width,
        height: height,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ShimmerLoading(
                height: height - (showTextLine ? 40 : 0),
                width: width,
                borderRadius: 16,
              ),
            ),
            if (showTextLine)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(height: 10, width: 60, borderRadius: 4),
                    const SizedBox(height: 6),
                    ShimmerLoading(
                        height: 14, width: width - 40, borderRadius: 4),
                  ],
                ),
              ),
          ],
        ),
      );
}

class ShimmerLoading extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;
  final bool isCircular;

  const ShimmerLoading({
    super.key,
    this.height = 190.0,
    this.width = 130.0,
    this.borderRadius = 8.0,
    this.isCircular = false,
  });

  @override
  Widget build(final BuildContext context) => Shimmer.fromColors(
        baseColor: context.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor:
            context.isDarkMode ? Colors.grey[600]! : Colors.grey[100]!,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: isCircular
                ? BorderRadius.circular(height / 2)
                : BorderRadius.circular(borderRadius),
          ),
        ),
      );
}
