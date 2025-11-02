import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import 'package:ticketapp/data/providers/event/event_provider.dart';
import 'package:ticketapp/data/providers/show/show_provider.dart';
import 'package:ticketapp/data/providers/stage/stage_provider.dart';
import 'package:ticketapp/domain/entities/event.dart';
import 'package:ticketapp/domain/entities/show.dart';
import 'package:ticketapp/domain/entities/stage.dart';
import 'package:ticketapp/domain/entities/ticket.dart';
import 'ticket_provider.dart';
import 'ticket_state.dart';

/// Bilet, Gösteri, Etkinlik ve Sahne verilerini birleştiren bir yardımcı sınıf.
/// UI katmanı için optimize edilmiş bir ViewModel görevi görür.
class DetailedTicket {
  final Ticket ticket;
  final Show? show;
  final Event? event;
  final Stage? stage;
  final bool isPast;

  const DetailedTicket({
    required this.ticket,
    this.show,
    this.event,
    this.stage,
    required this.isPast,
  });

  /// Factory constructor ile hızlı oluşturma
  factory DetailedTicket.fromTicket(
    final Ticket ticket, {
    final Show? show,
    final Event? event,
    final Stage? stage,
    required final bool isPast,
  }) =>
      DetailedTicket(
        ticket: ticket,
        show: show,
        event: event,
        stage: stage,
        isPast: isPast,
      );

  /// CopyWith metodu - immutable güncellemeler için
  DetailedTicket copyWith({
    final Ticket? ticket,
    final Show? show,
    final Event? event,
    final Stage? stage,
    final bool? isPast,
  }) =>
      DetailedTicket(
        ticket: ticket ?? this.ticket,
        show: show ?? this.show,
        event: event ?? this.event,
        stage: stage ?? this.stage,
        isPast: isPast ?? this.isPast,
      );
}

/// Ticket state yönetimi için optimize edilmiş notifier.
///
/// PERFORMANS İYİLEŞTİRMELERİ:
/// - Paralel veri yükleme (Future.wait)
/// - Gereksiz state güncellemelerini önleme
/// - Efficient error handling
/// - Memory-efficient data structures
class TicketNotifier extends BaseNotifierWithNetworkChecker<TicketState> {
  /// Concurrent request limiter
  String? _lastLoadedCustomerId;
  DateTime? _lastRequestTime;

  @override
  TicketState initialState() => const TicketState();

