import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import 'package:ticketapp/data/providers/ticket/ticket_provider.dart';
import '../../../domain/entities/ticket.dart';
import '../../model/ticket_model.dart';
import 'ticket_state.dart';

class TicketNotifier extends BaseNotifierWithNetworkChecker<TicketState> {
  @override
  TicketState initialState() => const TicketState();

  @override
  void reloadData() {
    // Örneğin son yüklenen biletlerin ID'leri varsa yeniden yükleyebilirsin.
    // Veya boş bırakıp implementasyonu sonraya bırakabilirsin.
  }

  Future<void> loadTicketsByIds(final List<String> ticketsIds) =>
      executeWithInternetCheck(
        () => ref.read(getTicketByIdUseCaseProvider).call(ticketsIds),
        onSuccess: (final tickets) =>
            state = state.copyWith(dataList: tickets, errorMessage: null),
      );

  Future<void> createTicket(final Ticket ticket) => executeWithInternetCheck(
        () => ref.read(createTicketUseCaseProvider).call(ticket),
        onSuccess: (final bool) =>
            state = state.copyWith(isLoading: false, errorMessage: null),
      );
}
