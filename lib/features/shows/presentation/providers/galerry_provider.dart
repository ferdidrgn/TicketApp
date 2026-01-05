import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final galleryProvider =
    NotifierProvider<GalleryNotifier, GalleryState>(GalleryNotifier.new);

@immutable
class GalleryState {
  final int currentIndex;
  final int totalImages;

  const GalleryState({
    this.currentIndex = 0,
    this.totalImages = 0,
  });

  GalleryState copyWith({
    final int? currentIndex,
    final int? totalImages,
  }) =>
      GalleryState(
        currentIndex: currentIndex ?? this.currentIndex,
        totalImages: totalImages ?? this.totalImages,
      );
}

class GalleryNotifier extends Notifier<GalleryState> {
  @override
  GalleryState build() => const GalleryState();

  void setCurrentIndex(final int index) =>
      state = state.copyWith(currentIndex: index);

  void nextImage() {
    if (state.currentIndex < (state.totalImages - 1))
      state = state.copyWith(currentIndex: state.currentIndex + 1);
  }

  void previousImage() {
    if (state.currentIndex > 0)
      state = state.copyWith(currentIndex: state.currentIndex - 1);
  }

  void reset() => state = const GalleryState();

  void setTotalImages(final int total) =>
      state = state.copyWith(totalImages: total);
}
