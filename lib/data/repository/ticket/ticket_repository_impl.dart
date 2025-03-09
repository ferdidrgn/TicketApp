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

  @override
  Future<Either<Failure, TicketModel?>> getTicketById(
      final String ticketId) async {
    if (await internetService.isConnected) {
      try {
        final ticket = await remoteDataSource.getTicketById(ticketId);
        return Right(ticket);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> createTicket(final TicketModel ticket) async {
    if (await internetService.isConnected) {
      try {
        await remoteDataSource.createTicket(ticket.toEntity());
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}
