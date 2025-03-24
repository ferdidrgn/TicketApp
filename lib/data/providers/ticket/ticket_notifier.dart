import 'package:ticketapp/core/common/base_notifier.dart';
import '../../../domain/entities/ticket.dart';
import '../../../domain/useCase/ticket/create_ticket_use_case_impl.dart';
import '../../../domain/useCase/ticket/get_ticket_by_id_use_case.dart';
import '../../model/ticket_model.dart';
import 'ticket_state.dart';

class TicketNotifier extends BaseNotifier<TicketState> {
  final GetTicketsByIdsUseCase getTicketsByIdsUseCase;
  final CreateTicketUseCase createTicketUseCase;

  TicketNotifier(this.getTicketsByIdsUseCase, this.createTicketUseCase)
      : super(TicketState());

  Future<void> loadTicketsByIds(final List<String> ticketsIds) async {
    await handleOperation(() => getTicketsByIdsUseCase.call(ticketsIds),
        onSuccess: (final tickets) => state = state.copyWith(tickets: tickets));
  }

  Future<void> createTicket(final Ticket ticket) async {
    await handleOperation(() =>
        createTicketUseCase.call(TicketModel.fromEntity(ticket)));
  }
}
