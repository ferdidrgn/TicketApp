import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:video_player/video_player.dart';

part 'home_asset_video_provider.g.dart';

// UI'ın ihtiyacı olan minimum state yapısı
class HomeVideoState {
  final VideoPlayerController? controller;
  final bool isReady;
  final String? error;

  HomeVideoState({this.controller, this.isReady = false, this.error});
}

@riverpod
class HomeVideoAsset extends _$HomeVideoAsset {
  @override
  HomeVideoState build() {
    // Provider dispose edildiğinde controller'ı da otomatik kapatıyoruz.
    ref.onDispose(() => state.controller?.dispose());
    return HomeVideoState();
  }

  Future<void> init() async {
    if (state.isReady) return;

    try {
      // Orijinal dosmandaki Firebase URL'si:
      final videoUrl = Uri.parse(
          'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2FIMG_20250310_200748-ANIMATION.mp4?alt=media&token=feab36d3-1d54-4ff8-868f-76f6591e8705');

      final controller = VideoPlayerController.networkUrl(videoUrl);

      // Web ve Mobil uyumu için sessiz başlatma ve döngü ayarları
      await controller.setVolume(0);
      await controller.setLooping(true);

      await controller.initialize();

      state = HomeVideoState(controller: controller, isReady: true);
      await controller.play();
    } catch (e) {
      state = HomeVideoState(error: e.toString());
    }
  }

  // 🎮 Kontrol metodları direkt burada:
  void togglePlay() {
    if (state.controller?.value.isPlaying ?? false)
      state.controller?.pause();
    else
      state.controller?.play();

    // State değiştiği için UI otomatik yenilenir
    ref.notifyListeners();
  }
}
