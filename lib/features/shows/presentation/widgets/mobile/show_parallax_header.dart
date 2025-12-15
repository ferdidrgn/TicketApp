import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ShowParallaxHeader extends StatelessWidget {
  final String imageUrl;
  final ScrollController scrollController;
  final Color backgroundColor;

  const ShowParallaxHeader({
    super.key,
    required this.imageUrl,
    required this.scrollController,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        double offset = 0;
        if (scrollController.hasClients) {
          offset = scrollController.offset;
        }
        return Positioned(
          top: -offset * 0.5,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.6 + (offset < 0 ? -offset : 0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                memCacheHeight: 800,
                errorWidget: (context, url, error) => Container(color: backgroundColor),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black12,
                      Colors.black54,
                      backgroundColor,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
              if (offset > 0)
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: (offset / 100).clamp(0, 5),
                    sigmaY: (offset / 100).clamp(0, 5),
                  ),
                  child: Container(color: Colors.transparent),
                ),
            ],
          ),
        );
      },
    );
  }
}