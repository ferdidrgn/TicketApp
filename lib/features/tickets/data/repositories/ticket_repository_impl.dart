import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../core/base/base_repo.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../datasources/ticket_remote_data_source_and_impl.dart';
import '../mappers/ticket_mapper.dart';

class TicketRepositoryImpl extends BaseRepository implements TicketRepository {
  final TicketRemoteDataSource remoteDataSource;

  TicketRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Ticket>>> getTicketsByIds(
      final List<String> ticketIds) {
    // ID listesi boşsa direkt boş liste dön, sunucuya gitme
    if (ticketIds.isEmpty) return Future.value(const Right([]));

    return execute(() async {
      final models = await remoteDataSource.getTicketsByIds(ticketIds);
      return models.map((final model) => model.toEntity()).toList();
    });
  }

  @override
  Future<Either<Failure, List<Ticket>>> getTicketsByCustomerId(
          final String customerId) =>
      execute(() async {
        final models =
            await remoteDataSource.getTicketsByCustomerId(customerId);
        return models.map((final model) => model.toEntity()).toList();
      });

  @override
  Future<Either<Failure, bool>> createTicket(final Ticket ticket) =>
      execute(() async {
        final ticketModel = ticket.toModel();
        return await remoteDataSource.createTicket(ticketModel);
      });
}
