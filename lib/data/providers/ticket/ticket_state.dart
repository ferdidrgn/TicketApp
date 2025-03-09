import '../../../domain/entities/ticket.dart';

class TicketState {
  final Ticket? ticket;
  final bool isLoading;
  final String? errorMessage;

  TicketState({
    this.ticket,
    this.isLoading = false,
    this.errorMessage,
  });

  TicketState copyWith({
    final Ticket? ticket,
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
