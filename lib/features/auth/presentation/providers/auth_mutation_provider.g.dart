// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_mutation_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OtpTimer)
const otpTimerProvider = OtpTimerProvider._();

final class OtpTimerProvider extends $NotifierProvider<OtpTimer, int> {
  const OtpTimerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'otpTimerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$otpTimerHash();

  @$internal
  @override
  OtpTimer create() => OtpTimer();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$otpTimerHash() => r'6b6b8551f2380a74cc2623966154c3bd22a13507';

abstract class _$OtpTimer extends $Notifier<int> {
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

String _$authMutationHash() => r'1211390c788b28c0198dd20a5aa3defc721ed337';

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
