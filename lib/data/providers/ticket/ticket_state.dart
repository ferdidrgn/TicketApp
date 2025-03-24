import 'package:ticketapp/core/common/base_state.dart';
import 'package:ticketapp/data/model/ticket_model.dart';

class TicketState extends BaseState {
  final List<TicketModel?>? tickets;

  TicketState({
    this.tickets,
    super.isLoading = false,
    super.errorMessage,
  });

  @override
  TicketState copyWith({
    final List<TicketModel?>? tickets,
    final bool? isLoading,
    final String? errorMessage,
  }) {
    return TicketState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
