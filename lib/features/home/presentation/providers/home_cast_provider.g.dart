// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_cast_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(homeCast)
const homeCastProvider = HomeCastProvider._();

final class HomeCastProvider extends $FunctionalProvider<
        AsyncValue<List<Player>>, List<Player>, FutureOr<List<Player>>>
    with $FutureModifier<List<Player>>, $FutureProvider<List<Player>> {
  const HomeCastProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'homeCastProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$homeCastHash();

  @$internal
  @override
  $FutureProviderElement<List<Player>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Player>> create(Ref ref) {
    return homeCast(ref);
  }
}

String _$homeCastHash() => r'007301bf2bb73d144bd9ae9b00e634b086e44ad3';
