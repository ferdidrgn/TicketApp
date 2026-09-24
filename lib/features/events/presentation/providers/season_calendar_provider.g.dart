// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'season_calendar_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Tüm oyunların tüm etkinliklerini tek bir listede, tarihe göre sıralı
/// olarak döner. Sezon takvimi gibi "tüm oyunlar" görünümleri bunu kullanır.
///
/// Gerçek Firestore verisini kullanır: sahte/placeholder oyun adı göstermez.
/// Show <-> Event ilişkisi iki bağımsız yönde tutuluyor (`Show.eventsId`
/// dizisi VE `Event.showId` alanı) — biri senkron kalmayı unutabilir. Bu
/// fonksiyon önceden SADECE `Show.eventsId` dizisini kullanıyordu; bir
/// event'in kendi `showId` alanı dolu ama hiçbir gösterinin dizisinde
/// listelenmemişse o event burada sessizce hiç görünmüyordu (tam olarak
/// "ana sayfada hâlâ yanlış oyun gösteriliyor" hatasının kök nedeniyle
/// aynı mekanizma — bkz. `show_provider.dart`'taki
/// `_activeShowIdsFromEvents`). Artık her iki yoldan gelen sonuçlar
/// birleştiriliyor.

@ProviderFor(seasonCalendarEntries)
const seasonCalendarEntriesProvider = SeasonCalendarEntriesProvider._();

/// Tüm oyunların tüm etkinliklerini tek bir listede, tarihe göre sıralı
/// olarak döner. Sezon takvimi gibi "tüm oyunlar" görünümleri bunu kullanır.
///
/// Gerçek Firestore verisini kullanır: sahte/placeholder oyun adı göstermez.
/// Show <-> Event ilişkisi iki bağımsız yönde tutuluyor (`Show.eventsId`
/// dizisi VE `Event.showId` alanı) — biri senkron kalmayı unutabilir. Bu
/// fonksiyon önceden SADECE `Show.eventsId` dizisini kullanıyordu; bir
/// event'in kendi `showId` alanı dolu ama hiçbir gösterinin dizisinde
/// listelenmemişse o event burada sessizce hiç görünmüyordu (tam olarak
/// "ana sayfada hâlâ yanlış oyun gösteriliyor" hatasının kök nedeniyle
/// aynı mekanizma — bkz. `show_provider.dart`'taki
/// `_activeShowIdsFromEvents`). Artık her iki yoldan gelen sonuçlar
/// birleştiriliyor.

final class SeasonCalendarEntriesProvider extends $FunctionalProvider<
        AsyncValue<List<SeasonCalendarEntry>>,
        List<SeasonCalendarEntry>,
        FutureOr<List<SeasonCalendarEntry>>>
    with
        $FutureModifier<List<SeasonCalendarEntry>>,
        $FutureProvider<List<SeasonCalendarEntry>> {
  /// Tüm oyunların tüm etkinliklerini tek bir listede, tarihe göre sıralı
  /// olarak döner. Sezon takvimi gibi "tüm oyunlar" görünümleri bunu kullanır.
  ///
  /// Gerçek Firestore verisini kullanır: sahte/placeholder oyun adı göstermez.
  /// Show <-> Event ilişkisi iki bağımsız yönde tutuluyor (`Show.eventsId`
  /// dizisi VE `Event.showId` alanı) — biri senkron kalmayı unutabilir. Bu
  /// fonksiyon önceden SADECE `Show.eventsId` dizisini kullanıyordu; bir
  /// event'in kendi `showId` alanı dolu ama hiçbir gösterinin dizisinde
  /// listelenmemişse o event burada sessizce hiç görünmüyordu (tam olarak
  /// "ana sayfada hâlâ yanlış oyun gösteriliyor" hatasının kök nedeniyle
  /// aynı mekanizma — bkz. `show_provider.dart`'taki
  /// `_activeShowIdsFromEvents`). Artık her iki yoldan gelen sonuçlar
  /// birleştiriliyor.
  const SeasonCalendarEntriesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'seasonCalendarEntriesProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$seasonCalendarEntriesHash();

  @$internal
  @override
  $FutureProviderElement<List<SeasonCalendarEntry>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<SeasonCalendarEntry>> create(Ref ref) {
    return seasonCalendarEntries(ref);
  }
}

String _$seasonCalendarEntriesHash() =>
    r'cbf8291e286ea0ac419233ff7a77fac5a3b547fc';
