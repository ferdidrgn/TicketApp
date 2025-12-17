import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/constants/app_constants.dart';
import '../../core/util/responsive_utils.dart';
import '../../features/shows/presentation/providers/galerry_provider.dart';
import '../navigation/empty_state_message_web.dart';
import 'optimized_cached_image.dart';

/// ------------------------------------------------------------
/// GALLERY SECTION
/// ------------------------------------------------------------
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
    if (widget.photos.isEmpty) {
      return const EmptyStateMessage(
        message: 'Galeri boş.',
        icon: Icons.photo_library,
      );
    }

    final isMobile = context.isMobile;
    final isTablet = context.isTablet;
    final photos = widget.photos;

    /// MOBILE → horizontal list
    if (isMobile) {
      // Eğer çok fazla resim varsa horizontal, azsa grid göster
      if (photos.length <= 4) {
        // Grid göster
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
          itemBuilder: (final _, final index) {
            return _GalleryItem(
              url: photos[index],
              index: index,
              allPhotos: photos,
              isMobile: true,
            );
          },
        );
      } else {
        // Horizontal list göster
        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: photos.length,
            itemBuilder: (final _, final index) {
              return Container(
                width: 160, // Sabit genişlik
                margin: const EdgeInsets.only(right: 12),
                child: _GalleryItem(
                  url: photos[index],
                  index: index,
                  allPhotos: photos,
                  isMobile: true,
                ),
              );
            },
          ),
        );
      }
    }

    /// DESKTOP / TABLET
    final totalPages =
        (photos.length / AppConstants.galleryItemsPerPage).ceil();

    final start = _currentPage * AppConstants.galleryItemsPerPage;
    final end = math.min(
      start + AppConstants.galleryItemsPerPage,
      photos.length,
    );

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
              itemBuilder: (final _, final index) {
                return _GalleryItem(
                  url: photos[start + index],
                  index: start + index,
                  allPhotos: photos,
                  isMobile: false,
                );
              },
            );
          },
        ),
        if (totalPages > 1)
          GalleryPaginationControls(
            currentPage: _currentPage,
            totalPages: totalPages,
            onPageChanged: (final page) {
              setState(() => _currentPage = page);
            },
          ),
      ],
    );
  }
}

/// ------------------------------------------------------------
/// GALLERY ITEM
/// ------------------------------------------------------------
class _GalleryItem extends ConsumerWidget {
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
  Widget build(final BuildContext context, final WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        ref.read(galleryProvider.notifier).setCurrentIndex(index);

        showDialog(
          context: context,
          barrierColor: Colors.black.withOpacity(0.95),
          builder: (final _) => GalleryViewerDialog(
            images: allPhotos,
            isMobile: isMobile,
          ),
        ).then((final _) {
          ref.read(galleryProvider.notifier).reset();
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: OptimizedCachedImage(
          imageUrl: url,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// ------------------------------------------------------------
/// FULLSCREEN VIEWER
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
    final currentIndex = ref.read(galleryProvider).currentIndex;
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(final int index) {
    ref.read(galleryProvider.notifier).setCurrentIndex(index);
  }

  @override
  Widget build(final BuildContext context) {
    final currentIndex = ref.watch(galleryProvider).currentIndex;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Column(
            children: [
              /// HEADER WITH CLOSE BUTTON
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${currentIndex + 1} / ${widget.images.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
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
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              /// IMAGE WITH PAGEVIEW
              Expanded(
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: widget.images.length,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (final context, final index) {
                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: OptimizedCachedImage(
                              imageUrl: widget.images[index],
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),

                    /// ◀ PREVIOUS BUTTON
                    if (currentIndex > 0)
                      Positioned(
                        left: 20,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _NavBtn(
                            icon: Icons.arrow_back_ios_rounded,
                            onTap: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                      ),

                    /// ▶ NEXT BUTTON
                    if (currentIndex < widget.images.length - 1)
                      Positioned(
                        right: 20,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _NavBtn(
                            icon: Icons.arrow_forward_ios_rounded,
                            onTap: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              /// THUMBNAILS
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
    );
  }
}

/// ------------------------------------------------------------
/// THUMBNAIL CAROUSEL (WEB + MOBILE)
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _scroll(final bool forward) {
    _controller.animateTo(
      _controller.offset + (forward ? 200 : -200),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(final BuildContext context) {
    final currentIndex = ref.watch(galleryProvider).currentIndex;

    return SizedBox(
      height: 110,
      child: Row(
        children: [
          if (!widget.isMobile)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              color: Colors.white,
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
                    ref.read(galleryProvider.notifier).setCurrentIndex(index);
                    widget.onThumbnailTap?.call(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFFD4AF37)
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
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
              icon: const Icon(Icons.arrow_forward_ios),
              color: Colors.white,
              onPressed: () => _scroll(true),
            ),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// NAV BUTTON
/// ------------------------------------------------------------
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavBtn({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
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
  Widget build(final BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1a1a2e).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PageButton(
            icon: Icons.arrow_back_ios_rounded,
            enabled: currentPage > 0,
            onTap: () => onPageChanged(currentPage - 1),
          ),
          const SizedBox(width: 16),
          Text(
            '${currentPage + 1} / $totalPages',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(width: 16),
          _PageButton(
            icon: Icons.arrow_forward_ios_rounded,
            enabled: currentPage < totalPages - 1,
            onTap: () => onPageChanged(currentPage + 1),
          ),
        ],
      ),
    );
  }
}

class _PageButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: enabled ? Color(0xFFD4AF37) : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: enabled ? Color(0xFF0a0a1a) : Colors.white38,
            size: 16,
          ),
        ),
      ),
    );
  }
}

class GalleryNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const GalleryNavButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(final BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Color(0xFF1a1a2e).withOpacity(0.8),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Color(0xFFD4AF37)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 10,
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Color(0xFFD4AF37),
            size: 24,
          ),
        ),
      ),
    );
  }
}
