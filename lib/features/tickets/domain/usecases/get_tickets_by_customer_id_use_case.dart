import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/ticket.dart';
import '../repositories/ticket_repository.dart';

abstract class GetTicketsByCustomerIdUseCase {
  Future<Either<Failure, List<Ticket>>> call(final String ticketsIds);
}

class GetTicketByCustomerIdUseCaseImpl
    implements GetTicketsByCustomerIdUseCase {
  final TicketRepository repository;

  GetTicketByCustomerIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Ticket>>> call(final String ticketsIds) async =>
      repository.getTicketsByCustomerId(ticketsIds);
}
