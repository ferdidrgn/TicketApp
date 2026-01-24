// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'show_mutation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ShowMutation)
const showMutationProvider = ShowMutationProvider._();

final class ShowMutationProvider
    extends $AsyncNotifierProvider<ShowMutation, void> {
  const ShowMutationProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'showMutationProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$showMutationHash();

  @$internal
  @override
  ShowMutation create() => ShowMutation();
}

String _$showMutationHash() => r'66d0478be7d0937ca5776ec1b500513ea5832b07';

abstract class _$ShowMutation extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<void>, void>,
        AsyncValue<void>,
        Object?,
        Object?>;
    element.handleValue(ref, null);
  }
}
