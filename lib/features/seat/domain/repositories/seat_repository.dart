import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/seat_plan_meta.dart';

abstract class SeatRepository {
  /// Sahne ID'sine göre koltuk planını (Layout) getirir.
  /// Örn: {'A': ['A1', 'A2'], 'B': ['B1', 'B2']}
  Future<Either<Failure, Map<String, List<String>>>> getSeatsByStage(final String stageId);

  /// `Seats/{stageId}` meta verisi: hangi sahneye ait, adresi, oluşturma/
  /// güncelleme zamanı. Koltuk layout'unu etkilemez, sadece izlenebilirlik.
  Future<Either<Failure, SeatPlanMeta>> getSeatPlanMeta(final String stageId);
}
