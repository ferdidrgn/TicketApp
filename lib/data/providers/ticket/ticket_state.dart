import '../../../core/common/base_loadable_state.dart';
import '../../../domain/entities/ticket.dart';

class TicketState extends LoadableState<Ticket, List<Ticket>> {
  const TicketState({
    final Ticket? ticket,
    final List<Ticket>? tickets,
    super.isLoading = false,
    super.errorMessage,
  }) : super(dataSingle: ticket, dataList: tickets);

  @override
  TicketState copyWith({
    final Ticket? dataSingle,
    final List<Ticket>? dataList,
    final bool? isLoading,
    final String? errorMessage,
  }) {
    return TicketState(
      ticket: dataSingle ?? this.dataSingle,
      tickets: dataList ?? this.dataList,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
