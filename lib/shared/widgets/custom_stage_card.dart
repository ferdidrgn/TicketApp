import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'shimmer.dart';

class CustomStageCard extends StatelessWidget {
  final String text;
  final String imageUrl;
  final VoidCallback onPressed;

  const CustomStageCard({
    super.key,
    required this.text,
    required this.imageUrl,
    required this.onPressed,
  });

  @override
  Widget build(final BuildContext context) {
    return Container(
      width: 125,
      margin: const EdgeInsets.only(right: 5),
      child: InkWell(
        onTap: onPressed,
        borderRadius: const BorderRadius.all(Radius.circular(60)),
        child: Card(
          elevation: 3,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(60)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  placeholder: (final context, final url) => ShimmerLoading(),
                  errorWidget: (final context, final url, final error) => const Icon(Icons.error),
                ),
              ),
              SizedBox(height: text.length <= 18 ? 17 : 8),
              Flexible(
                child: Text(text,
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
