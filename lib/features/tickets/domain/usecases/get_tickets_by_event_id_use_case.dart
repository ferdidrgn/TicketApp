import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/ticket.dart';
import '../repositories/ticket_repository.dart';

abstract class GetTicketsByEventIdUseCase {
  Future<Either<Failure, List<Ticket>>> call(final String eventId);
}

class GetTicketsByEventIdUseCaseImpl implements GetTicketsByEventIdUseCase {
  final TicketRepository repository;

  GetTicketsByEventIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Ticket>>> call(final String eventId) async =>
      repository.getTicketsByEventId(eventId);
}
