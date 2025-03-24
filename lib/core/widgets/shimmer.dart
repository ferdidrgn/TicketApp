import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({super.key});

  @override
  Widget build(final BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).primaryColor,
      highlightColor: Colors.black,
      child: Container(
        width: 130,
        height: 190,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
