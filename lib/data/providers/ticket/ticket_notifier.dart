import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import '../../../core/network/internet_service.dart';
import '../../../domain/entities/ticket.dart';
import '../../../domain/useCase/ticket/create_ticket_use_case_impl.dart';
import '../../../domain/useCase/ticket/get_ticket_by_id_use_case.dart';
import '../../model/ticket_model.dart';
import 'ticket_state.dart';

class TicketNotifier extends BaseNotifierWithNetworkChecker<TicketState> {
  final GetTicketsByIdsUseCase _getTicketsByIdsUseCase;
  final CreateTicketUseCase _createTicketUseCase;

  TicketNotifier(
    final InternetService internetService,
    this._getTicketsByIdsUseCase,
    this._createTicketUseCase,
  ) : super(internetService, const TicketState());

  @override
  void reloadData() {
    // Örneğin son yüklenen biletlerin ID'leri varsa yeniden yükleyebilirsin.
    // Veya boş bırakıp implementasyonu sonraya bırakabilirsin.
  }

  Future<void> loadTicketsByIds(final List<String> ticketsIds) =>
      executeWithInternetCheck(
        () => _getTicketsByIdsUseCase.call(ticketsIds),
        onSuccess: (final tickets) =>
            state = state.copyWith(dataList: tickets, errorMessage: null),
      );

  Future<void> createTicket(final Ticket ticket) => executeWithInternetCheck(
        () => _createTicketUseCase.call(TicketModel.fromEntity(ticket)),
      );
}
