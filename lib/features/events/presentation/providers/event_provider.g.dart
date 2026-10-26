// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(getEventsByIdsUseCase)
const getEventsByIdsUseCaseProvider = GetEventsByIdsUseCaseProvider._();

final class GetEventsByIdsUseCaseProvider extends $FunctionalProvider<
    GetEventsByIdsUseCase,
    GetEventsByIdsUseCase,
    GetEventsByIdsUseCase> with $Provider<GetEventsByIdsUseCase> {
  const GetEventsByIdsUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getEventsByIdsUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getEventsByIdsUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetEventsByIdsUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetEventsByIdsUseCase create(Ref ref) {
    return getEventsByIdsUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetEventsByIdsUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GetEventsByIdsUseCase>(value),
    );
  }
}

String _$getEventsByIdsUseCaseHash() =>
    r'c352e5de6f3f1b39c4cf9b7df12bcc95be349ddd';

@ProviderFor(getEventSeatStatusStreamUseCase)
const getEventSeatStatusStreamUseCaseProvider =
    GetEventSeatStatusStreamUseCaseProvider._();

final class GetEventSeatStatusStreamUseCaseProvider extends $FunctionalProvider<
        GetEventSeatStatusStreamUseCase,
        GetEventSeatStatusStreamUseCase,
        GetEventSeatStatusStreamUseCase>
    with $Provider<GetEventSeatStatusStreamUseCase> {
  const GetEventSeatStatusStreamUseCaseProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'getEventSeatStatusStreamUseCaseProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$getEventSeatStatusStreamUseCaseHash();

  @$internal
  @override
  $ProviderElement<GetEventSeatStatusStreamUseCase> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GetEventSeatStatusStreamUseCase create(Ref ref) {
    return getEventSeatStatusStreamUseCase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GetEventSeatStatusStreamUseCase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<GetEventSeatStatusStreamUseCase>(value),
    );
  }
}

String _$getEventSeatStatusStreamUseCaseHash() =>
    r'51c40e81e283a62f5337ad8f6d48f9cac94ef25b';

/// 🎯 KOLTUK DURUMU (Real-time Stream)
/// HATA ÇÖZÜMÜ: .cast() kullanarak nullable Map'i istenen tipe zorluyoruz.
/// 🎯 ID LİSTESİNE GÖRE ETKİNLİKLERİ ÇEKER
/// MyTicketProvider'ın beklediği provider budur.

@ProviderFor(eventsByIds)
const eventsByIdsProvider = EventsByIdsFamily._();

/// 🎯 KOLTUK DURUMU (Real-time Stream)
/// HATA ÇÖZÜMÜ: .cast() kullanarak nullable Map'i istenen tipe zorluyoruz.
/// 🎯 ID LİSTESİNE GÖRE ETKİNLİKLERİ ÇEKER
/// MyTicketProvider'ın beklediği provider budur.

