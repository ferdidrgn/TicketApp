import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/common/extentions/app_context_ui_extension.dart';

// --- 1. TEMEL PARLAMA EFEKTİ (Shimmer Box) ---
class ShimmerLoading extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;
  final bool isCircular;

  const ShimmerLoading({
    super.key,
    this.height = 190.0,
    this.width = 130.0,
    this.borderRadius = 8.0,
    this.isCircular = false,
  });

  @override
  Widget build(final BuildContext context) => Shimmer.fromColors(
        baseColor: context.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
        highlightColor:
            context.isDarkMode ? Colors.grey[600]! : Colors.grey[100]!,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: isCircular
                ? BorderRadius.circular(height / 2)
                : BorderRadius.circular(borderRadius),
          ),
        ),
      );
}

// --- 2. TEKİL ÜRÜN KARTI SHIMMER (Grid öğeleri için) ---
class ShimmerCard extends StatelessWidget {
  final double height;
  final int itemCount;
  final int? crossAxisCount;
  final bool showTextLine;

  const ShimmerCard({
    super.key,
    this.height = 300,
    this.itemCount = 5,
    this.crossAxisCount,
    this.showTextLine = true,
  });

  @override
  Widget build(final BuildContext context) {
    if (itemCount == 1 || itemCount == 2)
      return _buildShimmerItem(context);
    else {
      final int effectiveCrossAxisCount = crossAxisCount ??
          context.responsive<int>(mobile: 3, tablet: 6, desktop: 10);

      final double effectiveSpacing = effectiveCrossAxisCount > 6 ? 12.0 : 20.0;

      // 1. Ekran genişliğinden kenar paddinglerini çıkar (Örn: responsive_utils'den gelen değer)
      final double horizontalPadding =
          context.responsive<double>(mobile: 48, desktop: 120);
      final double availableWidth = context.screenWidth - horizontalPadding;

      // 2. Kartlar arasındaki toplam boşluğu çıkar (N-1 tane boşluk vardır)
      final double totalCrossSpacing =
          (effectiveCrossAxisCount - 1) * effectiveSpacing;

      // 3. Tek bir kartın NET GENİŞLİĞİ
      final double itemWidth =
          (availableWidth - totalCrossSpacing) / effectiveCrossAxisCount;

      return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: effectiveCrossAxisCount,
          mainAxisSpacing: 15,
          crossAxisSpacing: effectiveSpacing,
          childAspectRatio: itemWidth / height,
        ),
        itemBuilder: (final context, final index) => _buildShimmerItem(context),
      );
    }
  }

  Widget _buildShimmerItem(final BuildContext context) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Expanded(
              child: ShimmerLoading(
                height: double.infinity,
                width: double.infinity,
                borderRadius: 20,
              ),
            ),
            if (showTextLine)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoading(height: 12, width: 80, borderRadius: 4),
                    SizedBox(height: 8),
                    ShimmerLoading(
                        height: 16, width: double.infinity, borderRadius: 4),
                  ],
                ),
              ),
          ],
        ),
      );
}

// --- 3. KOMPLE SAYFA İSKELETİ (Skeleton Screen) ---
class FullPageShimmer extends StatelessWidget {
  const FullPageShimmer({super.key});

  @override
  Widget build(final BuildContext context) {
    // Shimmer.fromColors en üstte olursa, içindeki tüm alt elemanlar senkronize parlar.
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),

            // 1. Arama Çubuğu veya Başlık Alanı
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _shimmerBox(width: 200, height: 30, radius: 8),
            ),

            const SizedBox(height: 20),

            // 2. Hero Banner (Öne Çıkan Mobilya)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child:
                  _shimmerBox(width: double.infinity, height: 200, radius: 20),
            ),

            const SizedBox(height: 30),

            // 3. Kategoriler (Yatay Kaydırma Simülasyonu)
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 24),
                itemCount: 5,
                itemBuilder: (final _, final __) => Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: _shimmerBox(width: 80, height: 40, radius: 12),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 4. Ürün Gridi (Mobilya Kartları)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.8,
                ),
                itemBuilder: (final _, final __) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: _shimmerBox(
                            width: double.infinity,
                            height: double.infinity,
                            radius: 15)),
                    const SizedBox(height: 10),
                    _shimmerBox(width: 100, height: 15, radius: 5),
                    const SizedBox(height: 5),
                    _shimmerBox(width: 60, height: 15, radius: 5),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tekrarlayan kutuları oluşturmak için yardımcı metod
  Widget _shimmerBox(
      {required final double width,
      required final double height,
      required final double radius}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// --- 4. Artistic STIL SHIMMER ---
class ArtisticPageShimmer extends StatelessWidget {
  const ArtisticPageShimmer({super.key});

  @override
  Widget build(final BuildContext context) => Shimmer.fromColors(
        baseColor: context.isDarkMode ? Colors.grey[900]! : Colors.grey[300]!,
        highlightColor:
            context.isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Sanatsal Hero (Sahne/Afiş Alanı)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _artBox(
                    width: 180,
                    height: 35,
                    radius: 8), // "Öne Çıkanlar" başlığı simülasyonu
              ),
              const SizedBox(height: 20),

              // Büyük Sahne Kartı
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _artBox(width: double.infinity, height: 220, radius: 24),
              ),

              const SizedBox(height: 40),

              // Tiyatro Kategorileri (Yuvarlak Circle Shimmer'lar)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 24),
                  itemCount: 5,
                  itemBuilder: (final _, final __) => Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Column(
                      children: [
                        _artBox(width: 65, height: 65, radius: 32.5),
                        // Yuvarlak kategori
                        const SizedBox(height: 8),
                        _artBox(width: 50, height: 12, radius: 4),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Bilet Koçanı / Etkinlik Kartları simülasyonu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _artBox(width: double.infinity, height: 120, radius: 16),
              ),
              const SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _artBox(width: double.infinity, height: 120, radius: 16),
              ),
            ],
          ),
        ),
      );

  Widget _artBox(
          {required final double width,
          required final double height,
          required final double radius}) =>
      Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(radius)),
      );
}
