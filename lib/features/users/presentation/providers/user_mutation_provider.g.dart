// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_mutation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserMutation)
const userMutationProvider = UserMutationProvider._();

final class UserMutationProvider
    extends $AsyncNotifierProvider<UserMutation, void> {
  const UserMutationProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'userMutationProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$userMutationHash();

  @$internal
  @override
  UserMutation create() => UserMutation();
}

String _$userMutationHash() => r'2c420d8713d0c421ec203f50cc55545309221ca2';

abstract class _$UserMutation extends $AsyncNotifier<void> {
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
