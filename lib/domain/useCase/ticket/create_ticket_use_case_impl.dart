import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../data/model/ticket_model.dart';
import '../../entities/ticket.dart';
import '../../repository/ticket_repository.dart';

abstract class CreateTicketUseCase {
  Future<Either<Failure, bool>> call(final Ticket ticket);
}

class CreateTicketUseCaseImpl implements CreateTicketUseCase {
  final TicketRepository repository;

  CreateTicketUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(final Ticket ticket) async {
    return repository.createTicket(TicketModel.fromEntity(ticket));
  }
}
