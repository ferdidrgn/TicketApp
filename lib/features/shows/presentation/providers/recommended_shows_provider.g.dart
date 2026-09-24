// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recommended_shows_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(recommendedShows)
const recommendedShowsProvider = RecommendedShowsProvider._();

final class RecommendedShowsProvider extends $FunctionalProvider<
        AsyncValue<List<Show>>, List<Show>, FutureOr<List<Show>>>
    with $FutureModifier<List<Show>>, $FutureProvider<List<Show>> {
  const RecommendedShowsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'recommendedShowsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$recommendedShowsHash();

  @$internal
  @override
  $FutureProviderElement<List<Show>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Show>> create(Ref ref) {
    return recommendedShows(ref);
  }
}

String _$recommendedShowsHash() => r'169c3d44b7ab1b84eab9e742ed6624e8b62c7622';
