import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'background/shimmer_components.dart';

class OptimizedCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final bool isCircular;
  final Widget Function(BuildContext, String, dynamic)? errorBuilder;

  const OptimizedCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 8.0,
    this.isCircular = false,
    this.errorBuilder,
  });

  /// ✅ Provider Üretici (Precache işlemleri için)
  static CachedNetworkImageProvider provider(
    final String imageUrl, {
    required final BuildContext context,
    final double? width,
    final double? height,
  }) => CachedNetworkImageProvider(
      imageUrl,
      maxWidth: _calculateCacheSize(context, width),
      maxHeight: _calculateCacheSize(context, height),
    );

  @override
  Widget build(final BuildContext context) {
    // Eğer yuvarlak ise yarıçapı hesapla, değilse normal radius kullan
    final double effectiveRadius =
        isCircular ? (height ?? width ?? 50) / 2 : borderRadius;

    return ClipRRect(
      borderRadius: BorderRadius.circular(effectiveRadius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        // Animasyon Ayarları
        fadeInDuration: const Duration(milliseconds: 300),
        fadeInCurve: Curves.easeOut,

        // Bellek Optimizasyonu (Çok Önemli!)
        // Resmi ekranda göründüğü boyutta cache'ler, devasa resimleri küçültür.
        memCacheHeight: _calculateCacheSize(context, height),
        memCacheWidth: _calculateCacheSize(context, width),

        // Yükleniyor (Shimmer)
        placeholder: (final context, final url) => ShimmerLoading(
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          borderRadius: effectiveRadius, // Shimmer da aynı şekli alsın
          isCircular: isCircular,
        ),

        // Hata Durumu (Eski kodunuzdaki tasarıma sadık kalındı)
        errorWidget: errorBuilder ??
            (final context, final url, final error) {
              final isDarkMode =
                  Theme.of(context).brightness == Brightness.dark;
              return Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.grey[800]!.withOpacity(0.5)
                      : Colors.grey[200]!.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(effectiveRadius),
                ),
                child: Center(
                  child: Icon(
                    Icons.broken_image_outlined, // Veya photo_outlined
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                    size: (width != null && width! < 50) ? 20 : 24,
                  ),
                ),
              );
            },
      ),
    );
  }

  /// Cache boyutunu hesaplayan yardımcı metot
  static int? _calculateCacheSize(
      final BuildContext context, final double? size) {
    if (size == null || size == double.infinity) return null;
    // Cihazın piksel yoğunluğunu al (Retina ekranlar için x2, x3 gibi)
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    // Biraz tolerans ekleyerek (cache kalitesi düşmesin diye) int'e çevir
    return (size * devicePixelRatio).round();
  }
}
