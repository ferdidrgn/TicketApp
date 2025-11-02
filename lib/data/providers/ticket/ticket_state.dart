import '../../../core/common/base_loadable_state.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/show.dart';
import '../../../domain/entities/stage.dart';
import '../../../domain/entities/ticket.dart';

class TicketState extends LoadableState<Ticket, List<Ticket>> {
  /// Biletlerle ilişkili Gösteri (Show) verilerini tutar.
  final List<Show>? relatedShows;

  /// Biletlerle ilişkili Etkinlik (Event) verilerini tutar.
  final List<Event>? relatedEvents;

  /// Biletlerle ilişkili Sahne (Stage) verilerini tutar.
  final List<Stage>? relatedStages;

  const TicketState({
    super.dataList, // Bilet listesi
    super.dataSingle,
    super.isLoading = false,
    super.errorMessage,
    this.relatedShows,
    this.relatedEvents,
    this.relatedStages,
  });

  @override
  TicketState copyWith({
    final Ticket? dataSingle,
    final List<Ticket>? dataList,
    final bool? isLoading,
    final String? errorMessage,
    final List<Show>? relatedShows,
    final List<Event>? relatedEvents,
    final List<Stage>? relatedStages,
  }) =>
      TicketState(
        dataSingle: dataSingle ?? this.dataSingle,
        dataList: dataList ?? this.dataList,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
        relatedShows: relatedShows ?? this.relatedShows,
        relatedEvents: relatedEvents ?? this.relatedEvents,
        relatedStages: relatedStages ?? this.relatedStages,
      );
}
