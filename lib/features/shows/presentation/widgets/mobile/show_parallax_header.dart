import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ticketapp/core/theme/app_colors.dart';
import 'package:ticketapp/shared/widgets/optimized_cached_image.dart';

class ShowParallaxHeader extends StatelessWidget {
  final String imageUrl;
  final ScrollController scrollController;

  const ShowParallaxHeader({
    super.key,
    required this.imageUrl,
    required this.scrollController,
  });

  @override
  Widget build(final BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (final context, final child) {
        double offset = 0;
        if (scrollController.hasClients) offset = scrollController.offset;

        return Positioned(
          top: -offset * 0.5,
          left: 0,
          right: 0,
          height: MediaQuery.of(context).size.height * 0.6 +
              (offset < 0 ? -offset : 0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              OptimizedCachedImage(imageUrl: imageUrl, fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black12,
                      Colors.black54,
                      Theme.of(context).brightness == Brightness.dark
                          ? AppDarkColors.primary
                          : AppLightColors.background
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
