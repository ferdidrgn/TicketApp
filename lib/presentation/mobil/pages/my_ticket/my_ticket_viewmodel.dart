import 'package:ticketapp/data/providers/ticket/ticket_state.dart';
import 'package:ticketapp/domain/entities/event.dart';
import 'package:ticketapp/domain/entities/show.dart';
import 'package:ticketapp/domain/entities/stage.dart';
import 'package:ticketapp/domain/entities/ticket.dart';

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
      final eventDate =
          event?.date != null ? DateTime.tryParse(event!.date) : null;
      final isPast = eventDate?.isBefore(now) ?? false;

      return DetailedTicket(
        ticket: ticket,
        show: showMap[ticket.showId],
        event: event,
        stage: stageMap[ticket.stageId],
        isPast: isPast,
      );
    }).toList();
  }

  List<DetailedTicket> get upcomingTickets =>
      detailedTickets.where((final ticket) => !ticket.isPast).toList();

  List<DetailedTicket> get pastTickets =>
      detailedTickets.where((final ticket) => ticket.isPast).toList();

  DetailedTicket? getTicketById(final String ticketId) {
    try {
      final ticket = tickets.firstWhere((final t) => t.id == ticketId);
      final event = eventMap[ticket.eventId];
      final eventDate =
          event?.date != null ? DateTime.tryParse(event!.date) : null;
      final isPast = eventDate?.isBefore(DateTime.now()) ?? false;

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
}
