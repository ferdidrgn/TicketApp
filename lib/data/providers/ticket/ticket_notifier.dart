import 'package:ticketapp/core/common/base_notifier.dart';
import 'package:ticketapp/data/providers/event/event_provider.dart';
import 'package:ticketapp/data/providers/show/show_provider.dart';
import 'package:ticketapp/data/providers/stage/stage_provider.dart';
import 'package:ticketapp/domain/entities/event.dart';
import 'package:ticketapp/domain/entities/show.dart';
import 'package:ticketapp/domain/entities/stage.dart';
import 'package:ticketapp/domain/entities/ticket.dart';
import 'ticket_provider.dart';
import 'ticket_state.dart';

/// Ticket state yönetimi için optimize edilmiş notifier.
///
/// PERFORMANS İYİLEŞTİRMELERİ:
/// - Paralel veri yükleme (Future.wait)
/// - Gereksiz state güncellemelerini önleme
/// - Efficient error handling
/// - Memory-efficient data structures
class TicketNotifier extends BaseNotifier<TicketState> {
  String? _lastLoadedCustomerId;
  DateTime? _lastRequestTime;

  @override
  TicketState initialState() => const TicketState();

  /// Ana yükleme metodu - Müşteri ID'sine göre tüm bilet ve detayları getirir.
  ///
  /// WORKFLOW:
  /// 1. Biletleri customerId ile yükle
  /// 2. İlgili show, event, stage ID'lerini topla
  /// 3. Tüm detayları paralel olarak yükle
  /// 4. State'i güncelle
  ///
  /// [customerId] - Müşterinin benzersiz ID'si
  Future<void> loadTicketsAndDetailsByCustomerId(
      final String customerId) async {
    if (customerId.isEmpty) {
      _clearState();
      return;
    }

    if (_isRecentlyLoaded(customerId)) return;
    _lastLoadedCustomerId = customerId;

    await execute(
      () => ref.read(getTicketByCustomerIdUseCaseProvider).call(customerId),
      onSuccess: (final tickets) => _handleTicketsLoaded(tickets),
    );
  }

  Future<void> _handleTicketsLoaded(final List<Ticket> tickets) async {
    if (tickets.isEmpty) {
      _clearState();
      return;
    }

    state = state.copyWith(dataList: tickets, isLoading: true);

    try {
      final entityIds = _extractEntityIds(tickets);
      final relatedData = await _loadRelatedData(entityIds);

      state = state.copyWith(
        relatedShows: relatedData.shows,
        relatedEvents: relatedData.events,
        relatedStages: relatedData.stages,
        isLoading: false,
      );
    } catch (e) {
      setErrorState("Bilet detayları yüklenirken hata oluştu: $e");
    }
  }

  _EntityIds _extractEntityIds(final List<Ticket> tickets) {
    final showIds = <String>{};
    final eventIds = <String>{};
    final stageIds = <String>{};

    for (final ticket in tickets) {
      if (ticket.showId.isNotEmpty) showIds.add(ticket.showId);
      if (ticket.eventId.isNotEmpty) eventIds.add(ticket.eventId);
      if (ticket.stageId.isNotEmpty) stageIds.add(ticket.stageId);
    }

    return _EntityIds(
      showIds: showIds.toList(),
      eventIds: eventIds.toList(),
      stageIds: stageIds.toList(),
    );
  }

  Future<_RelatedData> _loadRelatedData(final _EntityIds ids) async {
    final results = await Future.wait([
      _loadShows(ids.showIds),
      _loadEvents(ids.eventIds),
      _loadStages(ids.stageIds),
    ]);

    return _RelatedData(
      shows: results[0] as List<Show>,
      events: results[1] as List<Event>,
      stages: results[2] as List<Stage>,
    );
  }

  Future<List<Show>> _loadShows(final List<String> ids) async {
    if (ids.isEmpty) return [];
    final result = await ref.read(getShowsByIdsUseCaseProvider).call(ids);
    return result.fold((final failure) => <Show>[], (final shows) => shows);
  }

  Future<List<Event>> _loadEvents(final List<String> ids) async {
    if (ids.isEmpty) return [];
    final result = await ref.read(getEventsByIdsUseCaseProvider).call(ids);
    return result.fold((final failure) => <Event>[], (final events) => events);
  }

  Future<List<Stage>> _loadStages(final List<String> ids) async {
    if (ids.isEmpty) return [];
    final result = await ref.read(getStageByIdUseCaseProvider).call(ids);
    return result.fold((final failure) => <Stage>[], (final stages) => stages);
  }

  void _clearState() {
    state = const TicketState();
  }

  bool _isRecentlyLoaded(final String customerId) {
    if (_lastLoadedCustomerId != customerId) return false;
    if (_lastRequestTime == null) return false;

    final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
    return timeSinceLastRequest.inSeconds < 5; // 5 saniye
  }
}

class _EntityIds {
  final List<String> showIds;
  final List<String> eventIds;
  final List<String> stageIds;

  const _EntityIds({
    required this.showIds,
    required this.eventIds,
    required this.stageIds,
  });
}

class _RelatedData {
  final List<Show> shows;
  final List<Event> events;
  final List<Stage> stages;

  const _RelatedData({
    required this.shows,
    required this.events,
    required this.stages,
  });
}

/// Debug print helper - Production'da otomatik disable olur
void debugPrint(final String message) {
  assert(() {
    print('[TicketNotifier] $message');
    return true;
  }());
}
