// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'show_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ShowFilterController)
const showFilterControllerProvider = ShowFilterControllerProvider._();

final class ShowFilterControllerProvider
    extends $NotifierProvider<ShowFilterController, ShowFilterState> {
  const ShowFilterControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'showFilterControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$showFilterControllerHash();

  @$internal
  @override
  ShowFilterController create() => ShowFilterController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShowFilterState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShowFilterState>(value),
    );
  }
}

String _$showFilterControllerHash() =>
    r'd9076d79b89b30410e91801b25edffcdfe809542';

abstract class _$ShowFilterController extends $Notifier<ShowFilterState> {
  ShowFilterState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<ShowFilterState, ShowFilterState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<ShowFilterState, ShowFilterState>,
        ShowFilterState,
        Object?,
        Object?>;
    element.handleValue(ref, created);
  }
}

@ProviderFor(filteredShows)
const filteredShowsProvider = FilteredShowsProvider._();

final class FilteredShowsProvider extends $FunctionalProvider<
        AsyncValue<List<FilteredShow>>,
        List<FilteredShow>,
        FutureOr<List<FilteredShow>>>
    with
        $FutureModifier<List<FilteredShow>>,
        $FutureProvider<List<FilteredShow>> {
  const FilteredShowsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'filteredShowsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$filteredShowsHash();

  @$internal
  @override
  $FutureProviderElement<List<FilteredShow>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<FilteredShow>> create(Ref ref) {
    return filteredShows(ref);
  }
}

String _$filteredShowsHash() => r'8c292672821713bd0fcf11ff938aa186c2f5c38b';

/// Fiyat aralığı slider'ının GERÇEK alt/üst sınırı — sabit bir "0-2000 TL"
/// tahmini DEĞİL, o an var olan tüm gerçek etkinliklerin (`Event.price`)
/// en düşük/en yüksek değerinden hesaplanır. Hiç fiyatlı etkinlik yoksa
/// `null` döner — UI bu durumda fiyat filtresini tamamen gizlemeli.

@ProviderFor(priceRangeBounds)
const priceRangeBoundsProvider = PriceRangeBoundsProvider._();

/// Fiyat aralığı slider'ının GERÇEK alt/üst sınırı — sabit bir "0-2000 TL"
/// tahmini DEĞİL, o an var olan tüm gerçek etkinliklerin (`Event.price`)
/// en düşük/en yüksek değerinden hesaplanır. Hiç fiyatlı etkinlik yoksa
/// `null` döner — UI bu durumda fiyat filtresini tamamen gizlemeli.

final class PriceRangeBoundsProvider extends $FunctionalProvider<
        AsyncValue<
            ({
              double max,
              double min,
            })?>,
        ({
          double max,
          double min,
        })?,
        FutureOr<
            ({
              double max,
              double min,
            })?>>
    with
        $FutureModifier<
            ({
              double max,
              double min,
            })?>,
        $FutureProvider<
            ({
              double max,
              double min,
            })?> {
  /// Fiyat aralığı slider'ının GERÇEK alt/üst sınırı — sabit bir "0-2000 TL"
  /// tahmini DEĞİL, o an var olan tüm gerçek etkinliklerin (`Event.price`)
  /// en düşük/en yüksek değerinden hesaplanır. Hiç fiyatlı etkinlik yoksa
  /// `null` döner — UI bu durumda fiyat filtresini tamamen gizlemeli.
  const PriceRangeBoundsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'priceRangeBoundsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$priceRangeBoundsHash();

  @$internal
  @override
  $FutureProviderElement<
      ({
        double max,
        double min,
      })?> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<
      ({
        double max,
        double min,
      })?> create(Ref ref) {
    return priceRangeBounds(ref);
  }
}

String _$priceRangeBoundsHash() => r'0f4b4949cc185798bd74a0bac751b8826d907de7';

/// Filtre UI'ının kategori/tür seçeneklerini doldurmak için — sabit,
/// uydurma bir liste DEĞİL; o an gerçekten var olan gösterilerin kendi
/// `category`/`type` alanlarından türetilir. Yeni bir kategori Firestore'a
/// eklendiği an burada da otomatik görünür.

@ProviderFor(availableShowFilterOptions)
const availableShowFilterOptionsProvider =
    AvailableShowFilterOptionsProvider._();

/// Filtre UI'ının kategori/tür seçeneklerini doldurmak için — sabit,
/// uydurma bir liste DEĞİL; o an gerçekten var olan gösterilerin kendi
/// `category`/`type` alanlarından türetilir. Yeni bir kategori Firestore'a
/// eklendiği an burada da otomatik görünür.

final class AvailableShowFilterOptionsProvider extends $FunctionalProvider<
        AsyncValue<
            ({
              List<String> categories,
              List<String> types,
            })>,
        ({
          List<String> categories,
          List<String> types,
        }),
        FutureOr<
            ({
              List<String> categories,
              List<String> types,
            })>>
    with
        $FutureModifier<
            ({
              List<String> categories,
              List<String> types,
            })>,
        $FutureProvider<
            ({
              List<String> categories,
              List<String> types,
            })> {
  /// Filtre UI'ının kategori/tür seçeneklerini doldurmak için — sabit,
  /// uydurma bir liste DEĞİL; o an gerçekten var olan gösterilerin kendi
  /// `category`/`type` alanlarından türetilir. Yeni bir kategori Firestore'a
  /// eklendiği an burada da otomatik görünür.
  const AvailableShowFilterOptionsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'availableShowFilterOptionsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$availableShowFilterOptionsHash();

  @$internal
  @override
  $FutureProviderElement<
      ({
        List<String> categories,
        List<String> types,
      })> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<
      ({
        List<String> categories,
        List<String> types,
      })> create(Ref ref) {
    return availableShowFilterOptions(ref);
  }
}

String _$availableShowFilterOptionsHash() =>
    r'2555478e4c3739d35041aa131ceb8a80c077c152';
