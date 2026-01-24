// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_asset_video_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HomeVideoAsset)
const homeVideoAssetProvider = HomeVideoAssetProvider._();

final class HomeVideoAssetProvider
    extends $NotifierProvider<HomeVideoAsset, HomeVideoState> {
  const HomeVideoAssetProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'homeVideoAssetProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$homeVideoAssetHash();

  @$internal
  @override
  HomeVideoAsset create() => HomeVideoAsset();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HomeVideoState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HomeVideoState>(value),
    );
  }
}

String _$homeVideoAssetHash() => r'9e5dc8a5e0e378fb257ca43650af1fd3f025eec7';

abstract class _$HomeVideoAsset extends $Notifier<HomeVideoState> {
  HomeVideoState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<HomeVideoState, HomeVideoState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<HomeVideoState, HomeVideoState>,
        HomeVideoState,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
