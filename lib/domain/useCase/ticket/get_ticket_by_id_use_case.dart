import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../entities/ticket.dart';
import '../../repository/ticket_repository.dart';

abstract class GetTicketsByIdsUseCase {
  Future<Either<Failure, List<Ticket>>> call(final List<String> ticketsIds);
}

class GetTicketByIdUseCaseImpl implements GetTicketsByIdsUseCase {
  final TicketRepository repository;

  GetTicketByIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Ticket>>> call(
      final List<String> ticketsIds) async {
    final result = await repository.getTicketsByIds(ticketsIds);
    return result.fold(
      (final failure) => Left(failure),
      (final ticketsModels) {
        final tickets = ticketsModels
                ?.map((final ticketModel) => ticketModel?.toEntity())
                .whereType<Ticket>()
                .toList() ??
            [];
        return Right(tickets);
      },
    );
  }
}
