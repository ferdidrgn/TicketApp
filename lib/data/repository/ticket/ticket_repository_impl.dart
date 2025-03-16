import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../core/network/internet_service.dart';
import '../../../domain/repository/ticket_repository.dart';
import '../../datasources/ticket/ticket_remote_data_source_and_impl.dart';
import '../../model/ticket_model.dart';

class TicketRepositoryImpl implements TicketRepository {
  final TicketRemoteDataSource remoteDataSource;
  final InternetService internetService;

  TicketRepositoryImpl({
    required this.remoteDataSource,
    required this.internetService,
  });

  Future<Either<Failure, T>> _execute<T>(final Future<T> Function() action) async {
    if (await internetService.isConnected) {
      try {
        final result = await action();
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, TicketModel?>> getTicketById(final String ticketId) async {
    return _execute(() async {
      if (ticketId.isEmpty) throw Exception('Ticket ID cannot be empty.');
      return await remoteDataSource.getTicketById(ticketId);
    });
  }

  @override
  Future<Either<Failure, void>> createTicket(final TicketModel ticket) async {
    return _execute(() async {
      await remoteDataSource.createTicket(ticket.toEntity());
    });
  }
}
