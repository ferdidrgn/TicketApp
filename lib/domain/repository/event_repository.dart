import 'package:dartz/dartz.dart';
import 'package:ticketapp/data/model/event_model.dart';
import '../../../../core/errors/failures.dart';

abstract class EventRepository {
  Future<Either<Failure, void>> initializeAndGetEventSeats(
      final String eventId);

  Future<Either<Failure, List<EventModel?>?>> getEventsByIds(
      final List<String> eventIds);

  /// Stream'ler genellikle Either ile sarmalanmaz,/// hata yönetimi stream'in kendi mekanizmasıyla (onError) yapılır.
  Stream<Map<String, Map<String, dynamic>>> getEventSeatStatusStream(
      final String eventId);

  /// Bir koltuğu rezerve etmeyi dener. Başarılı olursa true döner.
  Future<Either<Failure, bool>> attemptReservation(
      final String eventId, final String seatId, final String customerId);

  /// Bir rezervasyonu iptal eder.
  Future<Either<Failure, bool>> releaseReservation(
      final String eventId, final String seatId, final String customerId);

  /// Satın almayı onaylar ve koltukları 'sold' yapar.
  Future<Either<Failure, bool>> confirmPurchase(final String eventId,
      final List<String> seatIds, final String customerId);
}
