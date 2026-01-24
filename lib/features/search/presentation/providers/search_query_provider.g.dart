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

String _$searchFilterHash() => r'd9c1315f358217817562efdcf5205012268869ca';

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

String _$searchQueryHash() => r'b38ca647f4785c77d51c7724d55c42fdeada582d';

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

@ProviderFor(searchResult)
const searchResultProvider = SearchResultProvider._();

final class SearchResultProvider extends $FunctionalProvider<SearchResultState,
    SearchResultState, SearchResultState> with $Provider<SearchResultState> {
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

String _$searchResultHash() => r'01f59c6aee696244717f92bda3997b62bc21ffa2';
