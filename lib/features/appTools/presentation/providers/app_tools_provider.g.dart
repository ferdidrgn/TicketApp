// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_tools_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(getPrivacyPolicyUseCase)
const getPrivacyPolicyUseCaseProvider = GetPrivacyPolicyUseCaseProvider._();

final class GetPrivacyPolicyUseCaseProvider extends $FunctionalProvider<
    GetPrivacyPolicyUseCase,
    GetPrivacyPolicyUseCase,
    GetPrivacyPolicyUseCase> with $Provider<GetPrivacyPolicyUseCase> {
  const GetPrivacyPolicyUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getPrivacyPolicyUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getPrivacyPolicyUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetPrivacyPolicyUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetPrivacyPolicyUseCase create(Ref ref) {
    return getPrivacyPolicyUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetPrivacyPolicyUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetPrivacyPolicyUseCase>(value),
    );
  }
}

String _$getPrivacyPolicyUseCaseHash() =>
    r'892a4f1a40c9d666fb5dfbaac2d6cb18cb53db83';

@ProviderFor(getTermsConditionUseCase)
const getTermsConditionUseCaseProvider = GetTermsConditionUseCaseProvider._();

final class GetTermsConditionUseCaseProvider extends $FunctionalProvider<
    GetTermsConditionUseCase,
    GetTermsConditionUseCase,
    GetTermsConditionUseCase> with $Provider<GetTermsConditionUseCase> {
  const GetTermsConditionUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getTermsConditionUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getTermsConditionUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetTermsConditionUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetTermsConditionUseCase create(Ref ref) {
    return getTermsConditionUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetTermsConditionUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetTermsConditionUseCase>(value),
    );
  }
}

String _$getTermsConditionUseCaseHash() =>
    r'80e8cc0574cb0261c5478e26cd97b8c07d5eed40';

@ProviderFor(privacyPolicy)
const privacyPolicyProvider = PrivacyPolicyProvider._();

final class PrivacyPolicyProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  const PrivacyPolicyProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'privacyPolicyProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$privacyPolicyHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return privacyPolicy(ref);
  }
}

String _$privacyPolicyHash() => r'3b90f256bfaea68a5ad7f910fb345b14f1efcca6';

@ProviderFor(termsCondition)
const termsConditionProvider = TermsConditionProvider._();

final class TermsConditionProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  const TermsConditionProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'termsConditionProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$termsConditionHash();

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    return termsCondition(ref);
  }
}

String _$termsConditionHash() => r'1e76dbe9f03f5f9febbbf59e46103d9e5f3c9e9a';
