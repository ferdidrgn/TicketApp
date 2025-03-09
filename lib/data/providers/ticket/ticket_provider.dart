import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/useCase/ticket/create_ticket_use_case_impl.dart';
import '../../../domain/useCase/ticket/get_ticket_by_id_use_case.dart';
import '../../repository/ticket/ticket_repository_provider.dart';
import 'ticket_notifier.dart';
import 'ticket_state.dart';

final ticketProvider = StateNotifierProvider<TicketNotifier, TicketState>((final ref) {
  return TicketNotifier(
    ref.watch(getTicketByIdUseCaseProvider),
    ref.watch(createTicketUseCaseProvider),
  );
});

// Use case providers
final getTicketByIdUseCaseProvider = Provider<GetTicketByIdUseCase>((final ref) {
  final repository = ref.watch(ticketRepositoryProvider);
  return GetTicketByIdUseCaseImpl(repository);
});

final createTicketUseCaseProvider = Provider<CreateTicketUseCase>((final ref) {
  final repository = ref.watch(ticketRepositoryProvider);
  return CreateTicketUseCaseImpl(repository);
});