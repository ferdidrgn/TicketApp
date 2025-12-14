import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticketapp/features/tickets/domain/usecases/get_tickets_by_customer_id_use_case.dart';
import 'package:ticketapp/features/tickets/presentation/providers/ticket_state.dart';
import '../../data/repositories/ticket_repository_provider.dart';
import '../../domain/usecases/create_ticket_use_case_impl.dart';
import '../../domain/usecases/get_ticket_by_id_use_case.dart';
import '../pages/my_ticket_viewmodel.dart';
import 'ticket_notifier.dart';

final ticketProvider =
    NotifierProvider.autoDispose<TicketNotifier, TicketState>(
        TicketNotifier.new);

final ticketViewModelProvider = Provider<TicketViewModel>((final ref) {
  final state = ref.watch(ticketProvider);
  return TicketViewModel(state);
});

// Use case providers
final getTicketByIdUseCaseProvider = Provider<GetTicketsByIdUseCase>(
    (final ref) =>
        GetTicketsByIdUseCaseImpl(ref.watch(ticketRepositoryProvider)));

final getTicketByCustomerIdUseCaseProvider =
    Provider<GetTicketsByCustomerIdUseCase>((final ref) =>
        GetTicketByCustomerIdUseCaseImpl(ref.watch(ticketRepositoryProvider)));

final createTicketUseCaseProvider = Provider<CreateTicketUseCase>((final ref) =>
    CreateTicketUseCaseImpl(ref.watch(ticketRepositoryProvider)));
