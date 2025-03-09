import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../data/model/ticket_model.dart';
import '../../repository/ticket_repository.dart';

abstract class CreateTicketUseCase {
  Future<Either<Failure, void>> call(final TicketModel ticket);
}

class CreateTicketUseCaseImpl implements CreateTicketUseCase {
  final TicketRepository repository;

  CreateTicketUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, void>> call(final TicketModel ticket) async {
    return repository.createTicket(ticket);
  }
}
