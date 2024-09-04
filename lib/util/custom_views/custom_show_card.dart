import 'package:flutter/material.dart';

class CustomVerticalGameCard extends StatelessWidget {
  final String imageUrl;
  final String gameName;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  const CustomVerticalGameCard({
    super.key,
    required this.imageUrl,
    required this.gameName,
    this.width = 150,
    this.height = 250,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) {
                    return child;
                  }
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                      child: Icon(Icons.error, color: Colors.red));
                },
              ),
            ),
            _buildGradientStrip(
              isAlignmentCenterLeft: true,
            ),
            _buildGradientStrip(
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

  Widget _buildGradientStrip({
    required bool isAlignmentCenterLeft,
  }) {
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
