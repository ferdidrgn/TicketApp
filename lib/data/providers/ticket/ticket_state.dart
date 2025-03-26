import 'package:ticketapp/core/common/base_state.dart';
import '../../../domain/entities/ticket.dart';

class TicketState extends BaseState {
  List<Ticket>? tickets;

  TicketState({
    this.tickets,
    super.isLoading = false,
    super.errorMessage,
  });

  @override
  TicketState copyWith({
    List<Ticket>? tickets,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TicketState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
