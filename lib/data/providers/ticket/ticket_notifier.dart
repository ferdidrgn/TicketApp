import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/ticket.dart';
import '../../../domain/useCase/ticket/create_ticket_use_case_impl.dart';
import '../../../domain/useCase/ticket/get_ticket_by_id_use_case.dart';
import '../../model/ticket_model.dart';
import 'ticket_state.dart';

class TicketNotifier extends StateNotifier<TicketState> {
  final GetTicketByIdUseCase getTicketByIdUseCase;
  final CreateTicketUseCase createTicketUseCase;

  TicketNotifier(this.getTicketByIdUseCase, this.createTicketUseCase)
      : super(TicketState());

  Future<void> loadTicketById(final String ticketId) async {
    _setLoadingState(true);
    final result = await getTicketByIdUseCase.call(ticketId);

    result.fold(
      (final failure) => _setErrorState(failure.message),
      (final ticket) => _setTicketState(ticket?.toEntity()),
    );
  }

  Future<void> createTicket(final Ticket ticket) async {
    _setLoadingState(true);
    final ticketModel = TicketModel.fromEntity(ticket);
    final result = await createTicketUseCase.call(ticketModel);

    result.fold(
      (final failure) => _setErrorState(failure.message),
      (final _) => _setSuccessState(),
    );
  }

  void _setLoadingState(final bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void _setErrorState(final String errorMessage) {
    state = state.copyWith(errorMessage: errorMessage, isLoading: false);
  }

  void _setTicketState(final Ticket? ticket) {
    state = state.copyWith(ticket: ticket, isLoading: false);
  }

  void _setSuccessState() {
    state = state.copyWith(isLoading: false);
  }
}
