import 'package:ticketapp/data/model/ticket_model.dart';

class TicketState {
  final TicketModel? ticket;
  final bool isLoading;
  final String? errorMessage;

  TicketState({
    this.ticket,
    this.isLoading = false,
    this.errorMessage,
  });

  TicketState copyWith({
    final TicketModel? ticket,
    final bool? isLoading,
    final String? errorMessage,
  }) {
    return TicketState(
      ticket: ticket ?? this.ticket,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
