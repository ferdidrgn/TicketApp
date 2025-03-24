import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../data/model/ticket_model.dart';
import '../../repository/ticket_repository.dart';

abstract class GetTicketsByIdsUseCase {
  Future<Either<Failure, List<TicketModel?>?>> call(final List<String> ticketsIds);
}

class GetTicketByIdUseCaseImpl implements GetTicketsByIdsUseCase {
  final TicketRepository repository;

  GetTicketByIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<TicketModel?>?>> call(final List<String> ticketsIds) async {
    return repository.getTicketsByIds(ticketsIds);
  }
}
