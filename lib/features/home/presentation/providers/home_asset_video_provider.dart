import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:video_player/video_player.dart';

part 'home_asset_video_provider.g.dart';

@riverpod
class HomeAssets extends _$HomeAssets {
  @override
  AsyncValue<VideoPlayerController?> build() {
    // Provider kapandığında belleği temizle
    ref.onDispose(() {
      state.value?.dispose();
    });
    return const AsyncValue.loading();
  }

  Future<void> initializeVideo() async {
    if (state.hasValue && state.value != null) return;

    state = const AsyncValue.loading();

    try {
      final videoUrl = Uri.parse(
          'https://firebasestorage.googleapis.com/v0/b/ticketappflutter.appspot.com/o/images%2Fmetafor%2FIMG_20250310_200748-ANIMATION.mp4?alt=media&token=feab36d3-1d54-4ff8-868f-76f6591e8705');

      final controller = VideoPlayerController.networkUrl(videoUrl);

      // Web performansı için sessiz ve loop ayarları
      await controller.initialize();
      await controller.setVolume(0);
      await controller.setLooping(true);

      state = AsyncValue.data(controller);
      await controller.play();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void playVideo() => state.value?.play();

  void pauseVideo() => state.value?.pause();
}
