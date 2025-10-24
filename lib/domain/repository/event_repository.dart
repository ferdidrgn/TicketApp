import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';

abstract class EventRepository {
  Future<Either<Failure, void>> initializeAndGetEventSeats(
      final String eventId);

  Future<Either<Failure, Map<String, dynamic>?>> getEventDetails(
      final String eventId,
      {final bool formatWithMonthName = false});

  /// Koltuk durumlarını anlık olarak dinler.
  /// Stream'ler genellikle Either ile sarmalanmaz,
  /// hata yönetimi stream'in kendi mekanizmasıyla (onError) yapılır.
  Stream<Map<String, Map<String, dynamic>>> getEventSeatStatusStream(
      final String eventId);

  /// Bir koltuğu rezerve etmeyi dener. Başarılı olursa true döner.
  Future<Either<Failure, bool>> attemptReservation(
      final String eventId, final String seatId, final String customerId);

  /// Bir rezervasyonu iptal eder.
  Future<Either<Failure, void>> releaseReservation(
      final String eventId, final String seatId, final String customerId);

  /// Satın almayı onaylar ve koltukları 'sold' yapar.
  Future<Either<Failure, void>> confirmPurchase(final String eventId,
      final List<String> seatIds, final String customerId);
}
