import 'package:ticketapp/features/events/domain/entities/event.dart';
import 'package:ticketapp/features/shows/domain/entities/show.dart';
import 'package:ticketapp/features/stages/domain/entities/stage.dart';
import 'package:ticketapp/features/tickets/domain/entities/ticket.dart';
import '../../../../core/util/date_formatter.dart';
import 'ticket_state.dart';

/// PRESENTATION LAYER - Sadece UI için optimize edilmiş

/// UI Model - Presentation katmanına özel
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

/// Notifier'dan bağımsız, sadece state'i alıp UI'ya uygun formata çevirir
class TicketViewModel {
  final TicketState _state;

  TicketViewModel(this._state);

  // ============================================================
  // UI STATE PROPERTIES
  // ============================================================
  bool get isLoading => _state.isLoading;

  bool get hasError => _state.hasError;

  String? get errorMessage => _state.errorMessage;

  bool get isEmpty => _state.isEmpty;

  bool get isSuccess => _state.isSuccess;

  // ============================================================
  // DATA ACCESSORS
  // ============================================================
  List<Ticket> get tickets => _state.dataList ?? const [];

  List<Show> get shows => _state.relatedShows ?? const [];

  List<Event> get events => _state.relatedEvents ?? const [];

  List<Stage> get stages => _state.relatedStages ?? const [];

  Map<String, Show> get showMap => _state.showMap;

  Map<String, Event> get eventMap => _state.eventMap;

  Map<String, Stage> get stageMap => _state.stageMap;

  // ============================================================
  // BUSINESS LOGIC FOR UI
  // ============================================================
  List<DetailedTicket> get detailedTickets {
    if (tickets.isEmpty) return const [];

    final now = DateTime.now();
    return tickets.map((final ticket) {
      final event = eventMap[ticket.eventId];
      final isPast = _isEventPast(event, now);

      return DetailedTicket(
        ticket: ticket,
        show: showMap[ticket.showId],
        event: event,
        stage: stageMap[ticket.stageId],
        isPast: isPast,
      );
    }).toList();
  }

  // Etkinliğin geçmiş olup olmadığını kontrol eden metod
  bool _isEventPast(final Event? event, final DateTime now) {
    if (event?.date == null) return false;

    final eventDate = DateFormatter.parseDateString(event!.date);
    if (eventDate == null) return false;

    // Etkinlik tarihi şu anki tarihten önceyse geçmiş say
    return eventDate.isBefore(now);
  }

  List<DetailedTicket> get upcomingTickets =>
      detailedTickets.where((final ticket) => !ticket.isPast).toList();

  List<DetailedTicket> get pastTickets =>
      detailedTickets.where((final ticket) => ticket.isPast).toList();

  DetailedTicket? getTicketById(final String ticketId) {
    try {
      final ticket = tickets.firstWhere((final t) => t.id == ticketId);
      final event = eventMap[ticket.eventId];
      final isPast = _isEventPast(event, DateTime.now());

      return DetailedTicket(
        ticket: ticket,
        show: showMap[ticket.showId],
        event: event,
        stage: stageMap[ticket.stageId],
        isPast: isPast,
      );
    } catch (e) {
      return null;
    }
  }

  // TicketViewModel'e debug metodu ekleyin
  void debugTicketDates() {
    final now = DateTime.now();
    print('=== TICKET DATE DEBUG ===');
    print('Current time: $now');

    for (final ticket in tickets) {
      final event = eventMap[ticket.eventId];
      final eventDate = event?.date != null
          ? DateFormatter.parseDateString(event!.date)
          : null;
      final isPast = _isEventPast(event, now);

      print('Ticket: ${ticket.id}');
      print('Event Date: ${event?.date}');
      print('Parsed Date: $eventDate');
      print('Is Past: $isPast');
      print('---');
    }
  }
}
