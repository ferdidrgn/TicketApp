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

  /// ✅ Provider Üretici (SİLİNMEYEN, GELİŞMİŞ VERSİYON)
  /// Bu metodu resimleri önceden yüklemek (precacheImage) için kullanabilirsin.
  static CachedNetworkImageProvider provider(
    final String imageUrl, {
    required final BuildContext context,
    final double? width,
    final double? height,
  }) {
    return CachedNetworkImageProvider(
      imageUrl,
      maxWidth: _calculateCacheSize(context, width),
      maxHeight: _calculateCacheSize(context, height),
      // Hata durumunda konsola basar
      errorListener: (final e) => debugPrint("❌ Provider Hatası: $imageUrl"),
    );
  }

  @override
  Widget build(final BuildContext context) {
    // URL Güvenlik Kontrolü
    if (imageUrl.isEmpty || !imageUrl.startsWith('http'))
      return _buildErrorWidget(context);

    final double effectiveRadius =
        isCircular ? (height ?? width ?? 50) / 2 : borderRadius;

    // 📉 Bitmap Alt Örnekleme (subsampling): width/height açıkça
    // verilmediğinde (ör. Stack(fit: StackFit.expand) içindeki mozaik
    // kartları), ebeveynin gerçek constraint'lerini bellek boyutu
    // hesaplamasına yedek olarak kullanıyoruz — aksi halde görsel,
    // ekranda kapladığı küçük alandan bağımsız olarak tam çözünürlükte
    // belleğe decode edilir (Play Console "bitmap subsampling" uyarısı
    // tam olarak bunu işaret ediyor). Gerçekten sınırsız alanlarda
    // (ör. tam ekran zoom görüntüleyici) constraint sonsuz kalır ve
    // bilinçli olarak subsampling uygulanmaz.
    return LayoutBuilder(
      builder: (final context, final constraints) {
        final double? cacheWidth =
            width ?? (constraints.maxWidth.isFinite ? constraints.maxWidth : null);
        final double? cacheHeight = height ??
            (constraints.maxHeight.isFinite ? constraints.maxHeight : null);

        return ClipRRect(
          borderRadius: BorderRadius.circular(effectiveRadius),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            width: width,
            height: height,
            fit: fit,
            fadeInCurve: Curves.easeOut,
            fadeInDuration: const Duration(milliseconds: 300),
            fadeOutDuration: const Duration(milliseconds: 300),

            // Bellek Optimizasyonu
            memCacheHeight: _calculateCacheSize(context, cacheHeight),
            memCacheWidth: _calculateCacheSize(context, cacheWidth),

            // Yükleniyor (Shimmer)
            placeholder: (final context, final url) => ShimmerLoading(
              width: width ?? double.infinity,
              height: height ?? double.infinity,
              borderRadius: effectiveRadius,
              isCircular: isCircular,
            ),

            // Hata Durumu
            errorWidget: errorBuilder ??
                (final context, final url, final error) =>
                    _buildErrorWidget(context),
          ),
        );
      },
    );
  }

  /// 🛡️ Hata durumunda görünecek yer tutucu.
  /// Önceden düz Material `Colors.grey[...]` kullanıyordu — uygulamanın
  /// gerçek marka paletiyle (lacivert/bordo/altın) hiçbir ilgisi olmayan,
  /// "tasarlanmamış" gri bir kutu. Artık aktif temanın kendi renk şemasından
  /// (`ColorScheme.onSurface`/`outline`) türetiliyor — hangi ekranda,
  /// hangi temada görünürse görünsün sayfanın geri kalanıyla aynı
  /// ailede, marka rengine hafifçe eğilen bir nötr olarak okunuyor.
  Widget _buildErrorWidget(final BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final double effectiveRadius =
        isCircular ? (height ?? width ?? 50) / 2 : borderRadius;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
          color: colors.onSurface.withOpacity(0.08),
          borderRadius: BorderRadius.circular(effectiveRadius)),
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: colors.outline,
          size: (width != null && width! < 50) ? 18 : 24,
        ),
      ),
    );
  }

  /// Cache boyutunu hesaplayan yardımcı metot (Cihazın ekran kalitesine göre)
  static int? _calculateCacheSize(
      final BuildContext context, final double? size) {
    if (size == null || size == double.infinity || size <= 0) return null;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    return (size * devicePixelRatio).round();
  }
}
