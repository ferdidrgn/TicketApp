// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'season_calendar_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(seasonCalendarEntries)
const seasonCalendarEntriesProvider = SeasonCalendarEntriesProvider._();

final class SeasonCalendarEntriesProvider extends $FunctionalProvider<
        AsyncValue<List<SeasonCalendarEntry>>,
        List<SeasonCalendarEntry>,
        FutureOr<List<SeasonCalendarEntry>>>
    with
        $FutureModifier<List<SeasonCalendarEntry>>,
        $FutureProvider<List<SeasonCalendarEntry>> {
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
    r'8f2c4d6a1b9e7305c8f1a2d4e6b7c9a0d3f5e8b1';
