import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../core/common/base_repo.dart';
import '../../domain/repositories/seat_repository.dart';
import '../datasources/seat_remote_data_source_and_impl.dart';

class SeatRepositoryImpl extends BaseRepository implements SeatRepository {
  final SeatRemoteDataSource remoteDataSource;

  SeatRepositoryImpl({
    required this.remoteDataSource,
    //required super.internetService,
  });

  @override
  Future<Either<Failure, Map<String, List<String?>?>?>> getSeatsByStage(final String stageId) async {
    return execute(() async {
      if (stageId.isEmpty) throw Exception('stageId is empty');
      return remoteDataSource.getSeatsByStage(stageId);
    });
  }
}
