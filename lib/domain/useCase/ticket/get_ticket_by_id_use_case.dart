import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../data/model/ticket_model.dart';
import '../../repository/ticket_repository.dart';

abstract class GetTicketByIdUseCase {
  Future<Either<Failure, TicketModel?>> call(final String ticketId);
}

class GetTicketByIdUseCaseImpl implements GetTicketByIdUseCase {
  final TicketRepository repository;

  GetTicketByIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, TicketModel?>> call(final String ticketId) async {
    return repository.getTicketById(ticketId);
  }
}
