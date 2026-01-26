// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'show_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ShowSearch)
const showSearchProvider = ShowSearchProvider._();

final class ShowSearchProvider
    extends $AsyncNotifierProvider<ShowSearch, List<Show>> {
  const ShowSearchProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'showSearchProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$showSearchHash();

  @$internal
  @override
  ShowSearch create() => ShowSearch();
}

String _$showSearchHash() => r'5e75b270340de9a9951037f73f1aa5502bc5fe13';

abstract class _$ShowSearch extends $AsyncNotifier<List<Show>> {
  FutureOr<List<Show>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Show>>, List<Show>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<Show>>, List<Show>>,
        AsyncValue<List<Show>>,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}