final class EventsByIdsProvider extends $FunctionalProvider<
        AsyncValue<List<Event>>, List<Event>, FutureOr<List<Event>>>
    with $FutureModifier<List<Event>>, $FutureProvider<List<Event>> {
  /// 🎯 KOLTUK DURUMU (Real-time Stream)
  /// HATA ÇÖZÜMÜ: .cast() kullanarak nullable Map'i istenen tipe zorluyoruz.
  /// 🎯 ID LİSTESİNE GÖRE ETKİNLİKLERİ ÇEKER
  /// MyTicketProvider'ın beklediği provider budur.
  const EventsByIdsProvider._(
      {required EventsByIdsFamily super.from,
      required List<String> super.argument})
      : super(
          retry: null,
          name: r'eventsByIdsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$eventsByIdsHash();

  @override
  String toString() {
    return r'eventsByIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Event>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Event>> create(Ref ref) {
    final argument = this.argument as List<String>;
    return eventsByIds(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EventsByIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventsByIdsHash() => r'd1e56dfdd08fd7c2ac2c4a65ffbe483242eaed19';

/// 🎯 KOLTUK DURUMU (Real-time Stream)
/// HATA ÇÖZÜMÜ: .cast() kullanarak nullable Map'i istenen tipe zorluyoruz.
/// 🎯 ID LİSTESİNE GÖRE ETKİNLİKLERİ ÇEKER
/// MyTicketProvider'ın beklediği provider budur.

final class EventsByIdsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Event>>, List<String>> {
  const EventsByIdsFamily._()
      : super(
          retry: null,
          name: r'eventsByIdsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// 🎯 KOLTUK DURUMU (Real-time Stream)
  /// HATA ÇÖZÜMÜ: .cast() kullanarak nullable Map'i istenen tipe zorluyoruz.
  /// 🎯 ID LİSTESİNE GÖRE ETKİNLİKLERİ ÇEKER
  /// MyTicketProvider'ın beklediği provider budur.

  EventsByIdsProvider call(
    List<String> ids,
  ) =>
      EventsByIdsProvider._(argument: ids, from: this);

  @override
  String toString() => r'eventsByIdsProvider';
}

/// 🎯 KOLTUK DURUMU (Real-time Stream)
/// HATA ÇÖZÜMÜ: .map ve .cast ile nullable Map uyuşmazlığını gideriyoruz.

@ProviderFor(eventSeats)
const eventSeatsProvider = EventSeatsFamily._();

/// 🎯 KOLTUK DURUMU (Real-time Stream)
/// HATA ÇÖZÜMÜ: .map ve .cast ile nullable Map uyuşmazlığını gideriyoruz.

final class EventSeatsProvider extends $FunctionalProvider<
        AsyncValue<Map<String, Map<String, dynamic>>>,
        Map<String, Map<String, dynamic>>,
        Stream<Map<String, Map<String, dynamic>>>>
    with
        $FutureModifier<Map<String, Map<String, dynamic>>>,
        $StreamProvider<Map<String, Map<String, dynamic>>> {
  /// 🎯 KOLTUK DURUMU (Real-time Stream)
  /// HATA ÇÖZÜMÜ: .map ve .cast ile nullable Map uyuşmazlığını gideriyoruz.
  const EventSeatsProvider._(
      {required EventSeatsFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'eventSeatsProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$eventSeatsHash();

  @override
  String toString() {
    return r'eventSeatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, Map<String, dynamic>>> $createElement(
          $ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Map<String, Map<String, dynamic>>> create(Ref ref) {
    final argument = this.argument as String;
    return eventSeats(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EventSeatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventSeatsHash() => r'a73a9b613e4bc88b02c1b4f472487d13097d334d';

/// 🎯 KOLTUK DURUMU (Real-time Stream)
/// HATA ÇÖZÜMÜ: .map ve .cast ile nullable Map uyuşmazlığını gideriyoruz.

final class EventSeatsFamily extends $Family
    with
        $FunctionalFamilyOverride<Stream<Map<String, Map<String, dynamic>>>,
            String> {
  const EventSeatsFamily._()
      : super(
          retry: null,
          name: r'eventSeatsProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// 🎯 KOLTUK DURUMU (Real-time Stream)
  /// HATA ÇÖZÜMÜ: .map ve .cast ile nullable Map uyuşmazlığını gideriyoruz.

  EventSeatsProvider call(
    String eventId,
  ) =>
      EventSeatsProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventSeatsProvider';
}

/// 🎯 ETKİNLİK DETAYI

@ProviderFor(eventDetail)
const eventDetailProvider = EventDetailFamily._();

/// 🎯 ETKİNLİK DETAYI

final class EventDetailProvider
    extends $FunctionalProvider<AsyncValue<Event>, Event, FutureOr<Event>>
    with $FutureModifier<Event>, $FutureProvider<Event> {
  /// 🎯 ETKİNLİK DETAYI
  const EventDetailProvider._(
      {required EventDetailFamily super.from, required String super.argument})
      : super(
          retry: null,
          name: r'eventDetailProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$eventDetailHash();

  @override
  String toString() {
    return r'eventDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Event> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Event> create(Ref ref) {
    final argument = this.argument as String;
    return eventDetail(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is EventDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$eventDetailHash() => r'53b611a3e0e9b20bbd7c80d359cd9075c8d1a376';

/// 🎯 ETKİNLİK DETAYI

final class EventDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Event>, String> {
  const EventDetailFamily._()
      : super(
          retry: null,
          name: r'eventDetailProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// 🎯 ETKİNLİK DETAYI

  EventDetailProvider call(
    String eventId,
  ) =>
      EventDetailProvider._(argument: eventId, from: this);

  @override
  String toString() => r'eventDetailProvider';
}
