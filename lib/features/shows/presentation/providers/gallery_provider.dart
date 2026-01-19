import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gallery_provider.g.dart';

@immutable
class GalleryState {
  final int currentIndex;
  final int totalImages;

  const GalleryState({required this.currentIndex, required this.totalImages});

  factory GalleryState.initial(final int total) =>
      GalleryState(currentIndex: 0, totalImages: total);

  GalleryState copyWith({final int? currentIndex, final int? totalImages}) =>
      GalleryState(
          currentIndex: currentIndex ?? this.currentIndex,
          totalImages: totalImages ?? this.totalImages);
}

// @riverpod annotasyonu hem autoDispose hem de family desteğini otomatik halleder.
// (int totalCount) parametresi sayesinde bu artık bir 'Family' provider olur.
@riverpod
class Gallery extends _$Gallery {
  // Sayfa kapandığında state otomatik temizlenir (autoDispose varsayılandır)

  @override
  GalleryState build(final int totalCount) => GalleryState.initial(totalCount);

  void setCurrentIndex(final int index) {
    if (index >= 0 && index < state.totalImages)
      state = state.copyWith(currentIndex: index);
  }

  void nextImage() {
    if (state.currentIndex < (state.totalImages - 1))
      state = state.copyWith(currentIndex: state.currentIndex + 1);
  }

  void previousImage() {
    if (state.currentIndex > 0)
      state = state.copyWith(currentIndex: state.currentIndex - 1);
  }
}
