import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../entities/ticket.dart';
import '../../repository/ticket_repository.dart';

abstract class GetTicketsByCustomerIdUseCase {
  Future<Either<Failure, List<Ticket>>> call(final String ticketsIds);
}

class GetTicketByCustomerIdUseCaseImpl
    implements GetTicketsByCustomerIdUseCase {
  final TicketRepository repository;

  GetTicketByCustomerIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Ticket>>> call(final String ticketsIds) async {
    final result = await repository.getTicketsByCustomerId(ticketsIds);
    return result.fold(
        (final failure) => Left(failure),
        (final ticketsModels) => Right(ticketsModels
                ?.map((final ticketModel) => ticketModel?.toEntity())
                .whereType<Ticket>()
                .toList() ??
            []));
  }
}
