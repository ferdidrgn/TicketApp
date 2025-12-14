import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/ticket.dart';
import '../repositories/ticket_repository.dart';

abstract class GetTicketsByIdUseCase {
  Future<Either<Failure, List<Ticket>>> call(final List<String> ticketsIds);
}

class GetTicketsByIdUseCaseImpl implements GetTicketsByIdUseCase {
  final TicketRepository repository;

  GetTicketsByIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Ticket>>> call(
      final List<String> ticketsIds) async {
    final result = await repository.getTicketsByIds(ticketsIds);
    return result.fold(
        (final failure) => Left(failure),
        (final ticketsModels) => Right(ticketsModels
                ?.map((final ticketModel) => ticketModel?.toEntity())
                .whereType<Ticket>()
                .toList() ??
            []));
  }
}
