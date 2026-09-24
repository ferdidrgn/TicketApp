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
///
/// Firestore'daki yarım/taslak bir kampanya kaydı (başlığı ve/veya görseli
/// boş bırakılmış) her tüketicide (ana sayfa web/mobil, promo banner,
/// kampanya vitrini) aynı kırık görünümü üretiyordu: boş, metinsiz, gri bir
/// "resim yüklenemedi" kutusu. Böyle eksik kayıtlar burada, TEK bir yerde,
/// listeden çıkarılıyor — sahte bir başlık/görsel uydurulmuyor, sadece
/// gösterilecek kadar tam olmayan kayıt sessizce düşürülüyor.

@ProviderFor(campaigns)
const campaignsProvider = CampaignsProvider._();

/// 2. 🔥 KAMPANYA LİSTESİ (FutureProvider)
/// Fonksiyon ismi 'campaigns' -> Üretilen: 'campaignsProvider'
/// @riverpod default olarak 'autoDispose'dur.
///
/// Firestore'daki yarım/taslak bir kampanya kaydı (başlığı ve/veya görseli
/// boş bırakılmış) her tüketicide (ana sayfa web/mobil, promo banner,
/// kampanya vitrini) aynı kırık görünümü üretiyordu: boş, metinsiz, gri bir
/// "resim yüklenemedi" kutusu. Böyle eksik kayıtlar burada, TEK bir yerde,
/// listeden çıkarılıyor — sahte bir başlık/görsel uydurulmuyor, sadece
/// gösterilecek kadar tam olmayan kayıt sessizce düşürülüyor.

final class CampaignsProvider extends $FunctionalProvider<
        AsyncValue<List<Campaign>>, List<Campaign>, FutureOr<List<Campaign>>>
    with $FutureModifier<List<Campaign>>, $FutureProvider<List<Campaign>> {
  /// 2. 🔥 KAMPANYA LİSTESİ (FutureProvider)
  /// Fonksiyon ismi 'campaigns' -> Üretilen: 'campaignsProvider'
  /// @riverpod default olarak 'autoDispose'dur.
  ///
  /// Firestore'daki yarım/taslak bir kampanya kaydı (başlığı ve/veya görseli
  /// boş bırakılmış) her tüketicide (ana sayfa web/mobil, promo banner,
  /// kampanya vitrini) aynı kırık görünümü üretiyordu: boş, metinsiz, gri bir
  /// "resim yüklenemedi" kutusu. Böyle eksik kayıtlar burada, TEK bir yerde,
  /// listeden çıkarılıyor — sahte bir başlık/görsel uydurulmuyor, sadece
  /// gösterilecek kadar tam olmayan kayıt sessizce düşürülüyor.
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
  $FutureProviderElement<List<Campaign>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Campaign>> create(Ref ref) {
    return campaigns(ref);
  }
}

String _$campaignsHash() => r'878cd41f47328feec7eb1702d8114996dbe0cb67';
