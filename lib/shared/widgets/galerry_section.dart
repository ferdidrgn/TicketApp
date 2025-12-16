import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/core/constants/app_constants.dart';
import '../../core/util/responsive_utils.dart';
import '../../features/shows/presentation/pages/show_detail_page_web.dart';
import '../../features/shows/presentation/providers/galerry_provider.dart';
import '../navigation/empty_state_message_web.dart';
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
    if (widget.photos.isEmpty) {
      return EmptyStateMessage(
        message: 'Galeri boş.',
        icon: Icons.photo_library,
      );
    }

    final isMobile = context.isMobile;
    final allPhotos = widget.photos;

    if (isMobile) {
      return SizedBox(
        height: 180,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: allPhotos.length,
          itemBuilder: (final context, final index) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GalleryItem(
                url: allPhotos[index],
                width: 220,
                height: 180,
                index: index,
                allPhotos: allPhotos,
                isMobile: isMobile,
              ),
            );
          },
        ),
      );
    }

    final totalPages =
        (allPhotos.length / AppConstants.galleryItemsPerPage).ceil();
    final startIndex = _currentPage * AppConstants.galleryItemsPerPage;
    final endIndex = math.min(
      startIndex + AppConstants.galleryItemsPerPage,
      allPhotos.length,
    );
    final currentPhotos = allPhotos.sublist(startIndex, endIndex);

    return Column(
      children: [
        Wrap(
          spacing: context.gridSpacing,
          runSpacing: context.gridSpacing,
          children: currentPhotos.asMap().entries.map((final entry) {
            final actualIndex = startIndex + entry.key;
            return GalleryItem(
              url: entry.value,
              width: 280,
              height: 210,
              index: actualIndex,
              allPhotos: allPhotos,
              isMobile: isMobile,
            );
          }).toList(),
        ),
        if (totalPages > 1)
          GalleryPaginationControls(
            currentPage: _currentPage,
            totalPages: totalPages,
            onPageChanged: (final page) {
              setState(() {
                _currentPage = page;
              });
            },
          ),
      ],
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

class GalleryItem extends ConsumerWidget {
  final String url;
  final double width;
  final double height;
  final int index;
  final List<String> allPhotos;
  final bool isMobile;

  const GalleryItem({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    required this.index,
    required this.allPhotos,
    required this.isMobile,
  });

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showFullImageGallery(context, ref),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Color(0xFFD4AF37).withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFD4AF37).withOpacity(0.15),
                blurRadius: 20,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: OptimizedCachedImage(
              imageUrl: url,
              width: width,
              height: height,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  void _showFullImageGallery(final BuildContext context, final WidgetRef ref) {
    final allImages = allPhotos;

    // Galeri state'ini ayarla
    ref.read(galleryProvider.notifier).setCurrentIndex(index);
    ref.read(galleryProvider.notifier).setTotalImages(allImages.length);

    showDialog(
      context: context,
      barrierColor: Color(0xFF0a0a1a).withOpacity(0.98),
      barrierDismissible: true,
      builder: (final context) {
        return Consumer(
          builder: (final context, final ref, final child) {
            final galleryState = ref.watch(galleryProvider);
            final currentIndex = galleryState.currentIndex;

            return GalleryViewerDialog(
              allImages: allImages,
              currentIndex: currentIndex,
              isMobile: isMobile,
              ref: ref,
            );
          },
        );
      },
    ).then((final _) {
      // Dialog kapatıldığında state'i sıfırla
      ref.read(galleryProvider.notifier).reset();
    });
  }
}

class GalleryViewerDialog extends StatelessWidget {
  final List<String> allImages;
  final int currentIndex;
  final bool isMobile;
  final WidgetRef ref;

  const GalleryViewerDialog({
    super.key,
    required this.allImages,
    required this.currentIndex,
    required this.isMobile,
    required this.ref,
  });

  @override
  Widget build(final BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Arka plan overlay
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),

            // Ana görsel ve kontroller
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Görsel sayacı
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      '${currentIndex + 1} / ${allImages.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Görsel container
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.9,
                      maxHeight: MediaQuery.of(context).size.height * 0.8,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Ana görsel
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: OptimizedCachedImage(
                            key: ValueKey(currentIndex),
                            imageUrl: allImages[currentIndex],
                            fit: BoxFit.contain,
                            width: MediaQuery.of(context).size.width * 0.85,
                            height: MediaQuery.of(context).size.height * 0.75,
                          ),
                        ),

                        // Navigasyon butonları
                        Positioned.fill(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (currentIndex > 0)
                                Padding(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: GalleryNavButton(
                                    icon: Icons.arrow_back_ios_rounded,
                                    onTap: () {
                                      ref
                                          .read(galleryProvider.notifier)
                                          .previousImage();
                                    },
                                  ),
                                ),
                              if (currentIndex < allImages.length - 1)
                                Padding(
                                  padding: const EdgeInsets.only(right: 20),
                                  child: GalleryNavButton(
                                    icon: Icons.arrow_forward_ios_rounded,
                                    onTap: () {
                                      ref
                                          .read(galleryProvider.notifier)
                                          .nextImage();
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Klavye kontrolleri
                        RawKeyboardListener(
                          focusNode: FocusNode(),
                          onKey: (final RawKeyEvent event) {
                            if (event is RawKeyDownEvent) {
                              if (event.logicalKey ==
                                  LogicalKeyboardKey.arrowLeft) {
                                if (currentIndex > 0) {
                                  ref
                                      .read(galleryProvider.notifier)
                                      .previousImage();
                                }
                              } else if (event.logicalKey ==
                                  LogicalKeyboardKey.arrowRight) {
                                if (currentIndex < allImages.length - 1) {
                                  ref
                                      .read(galleryProvider.notifier)
                                      .nextImage();
                                }
                              } else if (event.logicalKey ==
                                  LogicalKeyboardKey.escape) {
                                Navigator.pop(context);
                              }
                            }
                          },
                          child: const SizedBox(),
                        ),
                      ],
                    ),
                  ),

                  // Küçük thumbnail'ler (mobil değilse)
                  if (!isMobile && allImages.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Container(
                        height: 80,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: ListView.separated(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: allImages.length,
                          separatorBuilder: (final _, final __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (final context, final idx) {
                            return GestureDetector(
                              onTap: () {
                                ref
                                    .read(galleryProvider.notifier)
                                    .setCurrentIndex(idx);
                              },
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: idx == currentIndex
                                        ? Color(0xFFD4AF37)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: OptimizedCachedImage(
                                    imageUrl: allImages[idx],
                                    fit: BoxFit.cover,
                                    width: 60,
                                    height: 60,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Kapatma butonu
            Positioned(
              top: 40,
              right: 40,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF1a1a2e).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Color(0xFFD4AF37)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                      ),
                    ],
                  ), // Renkler
                  child: Icon(
                    Icons.close,
                    color: Color(0xFFD4AF37),
                    size: 24,
                  ),
                ),
              ),
            ),

            // Swipe gesture (mobil için)
            if (isMobile)
              Positioned.fill(
                child: Row(
                  children: [
                    // Sol swipe alanı
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (currentIndex > 0) {
                            ref.read(galleryProvider.notifier).previousImage();
                          }
                        },
                        child: Container(color: Colors.transparent),
                      ),
                    ),

                    // Sağ swipe alanı
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (currentIndex < allImages.length - 1) {
                            ref.read(galleryProvider.notifier).nextImage();
                          }
                        },
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ],
                ),
              ),
          ],
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
