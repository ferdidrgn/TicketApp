import 'package:flutter_riverpod/legacy.dart';
import 'package:video_player/video_player.dart';

// Video durumunu takip eden basit bir State sınıfı
class HomeAssetsState {
  final VideoPlayerController? videoController;
  final bool isVideoReady;

  HomeAssetsState({this.videoController, this.isVideoReady = false});
}

class HomeAssetsNotifier extends StateNotifier<HomeAssetsState> {
  HomeAssetsNotifier() : super(HomeAssetsState());

  Future<void> initializeVideo() async {
    // Eğer zaten yüklendiyse tekrar yapma
    if (state.isVideoReady) return;

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(
          'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2FIMG_20250310_200748-ANIMATION.mp4?alt=media&token=feab36d3-1d54-4ff8-868f-76f6591e8705',
        ),
      );

      // Sesi kapat, döngüye al ve hazırlanmasını bekle
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.setPlaybackSpeed(0.5);

      // Video hazır! State'i güncelle
      state = HomeAssetsState(videoController: controller, isVideoReady: true);

      // Hemen oynatmaya başla (Splash altındayken)
      await controller.play();
    } catch (e) {
      // Hata olursa en azından app takılmasın diye ready true çekilebilir
      // veya error state yönetilebilir. Şimdilik devam ettiriyoruz.
      state = HomeAssetsState(isVideoReady: true);
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
