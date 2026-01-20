// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_mutation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuthMutation)
const authMutationProvider = AuthMutationProvider._();

final class AuthMutationProvider
    extends $AsyncNotifierProvider<AuthMutation, void> {
  const AuthMutationProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'authMutationProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$authMutationHash();

  @$internal
  @override
  AuthMutation create() => AuthMutation();
}

String _$authMutationHash() => r'ad5d2cd2b6d6da5d17a6aedf8251fbba5b1a5f9b';

abstract class _$AuthMutation extends $AsyncNotifier<void> {
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
