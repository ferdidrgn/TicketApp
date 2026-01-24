// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_query_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SearchFilter)
const searchFilterProvider = SearchFilterProvider._();

final class SearchFilterProvider extends $NotifierProvider<SearchFilter, int> {
  const SearchFilterProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'searchFilterProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$searchFilterHash();

  @$internal
  @override
  SearchFilter create() => SearchFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$searchFilterHash() => r'd738404002624c5bde7ee1d4bfd7022233f96f44';

abstract class _$SearchFilter extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<int, int>;
    final element = ref.element
        as $ClassProviderElement<AnyNotifier<int, int>, int, Object?, Object?>;
    element.handleValue(ref, created);
  }
}

@ProviderFor(SearchQuery)
const searchQueryProvider = SearchQueryProvider._();

final class SearchQueryProvider extends $NotifierProvider<SearchQuery, String> {
  const SearchQueryProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'searchQueryProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$searchQueryHash();

  @$internal
  @override
  SearchQuery create() => SearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$searchQueryHash() => r'36a87b4caf6180e24001bc7d65aadc70ded18b28';

abstract class _$SearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String, String>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<String, String>, String, Object?, Object?>;
    element.handleValue(ref, created);
  }
}

/// 🔥 MERKEZİ ARAMA MANTIĞI

@ProviderFor(searchResult)
const searchResultProvider = SearchResultProvider._();

/// 🔥 MERKEZİ ARAMA MANTIĞI

final class SearchResultProvider extends $FunctionalProvider<SearchResultState,
    SearchResultState, SearchResultState> with $Provider<SearchResultState> {
  /// 🔥 MERKEZİ ARAMA MANTIĞI
  const SearchResultProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'searchResultProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$searchResultHash();

  @$internal
  @override
  $ProviderElement<SearchResultState> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SearchResultState create(Ref ref) {
    return searchResult(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SearchResultState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SearchResultState>(value),
    );
  }
}

String _$searchResultHash() => r'b8c49d131de11c501b6316a41c6cd1957334c666';
