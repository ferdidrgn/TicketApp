import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/model/ticket_model.dart';

abstract class TicketRepository {
  Future<Either<Failure, List<TicketModel?>?>> getTicketsByIds(final List<String> ticketIds);
  Future<Either<Failure, void>> createTicket(final TicketModel ticket);
}
