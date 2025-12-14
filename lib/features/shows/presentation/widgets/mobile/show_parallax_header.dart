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
    // Temanın arka plan rengini al (Light: Beyaz, Dark: Koyu)
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

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
          height: MediaQuery.of(context).size.height * 0.6 +
              (offset < 0 ? -offset : 0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                // Arka plan yüklenirken temanın rengini göster
                errorWidget: (context, url, error) =>
                    Container(color: backgroundColor),
              ),
              // Gradient: Resimden -> Sayfa Rengine yumuşak geçiş
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black12, // Üst kısım hafif
                      Colors.black54, // Orta kısım koyulaşıyor
                      backgroundColor, // Alt kısım tamamen sayfa rengi
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
              // Scroll yaptıkça artan bulanıklık (Blur)
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
