// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_asset_video_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HomeAssets)
const homeAssetsProvider = HomeAssetsProvider._();

final class HomeAssetsProvider
    extends $NotifierProvider<HomeAssets, AsyncValue<VideoPlayerController?>> {
  const HomeAssetsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'homeAssetsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$homeAssetsHash();

  @$internal
  @override
  HomeAssets create() => HomeAssets();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<VideoPlayerController?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<VideoPlayerController?>>(value),
    );
  }
}

String _$homeAssetsHash() => r'008f4cf4a983d4f4705695322d8a208474b50039';

abstract class _$HomeAssets
    extends $Notifier<AsyncValue<VideoPlayerController?>> {
  AsyncValue<VideoPlayerController?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<VideoPlayerController?>,
        AsyncValue<VideoPlayerController?>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<VideoPlayerController?>,
            AsyncValue<VideoPlayerController?>>,
        AsyncValue<VideoPlayerController?>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
