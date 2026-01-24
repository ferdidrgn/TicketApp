// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stage_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(stageDetail)
const stageDetailProvider = StageDetailFamily._();

final class StageDetailProvider extends $FunctionalProvider<
        AsyncValue<StageDetailState>,
        StageDetailState,
        FutureOr<StageDetailState>>
    with $FutureModifier<StageDetailState>, $FutureProvider<StageDetailState> {
  const StageDetailProvider._(
      {required StageDetailFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'stageDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$stageDetailHash();

  @override
  String toString() {
    return r'stageDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<StageDetailState> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<StageDetailState> create(Ref ref) {
    final argument = this.argument as String;
    return stageDetail(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StageDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stageDetailHash() => r'12229bed05769f332b57aa3118a434ff1ce4d699';

final class StageDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<StageDetailState>, String> {
  const StageDetailFamily._()
      : super(
          retry: null,
          name: r'stageDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  StageDetailProvider call(
    String stageId,
  ) =>
      StageDetailProvider._(argument: stageId, from: this);

  @override
  String toString() => r'stageDetailProvider';
}
