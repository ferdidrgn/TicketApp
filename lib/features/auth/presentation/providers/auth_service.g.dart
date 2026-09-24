// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AuthService)
const authServiceProvider = AuthServiceProvider._();

final class AuthServiceProvider extends $NotifierProvider<AuthService, User?> {
  const AuthServiceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'authServiceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$authServiceHash();

  @$internal
  @override
  AuthService create() => AuthService();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(User? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<User?>(value),
    );
  }
}

String _$authServiceHash() => r'f114069f8eed350e77f394cf59cf991676a04c9c';

abstract class _$AuthService extends $Notifier<User?> {
  User? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<User?, User?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<User?, User?>, User?, Object?, Object?>;
    element.handleValue(ref, created);
  }
}
