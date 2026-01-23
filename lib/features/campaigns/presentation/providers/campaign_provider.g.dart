// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campaign_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 1. UseCase Provider (Dependency Injection)
/// Fonksiyon ismi 'getCampaignsUseCase' -> Üretilen: 'getCampaignsUseCaseProvider'

@ProviderFor(getCampaignsUseCase)
const getCampaignsUseCaseProvider = GetCampaignsUseCaseProvider._();

/// 1. UseCase Provider (Dependency Injection)
/// Fonksiyon ismi 'getCampaignsUseCase' -> Üretilen: 'getCampaignsUseCaseProvider'

final class GetCampaignsUseCaseProvider extends $FunctionalProvider<
    GetCampaignsUseCase,
    GetCampaignsUseCase,
    GetCampaignsUseCase> with $Provider<GetCampaignsUseCase> {
  /// 1. UseCase Provider (Dependency Injection)
  /// Fonksiyon ismi 'getCampaignsUseCase' -> Üretilen: 'getCampaignsUseCaseProvider'
  const GetCampaignsUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getCampaignsUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getCampaignsUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetCampaignsUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetCampaignsUseCase create(Ref ref) {
    return getCampaignsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetCampaignsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetCampaignsUseCase>(value),
    );
  }
}

String _$getCampaignsUseCaseHash() =>
    r'e445385744f8c591fdd49bd211e69b9132c780bd';

/// 2. 🔥 KAMPANYA LİSTESİ (FutureProvider)
/// Fonksiyon ismi 'campaigns' -> Üretilen: 'campaignsProvider'
/// @riverpod default olarak 'autoDispose'dur.

@ProviderFor(campaigns)
const campaignsProvider = CampaignsProvider._();

/// 2. 🔥 KAMPANYA LİSTESİ (FutureProvider)
/// Fonksiyon ismi 'campaigns' -> Üretilen: 'campaignsProvider'
/// @riverpod default olarak 'autoDispose'dur.

final class CampaignsProvider
    extends $FunctionalProvider<List<Campaign>, List<Campaign>, List<Campaign>>
    with $Provider<List<Campaign>> {
  /// 2. 🔥 KAMPANYA LİSTESİ (FutureProvider)
  /// Fonksiyon ismi 'campaigns' -> Üretilen: 'campaignsProvider'
  /// @riverpod default olarak 'autoDispose'dur.
  const CampaignsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'campaignsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$campaignsHash();

  @$internal
  @override
  $ProviderElement<List<Campaign>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Campaign> create(Ref ref) {
    return campaigns(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Campaign> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Campaign>>(value),
    );
  }
}

String _$campaignsHash() => r'fe95b1be7bf253bcff553c321b0ba1757625961b';
