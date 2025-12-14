import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../../data/models/ticket_model.dart';

abstract class TicketRepository {
  Future<Either<Failure, List<TicketModel?>?>> getTicketsByIds(final List<String> ticketIds);
  Future<Either<Failure, List<TicketModel?>?>> getTicketsByCustomerId(final String customerId);
  Future<Either<Failure, bool>> createTicket(final TicketModel ticket);
}
