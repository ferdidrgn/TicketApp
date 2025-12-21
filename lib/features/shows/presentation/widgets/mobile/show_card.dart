import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ticketapp/shared/widgets/card/shimmer_card.dart';
import '../../../../../shared/widgets/custom_gradient_background_image.dart';

class ShowCard extends StatelessWidget {
  final String imageUrl;
  final String gameName;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  const ShowCard({
    super.key,
    required this.imageUrl,
    required this.gameName,
    this.width = 150,
    this.height = 250,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.only(right: 16, left: 5, bottom: 20),
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.8),
              blurRadius: 5,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            ClipRRect(
              borderRadius: borderRadius,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (final context, final url) => ShimmerLoading(),
                errorWidget: (final context, final url, final error) =>
                    const Icon(Icons.error),
              ),
            ),
            const GradientStrip(
              isAlignmentCenterLeft: true,
            ),
            const GradientStrip(
              isAlignmentCenterLeft: false,
            ),
            // Oyun adı overlay'i
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(16)),
                  color: Colors.black.withOpacity(0.5),
                ),
                child: Text(
                  gameName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
