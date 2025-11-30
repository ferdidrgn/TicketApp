import 'package:flutter_riverpod/legacy.dart';
import 'package:video_player/video_player.dart';

import '../../../../../../data/providers/ticket/ticket_notifier.dart';

// State sınıfı
class HomeAssetsState {
  final bool isVideoReady;
  final VideoPlayerController? videoController;

  HomeAssetsState({
    this.isVideoReady = false,
    this.videoController,
  });

  HomeAssetsState copyWith({
    bool? isVideoReady,
    VideoPlayerController? videoController,
  }) {
    return HomeAssetsState(
      isVideoReady: isVideoReady ?? this.isVideoReady,
      videoController: videoController ?? this.videoController,
    );
  }
}

// Notifier sınıfı
class HomeAssetsNotifier extends StateNotifier<HomeAssetsState> {
  HomeAssetsNotifier() : super(HomeAssetsState());

  Future<void> initializeVideo() async {
    try {
      // Eğer zaten varsa tekrar oluşturma
      if (state.videoController != null && state.videoController!.value.isInitialized) {
        return;
      }

      // 1. Controller'ı oluştur (mixWithOthers ÖNEMLİ)
      final controller = VideoPlayerController.asset(
        'assets/video/intro.mp4', // Videonun yolu doğru olduğundan emin ol
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      // 2. Başlat
      await controller.initialize();

      // 3. MOBİL İÇİN ZORUNLU AYARLAR
      await controller.setVolume(0.0); // Ses sıfır olmazsa mobil oynatmaz
      await controller.setLooping(true); // Döngü

      // State'i güncelle
      if (mounted) {
        state = state.copyWith(
          isVideoReady: true,
          videoController: controller,
        );
      }
    } catch (e) {
      debugPrint("Video Yükleme Hatası: $e");
    }
  }

  @override
  void dispose() {
    state.videoController?.dispose();
    super.dispose();
  }
}

// Provider
final homeAssetsProvider = StateNotifierProvider<HomeAssetsNotifier, HomeAssetsState>((ref) {
  return HomeAssetsNotifier();
});