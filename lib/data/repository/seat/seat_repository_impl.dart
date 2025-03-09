import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../core/network/internet_service.dart';
import '../../../domain/repository/seat_repository.dart';
import '../../datasources/seat/seat_remote_data_source_and_impl.dart';

class SeatRepositoryImpl implements SeatRepository {
  final SeatRemoteDataSource remoteDataSource;
  final InternetService internetService;

  SeatRepositoryImpl({
    required this.remoteDataSource,
    required this.internetService,
  });

  @override
  Future<Either<Failure, Map<String, List<String>>>> getSeatsByStage(final String stageId) async {
    if (await internetService.isConnected) {
      try {
        final seats = await remoteDataSource.getSeatsByStage(stageId);
        return Right(seats);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}
