import 'package:flutter/material.dart';

import '../util/responsive_utils.dart';
import 'optimized_cached_image.dart';

class InspirationalQuoteView extends StatelessWidget {
  final String word;
  final String author;
  final String imageUrl;

  const InspirationalQuoteView({
    super.key,
    required this.word,
    required this.author,
    this.imageUrl =
        'https://avatars.mds.yandex.net/get-entity_search/10349888/1168254232/SUx150_2x',
  });

  @override
  Widget build(final BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 250,
        width: double.infinity,
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            OptimizedCachedImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              width: context.screenWidth > 1400 ? 1400 : context.screenWidth,
            ),

            // 2. Siyah Kaplama (Yazının okunabilirliği için)
            Container(
                decoration: BoxDecoration(
                    // Görselin üzerine hafif siyah bir karartma
                    color: Colors.black.withOpacity(0.45))),

            // 3. Yazı İçeriği
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // İçeriğe göre boyut al
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('"$word"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            // Başka bir zarif serifli font
                            fontSize: 22,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            // Koyu arka plan için beyaz yazı
                            shadows: [
                              // Yazıya hafif bir derinlik
                              Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 5,
                                  offset: Offset(0, 2))
                            ])),
                    const SizedBox(height: 16),
                    Text(
                      "- $author -",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w300,
                          color: Colors.white.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
