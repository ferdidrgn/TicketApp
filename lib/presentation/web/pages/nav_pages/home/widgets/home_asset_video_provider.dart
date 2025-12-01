import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:video_player/video_player.dart';

// Video durumunu takip eden State sınıfı
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
    VideoPlayerController? videoController,
    bool? isVideoReady,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
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

class HomeAssetsNotifier extends StateNotifier<HomeAssetsState> {
  HomeAssetsNotifier() : super(HomeAssetsState());

  bool _isInitializing = false;

  Future<void> initializeVideo() async {
    // Eğer zaten yükleme yapılıyorsa veya yüklendiyse çık
    if (_isInitializing || state.isVideoReady) {
      return;
    }

    _isInitializing = true;

    // Loading başlat
    state = state.copyWith(isLoading: true);
    debugPrint('🎬 Video yükleme zorlanıyor (Tarayıcı kontrolü devre dışı)...');

    try {
      final videoUrl = Uri.parse(
        'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2FIMG_20250310_200748-ANIMATION.mp4?alt=media&token=feab36d3-1d54-4ff8-868f-76f6591e8705',
      );

      // Controller oluştur
      final controller = VideoPlayerController.networkUrl(videoUrl);

      // Timeout süresini biraz artırdık ki yavaş bağlantılarda hemen hata vermesin
      await controller.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Video yükleme zaman aşımı');
        },
      );

      // --- OTOMATİK OYNATMA İÇİN KRİTİK AYARLAR ---
      await controller.setLooping(true); // Döngü
      await controller.setVolume(0);     // Sessiz (Autoplay için şart)
      await controller.setPlaybackSpeed(0.5); // İsteğe bağlı hız
      // -------------------------------------------

      // State'i güncelle - Video hazır!
      state = HomeAssetsState(
        videoController: controller,
        isVideoReady: true,
        isLoading: false,
        hasError: false,
      );

      debugPrint('✅ Video hazır, sessiz ve döngüde oynatılıyor.');

      // Otomatik oynatmayı başlat
      await playVideo();

    } catch (e) {
      debugPrint('❌ VIDEO HATA: $e');
      // Hata olsa bile sistemi kilitleme, fallback (arkaplan) görünsün
      state = HomeAssetsState(
        isVideoReady: true, // Hata olsa bile ready ver ki splash kapansın
        isLoading: false,
        hasError: true,
        errorMessage: e.toString(),
      );
    } finally {
      _isInitializing = false;
    }
  }

  // Videoyu oynatma tetikleyicisi
  Future<void> playVideo() async {
    if (state.videoController != null && state.videoController!.value.isInitialized) {
      try {
        if (!state.videoController!.value.isPlaying) {
          await state.videoController!.play();
        }
      } catch (e) {
        debugPrint('Oynatma hatası: $e');
      }
    }
  }

  @override
  void dispose() {
    state.videoController?.dispose();
    super.dispose();
  }
}

final homeAssetsProvider =
StateNotifierProvider<HomeAssetsNotifier, HomeAssetsState>((ref) {
  return HomeAssetsNotifier();
});