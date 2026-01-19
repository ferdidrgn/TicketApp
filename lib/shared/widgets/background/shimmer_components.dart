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
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header simülasyonu (Opsiyonel)
          const SizedBox(height: 40),

          // Hero Banner Shimmer
          Padding(
            padding: context.sectionPadding,
            child: ShimmerLoading(
                width: double.infinity,
                height: context.hp(45),
                borderRadius: 30),
          ),

          // Kategori Listesi Shimmer
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(
                  left: context.responsive(mobile: 24, desktop: 60)),
              itemCount: 6,
              itemBuilder: (final _, final __) => const Padding(
                padding: EdgeInsets.only(right: 12),
                child: ShimmerLoading(height: 40, width: 120, borderRadius: 12),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Ürün Gridi Shimmer
          Padding(
              padding: context.sectionPadding,
              child: const ShimmerCard(itemCount: 8)),
        ],
      ),
    );
  }
}

// --- 4. VINTAGE STIL SHIMMER (Antika temalı) ---
class VintagePageShimmer extends StatelessWidget {
  const VintagePageShimmer({super.key});

  @override
  Widget build(final BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vintage Hero Banner Shimmer
          Container(
            height: 280,
            color: const Color(0xFF5D4037),
            child: Stack(
              children: [
                Shimmer.fromColors(
                  baseColor: const Color(0xFF6B4F3A),
                  highlightColor: const Color(0xFF8B7355),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF5D4037),
                          const Color(0xFF8B7355).withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 24,
                  bottom: 20,
                  child: Container(
                    width: context.responsive(mobile: 250, desktop: 350),
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFD4B483)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar Shimmer
          Container(
            padding:
                EdgeInsets.all(context.responsive(mobile: 20, desktop: 24)),
            color: Colors.white,
            child: Column(
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade200,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Kategori Chips Shimmer
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 6,
                    separatorBuilder: (final _, final __) =>
                        const SizedBox(width: 12),
                    itemBuilder: (final context, final index) =>
                        Shimmer.fromColors(
                      baseColor: Colors.grey.shade200,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Ürün Grid Shimmer (Vintage Stil)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: 8,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:
                    context.responsive(mobile: 2, tablet: 3, desktop: 4),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemBuilder: (final context, final index) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey.shade200,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Shimmer.fromColors(
                            baseColor: Colors.grey.shade200,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              height: 12,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Shimmer.fromColors(
                            baseColor: Colors.grey.shade200,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Shimmer.fromColors(
                                baseColor: Colors.grey.shade200,
                                highlightColor: Colors.grey.shade100,
                                child: Container(
                                  height: 20,
                                  width: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              Shimmer.fromColors(
                                baseColor: Colors.grey.shade200,
                                highlightColor: Colors.grey.shade100,
                                child: Container(
                                  height: 20,
                                  width: 20,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Adsense Banner Shimmer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade200,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
