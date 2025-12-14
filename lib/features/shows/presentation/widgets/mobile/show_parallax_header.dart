import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ShowParallaxHeader extends StatelessWidget {
  final String imageUrl;
  final ScrollController scrollController;

  const ShowParallaxHeader({
    super.key,
    required this.imageUrl,
    required this.scrollController,
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
        // Resmin yukarı kayma ve büyüme efekti
        return Positioned(
          top: -offset * 0.5,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.6 +
              (offset < 0 ? -offset : 0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    Container(color: const Color(0xFF151525)),
              ),
              // Okunurluk için karartma
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black12, Colors.black54, Color(0xFF0a0a1a)],
                  ),
                ),
              ),
              // Scroll yaptıkça artan bulanıklık (Blur)
              if (offset > 0)
                BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: (offset / 100).clamp(0, 10),
                    sigmaY: (offset / 100).clamp(0, 10),
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
