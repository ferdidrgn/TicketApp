import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ticketapp/shared/widgets/shimmer.dart';

class OptimizedCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget Function(BuildContext, String, dynamic)? errorBuilder;

  const OptimizedCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.errorBuilder,
  });

  /// ✅ YENİ EKLENEN KISIM: Provider Üretici
  /// Bu metot, precacheImage yaparken widget ile AYNI optimizasyon ayarlarını
  /// kullanan bir provider döndürür.
  static CachedNetworkImageProvider provider(
    final String imageUrl, {
    required final BuildContext context,
    final double? width,
    final double? height,
  }) {
    return CachedNetworkImageProvider(
      imageUrl,
      // Widget'taki memCacheWidth/Height mantığının aynısı:
      maxWidth: _calculateCacheSize(context, width),
      maxHeight: _calculateCacheSize(context, height),
    );
  }

  @override
  Widget build(final BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 300),
      fadeInCurve: Curves.easeOut,
      placeholder: (final context, final url) => ShimmerLoading(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
      ),
      errorWidget: errorBuilder ??
          (final context, final url, final error) => Container(
              color: const Color(0xFF1a1a2e),
              child: const Icon(Icons.error_outline, color: Color(0xFFD4AF37))),
      // Aşağıdaki private metotları static yaptık ki hem buradan hem provider'dan erişilsin
      memCacheHeight: _calculateCacheSize(context, height),
      memCacheWidth: _calculateCacheSize(context, width),
    );
  }

  /// Helper metodu static yaptık (Kod tekrarını önlemek için)
  static int? _calculateCacheSize(
      final BuildContext context, final double? size) {
    if (size == null) return null;
    // Cihazın piksel yoğunluğunu al (Örn: Retina ekranlarda 2.0 veya 3.0)
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    // Boyutu piksel yoğunluğu ile çarpıp int'e çevir
    return (size * devicePixelRatio).round();
  }
}
