// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seats_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(getSeatsByStageUseCase)
const getSeatsByStageUseCaseProvider = GetSeatsByStageUseCaseProvider._();

final class GetSeatsByStageUseCaseProvider extends $FunctionalProvider<
    GetSeatsByStageUseCase,
    GetSeatsByStageUseCase,
    GetSeatsByStageUseCase> with $Provider<GetSeatsByStageUseCase> {
  const GetSeatsByStageUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getSeatsByStageUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getSeatsByStageUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetSeatsByStageUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetSeatsByStageUseCase create(Ref ref) {
    return getSeatsByStageUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetSeatsByStageUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetSeatsByStageUseCase>(value),
    );
  }
}

String _$getSeatsByStageUseCaseHash() =>
    r'904efaa6d9690530e7beb4215ca5c6fd5343a39d';

/// 🔥 SAHNE KOLTUK PLANINI (LAYOUT) ÇEKER
/// Örn: Map<"A", ["A1", "A2"...]>

@ProviderFor(stageLayout)
const stageLayoutProvider = StageLayoutFamily._();

/// 🔥 SAHNE KOLTUK PLANINI (LAYOUT) ÇEKER
/// Örn: Map<"A", ["A1", "A2"...]>

final class StageLayoutProvider extends $FunctionalProvider<
        AsyncValue<Map<String, List<String>>>,
        Map<String, List<String>>,
        FutureOr<Map<String, List<String>>>>
    with
        $FutureModifier<Map<String, List<String>>>,
        $FutureProvider<Map<String, List<String>>> {
  /// 🔥 SAHNE KOLTUK PLANINI (LAYOUT) ÇEKER
  /// Örn: Map<"A", ["A1", "A2"...]>
  const StageLayoutProvider._(
      {required StageLayoutFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'stageLayoutProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$stageLayoutHash();

  @override
  String toString() {
    return r'stageLayoutProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, List<String>>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, List<String>>> create(Ref ref) {
    final argument = this.argument as String;
    return stageLayout(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is StageLayoutProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$stageLayoutHash() => r'46a20f8c74fdbb050f458eee293c3c69d4f5375a';

/// 🔥 SAHNE KOLTUK PLANINI (LAYOUT) ÇEKER
/// Örn: Map<"A", ["A1", "A2"...]>

final class StageLayoutFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<Map<String, List<String>>>, String> {
  const StageLayoutFamily._()
      : super(
          retry: null,
          name: r'stageLayoutProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// 🔥 SAHNE KOLTUK PLANINI (LAYOUT) ÇEKER
  /// Örn: Map<"A", ["A1", "A2"...]>

  StageLayoutProvider call(
    String stageId,
  ) =>
      StageLayoutProvider._(argument: stageId, from: this);

  @override
  String toString() => r'stageLayoutProvider';
}

/// 🚀 SELECTION & AUDIT İÇİN COMPOSITE PROVIDER
/// Bir etkinliğin ihtiyacı olan TÜM verileri paketler.

@ProviderFor(eventSeating)
const eventSeatingProvider = EventSeatingFamily._();

/// 🚀 SELECTION & AUDIT İÇİN COMPOSITE PROVIDER
/// Bir etkinliğin ihtiyacı olan TÜM verileri paketler.

final class EventSeatingProvider extends $FunctionalProvider<
        AsyncValue<EventSeatingState>,
        EventSeatingState,
        FutureOr<EventSeatingState>>
    with
        $FutureModifier<EventSeatingState>,
        $FutureProvider<EventSeatingState> {
  /// 🚀 SELECTION & AUDIT İÇİN COMPOSITE PROVIDER
  /// Bir etkinliğin ihtiyacı olan TÜM verileri paketler.
  const EventSeatingProvider._(
      {required EventSeatingFamily super.from,
      required ({
        String eventId,
        String showId,
      })
          super.argument})
      : super(
          retry: null,
          name: r'eventSeatingProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$eventSeatingHash();

  @override
  String toString() {
    return r'eventSeatingProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<EventSeatingState> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<EventSeatingState> create(Ref ref) {
    final argument = this.argument as ({
      String eventId,
      String showId,
    });
    return eventSeating(
      ref,
      eventId: argument.eventId,
      showId: argument.showId,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EventSeatingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventSeatingHash() => r'fc767f84969c447346e3be703d12482ca30cda05';

/// 🚀 SELECTION & AUDIT İÇİN COMPOSITE PROVIDER
/// Bir etkinliğin ihtiyacı olan TÜM verileri paketler.

final class EventSeatingFamily extends $Family
    with
        $FunctionalFamilyOverride<
            FutureOr<EventSeatingState>,
            ({
              String eventId,
              String showId,
            })> {
  const EventSeatingFamily._()
      : super(
          retry: null,
          name: r'eventSeatingProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// 🚀 SELECTION & AUDIT İÇİN COMPOSITE PROVIDER
  /// Bir etkinliğin ihtiyacı olan TÜM verileri paketler.

  EventSeatingProvider call({
    required String eventId,
    required String showId,
  }) =>
      EventSeatingProvider._(argument: (
        eventId: eventId,
        showId: showId,
      ), from: this);

  @override
  String toString() => r'eventSeatingProvider';
}
