import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';

abstract class SeatRepository {
  /// Sahne ID'sine göre koltuk planını (Layout) getirir.
  /// Örn: {'A': ['A1', 'A2'], 'B': ['B1', 'B2']}
  Future<Either<Failure, Map<String, List<String>>>> getSeatsByStage(final String stageId);
}
