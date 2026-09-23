import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/common/extentions/app_context_ui_extension.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';
import '../../features/shows/presentation/providers/gallery_provider.dart';
import 'optimized_cached_image.dart';

class GallerySection extends ConsumerStatefulWidget {
  final List<String> photos;

  const GallerySection({super.key, required this.photos});

  @override
  ConsumerState<GallerySection> createState() => _GallerySectionState();
}

class _GallerySectionState extends ConsumerState<GallerySection> {
  int _currentPage = 0;

  @override
  Widget build(final BuildContext context) {
    if (widget.photos.isEmpty)
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 48,
                color: Colors.white.withOpacity(0.2),
              ),
              const SizedBox(height: 16),
              Text(
                "Bu oyuna ait henüz fotoğraf eklenmemiş.",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      );

    if (widget.photos.isEmpty)
      return const Center(
          child: Text("Henüz fotoğraf eklenmemiş.",
              style: TextStyle(color: Colors.white30)));

    final isMobile = context.isMobile;
    final isTablet = context.isTablet;
    final photos = widget.photos;

    // MOBİL GÖRÜNÜM: Yatay akışkan liste veya 2'li Grid
    if (isMobile) if (photos.length <= 4)
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: photos.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 4 / 3,
        ),
        itemBuilder: (final _, final index) => _GalleryItem(
          url: photos[index],
          index: index,
          allPhotos: photos,
          isMobile: true,
        ),
      );
    else
      return SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: photos.length,
          itemBuilder: (final _, final index) => Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            child: _GalleryItem(
              url: photos[index],
              index: index,
              allPhotos: photos,
              isMobile: true,
            ),
          ),
        ),
      );

    // WEB/TABLET GÖRÜNÜM: Sayfalamalı Grid
    final totalPages = (photos.length / 8).ceil();
    final start = _currentPage * 8;
    final end = math.min(start + 8, photos.length);

    return Column(
      children: [
        LayoutBuilder(
          builder: (final context, final constraints) {
            final crossAxisCount = isTablet ? 3 : 4;
            final spacing = context.gridSpacing;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: end - start,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: 4 / 3,
              ),
              itemBuilder: (final _, final index) => _GalleryItem(
                url: photos[start + index],
                index: start + index,
                allPhotos: photos,
                isMobile: false,
              ),
            );
          },
        ),
        if (totalPages > 1)
          GalleryPaginationControls(
            currentPage: _currentPage,
            totalPages: totalPages,
            onPageChanged: (final page) => setState(() => _currentPage = page),
          ),
      ],
    );
  }
}

/// ------------------------------------------------------------
/// TEKİL GALERİ ÖĞESİ
/// ------------------------------------------------------------
/// Masaüstünde hover'da — `theatre_show_card.dart` ile AYNI teknik —
/// bağlanırken bir kez rastgele seçilmiş (bu tekil karo bağlı kaldığı
/// sürece sabit, her hover'da yeniden zar atılmayan) başka bir gerçek
/// galeri fotoğrafını `curtainTransition`'ın "perde açılışı" tarzıyla
/// (`ClipRect` + ortadan büyüyen `Align(widthFactor: ...)`) üzerine açar.
/// Galeride başka fotoğraf yoksa (tek kare) sadece kaldırma/kenarlık/
/// gölge hover geri bildirimi uygulanır, görsel değişmez. Dokunmatik
/// cihazlarda hover hiç tetiklenmediği için mobil kullanım etkilenmez.
class _GalleryItem extends ConsumerStatefulWidget {
  final String url;
  final int index;
  final List<String> allPhotos;
  final bool isMobile;

  const _GalleryItem({
    required this.url,
    required this.index,
    required this.allPhotos,
    required this.isMobile,
  });

  @override
  ConsumerState<_GalleryItem> createState() => _GalleryItemState();
}

class _GalleryItemState extends ConsumerState<_GalleryItem> {
  bool _hovered = false;

  /// Bu karo bağlı kaldığı sürece sabit kalan "sürpriz" ikinci fotoğraf.
  String? _revealUrl;

  @override
  void initState() {
    super.initState();
    final others =
        widget.allPhotos.where((final p) => p != widget.url).toList();
    if (others.isNotEmpty) {
      _revealUrl = others[math.Random().nextInt(others.length)];
    }
  }

