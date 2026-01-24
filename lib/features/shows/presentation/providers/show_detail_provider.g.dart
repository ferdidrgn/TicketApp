// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'show_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 🔥 COMPOSITE PROVIDER (Tüm veriyi burada topluyoruz)

@ProviderFor(showDetail)
const showDetailProvider = ShowDetailFamily._();

/// 🔥 COMPOSITE PROVIDER (Tüm veriyi burada topluyoruz)

final class ShowDetailProvider extends $FunctionalProvider<
        AsyncValue<ShowDetailState>, ShowDetailState, FutureOr<ShowDetailState>>
    with $FutureModifier<ShowDetailState>, $FutureProvider<ShowDetailState> {
  /// 🔥 COMPOSITE PROVIDER (Tüm veriyi burada topluyoruz)
  const ShowDetailProvider._(
      {required ShowDetailFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'showDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$showDetailHash();

  @override
  String toString() {
    return r'showDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ShowDetailState> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ShowDetailState> create(Ref ref) {
    final argument = this.argument as String;
    return showDetail(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ShowDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$showDetailHash() => r'0ce269f01187d902ea19e2efefe4167e80648781';

/// 🔥 COMPOSITE PROVIDER (Tüm veriyi burada topluyoruz)

final class ShowDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ShowDetailState>, String> {
  const ShowDetailFamily._()
      : super(
          retry: null,
          name: r'showDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// 🔥 COMPOSITE PROVIDER (Tüm veriyi burada topluyoruz)

  ShowDetailProvider call(
    String showId,
  ) =>
      ShowDetailProvider._(argument: showId, from: this);

  @override
  String toString() => r'showDetailProvider';
}
