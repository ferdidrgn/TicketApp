import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../domain/entities/ticket.dart';

abstract class TicketRepository {
  Future<Either<Failure, List<Ticket>>> getTicketsByIds(final List<String> ticketIds);
  Future<Either<Failure, List<Ticket>>> getTicketsByCustomerId(final String customerId);
  Future<Either<Failure, bool>> createTicket(final Ticket ticket);
}
