import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../core/common/base_repo.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../datasources/ticket_remote_data_source_and_impl.dart';
import '../models/ticket_model.dart';

class TicketRepositoryImpl extends BaseRepository implements TicketRepository {
  final TicketRemoteDataSource remoteDataSource;

  TicketRepositoryImpl({
    required this.remoteDataSource,
    //required super.internetService,
  });

  @override
  Future<Either<Failure, List<TicketModel?>?>> getTicketsByIds(
      final List<String> ticketIds) async {
    return execute(() async {
      if (ticketIds.isEmpty) throw Exception('Ticket ID cannot be empty.');
      return remoteDataSource.getTicketsByIds(ticketIds);
    });
  }

  @override
  Future<Either<Failure, bool>> createTicket(final TicketModel ticket) async =>
      execute(() => remoteDataSource.createTicket(ticket.toEntity()));

  @override
  Future<Either<Failure, List<TicketModel?>?>> getTicketsByCustomerId(
          final String customerId) async =>
      execute(() => remoteDataSource.getTicketsByCustomerId(customerId));
}
