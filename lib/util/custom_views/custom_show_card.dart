import 'package:flutter/material.dart';

class GameCard extends StatelessWidget {
  final String imageUrl;
  final String gameName;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const GameCard({
    Key? key,
    required this.imageUrl,
    required this.gameName,
    this.width = 120,
    this.height = 200,
    this.borderRadius = const BorderRadius.only(
      topLeft: Radius.circular(30),
      bottomRight: Radius.circular(16),
    ),
  }) : super(key: key);

  List<Color> gradientColors(BuildContext context, bool isActive) {
    return isActive
        ? [
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
            Theme.of(context).colorScheme.secondary.withOpacity(0.8),
          ]
        : [
            Colors.grey.withOpacity(0.5),
            Colors.grey.withOpacity(0.3),
          ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.only(right: 16, bottom: 20),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
            ),
          ),
          // Gradient on the sides
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 10, // Width of the gradient strip
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors(context, true),
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 10, // Width of the gradient strip
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors(context, true),
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                  ),
                ),
              ),
            ),
          ),
          // Overlay for game name
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.black.withOpacity(0.5),
              child: Text(
                gameName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