  @override
  Widget build(final BuildContext context) {
    final hasReveal = _revealUrl != null;

    return Hero(
      tag: 'gallery_image_${widget.index}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (final _) => setState(() => _hovered = true),
        onExit: (final _) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            ref
                .read(galleryProvider(widget.allPhotos.length).notifier)
                .setCurrentIndex(widget.index);

            showDialog(
              context: context,
              barrierColor: Colors.black.withOpacity(0.9),
              builder: (final _) => GalleryViewerDialog(
                images: widget.allPhotos,
                isMobile: widget.isMobile,
              ),
            );
          },
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: _hovered
                    ? WebColors.primaryGold.withOpacity(0.5)
                    : Colors.transparent,
                width: 1.2,
              ),
              boxShadow: _hovered
                  ? AppShadows.level3(WebColors.primaryGold)
                  : AppShadows.level1(Colors.black),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  OptimizedCachedImage(
                    imageUrl: widget.url,
                    fit: BoxFit.cover,
                  ),
                  if (hasReveal)
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: 0,
                        end: _hovered ? 1.0 : 0.0,
                      ),
                      duration: AppMotion.normal,
                      curve: AppMotion.dramatic,
                      builder: (final context, final t, final child) {
                        if (t <= 0) return const SizedBox.shrink();
                        return ClipRect(
                          child: Align(
                            alignment: Alignment.center,
                            widthFactor: t,
                            child: child,
                          ),
                        );
                      },
                      child: SizedBox.expand(
                        child: OptimizedCachedImage(
                          imageUrl: _revealUrl!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// TAM EKRAN GALERİ GÖRÜNTÜLEYİCİ (DIALOG)
/// ------------------------------------------------------------
class GalleryViewerDialog extends ConsumerStatefulWidget {
  final List<String> images;
  final bool isMobile;

  const GalleryViewerDialog({
    super.key,
    required this.images,
    required this.isMobile,
  });

  @override
  ConsumerState<GalleryViewerDialog> createState() =>
      _GalleryViewerDialogState();
}

class _GalleryViewerDialogState extends ConsumerState<GalleryViewerDialog> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final currentIndex =
        ref.read(galleryProvider(widget.images.length)).currentIndex;
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(final int index) {
    HapticFeedback.selectionClick();
    ref
        .read(galleryProvider(widget.images.length).notifier)
        .setCurrentIndex(index);
  }

  @override
  Widget build(final BuildContext context) {
    final currentIndex =
        ref.watch(galleryProvider(widget.images.length)).currentIndex;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              children: [
                // Üst Araç Çubuğu
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                            '${currentIndex + 1} / ${widget.images.length}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14)),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),
                // Ana Görsel Alanı
                Expanded(
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        itemCount: widget.images.length,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (final context, final index) {
                          return Hero(
                            tag: 'gallery_image_$index',
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: InteractiveViewer(
                                minScale: 0.5,
                                maxScale: 3.0,
                                child: OptimizedCachedImage(
                                  imageUrl: widget.images[index],
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      // Masaüstü Navigasyon Okları
                      if (!widget.isMobile) ...[
                        if (currentIndex > 0)
                          Positioned(
                            left: 20,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: _NavBtn(
                                icon: Icons.arrow_back_ios_rounded,
                                onTap: () => _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                ),
                              ),
                            ),
                          ),
                        if (currentIndex < widget.images.length - 1)
                          Positioned(
                            right: 20,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: _NavBtn(
                                icon: Icons.arrow_forward_ios_rounded,
                                onTap: () => _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                // Alt Önizleme (Thumbnails)
                ThumbnailCarousel(
                  images: widget.images,
                  isMobile: widget.isMobile,
                  onThumbnailTap: (final index) {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// ÖNİZLEME (THUMBNAIL) ŞERİDİ
/// ------------------------------------------------------------
class ThumbnailCarousel extends ConsumerStatefulWidget {
  final List<String> images;
  final bool isMobile;
  final Function(int)? onThumbnailTap;

  const ThumbnailCarousel({
    super.key,
    required this.images,
    required this.isMobile,
    this.onThumbnailTap,
  });

  @override
  ConsumerState<ThumbnailCarousel> createState() => _ThumbnailCarouselState();
}

class _ThumbnailCarouselState extends ConsumerState<ThumbnailCarousel> {
  final ScrollController _controller = ScrollController();

  void _scroll(final bool forward) {
    _controller.animateTo(
      _controller.offset + (forward ? 200 : -200),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(final BuildContext context) {
    final currentIndex =
        ref.watch(galleryProvider(widget.images.length)).currentIndex;

    return SizedBox(
      height: 100,
      child: Row(
        children: [
          if (!widget.isMobile)
            IconButton(
              tooltip: 'Önceki',
              icon: const Icon(Icons.arrow_back_ios,
                  color: Colors.white, size: 20),
              onPressed: () => _scroll(false),
            ),
          Expanded(
            child: ListView.builder(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: widget.images.length,
              itemBuilder: (final _, final index) {
                final isActive = index == currentIndex;

                return GestureDetector(
                  onTap: () {
                    ref
                        .read(galleryProvider(widget.images.length).notifier)
                        .setCurrentIndex(index);
                    widget.onThumbnailTap?.call(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    width: isActive ? 90 : 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? WebColors.primaryGold
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: OptimizedCachedImage(
                        imageUrl: widget.images[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (!widget.isMobile)
            IconButton(
              tooltip: 'Sonraki',
              icon: const Icon(Icons.arrow_forward_ios,
                  color: Colors.white, size: 20),
              onPressed: () => _scroll(true),
            ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// YARDIMCI BİLEŞENLER (NAV & PAGINATION)
/// ------------------------------------------------------------
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(final BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );
}

class GalleryPaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageChanged;

  const GalleryPaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  @override
  Widget build(final BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: WebColors.darkBlueSurface.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PageButton(
              icon: Icons.arrow_back_ios_rounded,
              enabled: currentPage > 0,
              onTap: () => onPageChanged(currentPage - 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${currentPage + 1} / $totalPages',
                style: const TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.w600),
              ),
            ),
            _PageButton(
              icon: Icons.arrow_forward_ios_rounded,
              enabled: currentPage < totalPages - 1,
              onTap: () => onPageChanged(currentPage + 1),
            ),
          ],
        ),
      );
}

class _PageButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageButton(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(final BuildContext context) => MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: enabled
                  ? WebColors.primaryGold
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: enabled ? WebColors.darkBlueBackground : Colors.white24,
              size: 14,
            ),
          ),
        ),
      );
}
