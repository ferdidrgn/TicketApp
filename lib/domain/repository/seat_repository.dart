import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

abstract class SeatRepository {
  Future<Either<Failure, Map<String, List<String>>>> getSeatsByStage(final String stageId);
}
