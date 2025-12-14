import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Modern import
import 'package:video_player/video_player.dart';

// 1. STATE SINIFI (Aynı kalıyor)
class HomeAssetsState {
  final VideoPlayerController? videoController;
  final bool isVideoReady;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;

  HomeAssetsState({
    this.videoController,
    this.isVideoReady = false,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
  });

  HomeAssetsState copyWith({
    final VideoPlayerController? videoController,
    final bool? isVideoReady,
    final bool? isLoading,
    final bool? hasError,
    final String? errorMessage,
  }) {
    return HomeAssetsState(
      videoController: videoController ?? this.videoController,
      isVideoReady: isVideoReady ?? this.isVideoReady,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// 2. NOTIFIER SINIFI (GÜNCELLENDİ: StateNotifier -> Notifier)
class HomeAssetsNotifier extends Notifier<HomeAssetsState> {
  // 🚀 DEĞİŞİKLİK 1: Constructor yerine build() metodu geldi.
  // Başlangıç değerini burada veriyoruz.
  @override
  HomeAssetsState build() => HomeAssetsState();

  bool _isInitializing = false;

  Future<void> initializeVideo() async {
    // state'e erişim aynen devam eder
    if (_isInitializing || (state.isVideoReady && !state.hasError))
      return;

    _isInitializing = true;
    state = state.copyWith(isLoading: true);
    debugPrint('🎬 Video yükleme işlemi başladı...');

    try {
      // Test URL'si (HTTPS)
      final videoUrl = Uri.parse(
        'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2FIMG_20250310_200748-ANIMATION.mp4?alt=media&token=feab36d3-1d54-4ff8-868f-76f6591e8705',
      );

      final controller = VideoPlayerController.networkUrl(videoUrl);

      await controller.setVolume(0);
      await controller.setLooping(true);

      await controller.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Video sunucudan yanıt vermedi (Timeout).');
        },
      );

      state = HomeAssetsState(
        videoController: controller,
        isVideoReady: true,
        isLoading: false,
        hasError: false,
      );

      debugPrint('✅ Video başarıyla yüklendi.');
      await controller.play();
    } catch (e) {
      debugPrint('❌ VİDEO YÜKLEME HATASI: $e');
      state = HomeAssetsState(
        isVideoReady: true,
        isLoading: false,
        hasError: true,
        errorMessage: e.toString(),
      );
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> playVideo() async {
    final controller = state.videoController;
    if (controller != null && controller.value.isInitialized)
      if (!controller.value.isPlaying)
        await controller.play();
  }

// Notifier'da dispose yoktur, Riverpod kendi halleder.
// Ancak Controller'ı kapatmak için "ref.onDispose" kullanılır.
// Ama şimdilik basit tutmak için controller dispose işlemini
// widget tarafında veya provider kapatılırken yapmak daha doğrudur.
}

// 3. PROVIDER TANIMI (GÜNCELLENDİ: StateNotifierProvider -> NotifierProvider)
final homeAssetsProvider =
    NotifierProvider<HomeAssetsNotifier, HomeAssetsState>(() {
  return HomeAssetsNotifier();
});
