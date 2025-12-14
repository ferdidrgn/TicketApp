import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double height;
  final double width;

  const ShimmerLoading({
    super.key,
    this.height = 190.0, // Varsayılan yükseklik
    this.width = 130.0, // Varsayılan genişlik
  });

  @override
  Widget build(final BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context)
          .primaryColor
          .withOpacity(0.6), // Ana rengin biraz soluk hali
      highlightColor: Colors.grey[500]!, // Vurgu için gri tonu

      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white, // Veya Colors.grey[300]
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
