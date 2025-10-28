import '../../../core/common/base_loadable_state.dart';
import '../../../domain/entities/ticket.dart';

class TicketState extends LoadableState<Ticket, List<Ticket>> {
  const TicketState({
    super.dataList,
    super.dataSingle,
    super.isLoading = false,
    super.errorMessage,
  });

  @override
  TicketState copyWith({
    final Ticket? dataSingle,
    final List<Ticket>? dataList,
    final bool? isLoading,
    final String? errorMessage,
  }) =>
      TicketState(
        dataSingle: dataSingle ?? this.dataSingle,
        dataList: dataList ?? this.dataList,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}
