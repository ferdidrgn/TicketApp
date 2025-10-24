import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/useCase/ticket/create_ticket_use_case_impl.dart';
import '../../../domain/useCase/ticket/get_ticket_by_id_use_case.dart';
import '../../repository/ticket/ticket_repository_provider.dart';
import 'ticket_notifier.dart';
import 'ticket_state.dart';

final ticketProvider =
    NotifierProvider.autoDispose<TicketNotifier, TicketState>(TicketNotifier.new);

// Use case providers
final getTicketByIdUseCaseProvider = Provider<GetTicketsByIdsUseCase>(
  (final ref) => GetTicketByIdUseCaseImpl(ref.watch(ticketRepositoryProvider)),
);

final createTicketUseCaseProvider = Provider<CreateTicketUseCase>(
  (final ref) => CreateTicketUseCaseImpl(ref.watch(ticketRepositoryProvider)),
);
