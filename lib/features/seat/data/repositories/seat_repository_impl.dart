import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../core/base/base_repo.dart';
import '../../domain/repositories/seat_repository.dart';
import '../datasources/seat_remote_data_source_and_impl.dart';

class SeatRepositoryImpl extends BaseRepository implements SeatRepository {
  final SeatRemoteDataSource remoteDataSource;

  SeatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Map<String, List<String>>>> getSeatsByStage(
          final String stageId) async =>
      execute(() async {
        if (stageId.isEmpty) throw Exception('stageId is empty');

        final rawData = await remoteDataSource.getSeatsByStage(stageId);

        // 🛡️ Safe Transformation: Null değerleri burada temizliyoruz.
        // Repository katmanı, Domain'e kirli (null içeren) veri göndermez.
        return rawData?.map((final key, final value) {
              return MapEntry(key, value?.whereType<String>().toList() ?? []);
            }) ??
            {};
      });
}