  @override
  void reloadData() {
    if (_lastLoadedCustomerId != null && _lastLoadedCustomerId!.isNotEmpty)
      loadTicketsAndDetailsByCustomerId(_lastLoadedCustomerId!);
  }

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
    final String customerId,
  ) async {
    // Validation
    if (customerId.isEmpty || customerId == '0') {
      _clearState();
      return;
    }

    // Debouncing - Aynı customer için çok sık istek yapılmasını önle
    if (_isRecentlyLoaded(customerId)) return;

    _lastLoadedCustomerId = customerId;

    await executeWithInternetCheck(
        () => ref.read(getTicketByCustomerIdUseCaseProvider).call(customerId),
        onSuccess: (final tickets) => _handleTicketsLoaded(tickets));
  }

  /// Biletler yüklendikten sonra detayları getirir
  Future<void> _handleTicketsLoaded(final List<Ticket> tickets) async {
    // Boş liste kontrolü
    if (tickets.isEmpty) {
      _clearState();
      return;
    }

    // Biletleri state'e yaz (loading indicator için)
    state =
        state.copyWith(dataList: tickets, errorMessage: null, isLoading: true);

    try {
      // ID'leri topla ve unique yap (Set kullanarak O(1) lookup)
      final entityIds = _extractEntityIds(tickets);

      // Paralel yükleme - Tüm detayları aynı anda getir
      final relatedData = await _loadRelatedData(entityIds);

      // Final state güncellemesi
      state = state.copyWith(
        relatedShows: relatedData.shows,
        relatedEvents: relatedData.events,
        relatedStages: relatedData.stages,
        isLoading: false,
        errorMessage: null,
      );
    } catch (e) {
      setErrorState("Bilet detayları yüklenirken hata oluştu: $e");
    }
  }

  /// Entity ID'lerini toplar ve temizler
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
        stageIds: stageIds.toList());
  }

  /// İlgili tüm verileri paralel olarak yükler
  ///
  /// PERFORMANS: Future.wait ile paralel yükleme
  /// Network latency'i minimize eder
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

  /// Show'ları yükler
  Future<List<Show>> _loadShows(final List<String> ids) async {
    if (ids.isEmpty) return [];

    final result = await ref.read(getShowsByIdsUseCaseProvider).call(ids);
    return result.fold(
      (final failure) {
        debugPrint('Show yükleme hatası: $failure');
        return <Show>[];
      },
      (final shows) => shows,
    );
  }

  /// Event'leri yükler
  Future<List<Event>> _loadEvents(final List<String> ids) async {
    if (ids.isEmpty) return [];

    final result = await ref.read(getEventsByIdsUseCaseProvider).call(ids);
    return result.fold(
      (final failure) {
        debugPrint('Event yükleme hatası: $failure');
        return <Event>[];
      },
      (final events) => events,
    );
  }

  /// Stage'leri yükler
  Future<List<Stage>> _loadStages(final List<String> ids) async {
    if (ids.isEmpty) return [];

    final result = await ref.read(getStageByIdUseCaseProvider).call(ids);
    return result.fold(
      (final failure) {
        debugPrint('Stage yükleme hatası: $failure');
        return <Stage>[];
      },
      (final stages) => stages,
    );
  }

  /// State'i temizler
  void _clearState() {
    state = state.copyWith(
      dataList: [],
      relatedShows: [],
      relatedEvents: [],
      relatedStages: [],
      isLoading: false,
      errorMessage: null,
    );
  }

  /// Son 500ms içinde aynı customer için istek yapıldı mı?
  bool _isRecentlyLoaded(final String customerId) {
    if (_lastLoadedCustomerId != customerId) {
      _lastLoadedCustomerId = customerId;
      _lastRequestTime = DateTime.now();
      return false;
    }

    // Son istek 500ms içinde mi?
    if (_lastRequestTime != null) {
      final timeSinceLastRequest = DateTime.now().difference(_lastRequestTime!);
      if (timeSinceLastRequest.inMilliseconds < 500) return true;
    }

    _lastRequestTime = DateTime.now();
    return false;
  }

  /// Yeni bilet oluşturur
  ///
  /// Optimistic update pattern - önce UI'ı güncelle, sonra backend'e gönder
  Future<void> createTicket(final Ticket ticket) async {
    // Optimistic update
    final currentTickets = state.dataList ?? [];
    state = state.copyWith(dataList: [...currentTickets, ticket]);

    await executeWithInternetCheck(
      () => ref.read(createTicketUseCaseProvider).call(ticket),
      onSuccess: (final _) {},
    );
  }

  /// Deprecated - Geriye dönük uyumluluk için tutuldu
  @Deprecated('Use loadTicketsAndDetailsByCustomerId instead')
  Future<void> loadTicketsAndDetails(final List<String> ticketIds) async {
    if (ticketIds.isEmpty) {
      _clearState();
      return;
    }

    await executeWithInternetCheck(
      () => ref.read(getTicketByIdUseCaseProvider).call(ticketIds),
      onSuccess: (final tickets) {
        if (tickets.isNotEmpty)
          loadTicketsAndDetailsByCustomerId(tickets.first.customerId);
        else
          _clearState();
      },
    );
  }
}

// ============================================================
// HELPER CLASSES - Internal use only

/// ID koleksiyonları için helper class
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

/// İlgili veri koleksiyonları için helper class
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
