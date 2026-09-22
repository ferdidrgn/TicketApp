import 'package:dartz/dartz.dart';
import '../../../../../../core/errors/failures.dart';
import '../entities/event.dart';

abstract class EventRepository {
  Future<Either<Failure, void>> initializeAndGetEventSeats(
      final String eventId);

  // 🔥 Model yerine temiz Entity (Event) listesi döndürür
  Future<Either<Failure, List<Event>>> getEventsByIds(
      final List<String> eventIds);

  /// Etkinlikleri, `Event.showId` alanına göre DOĞRUDAN sorgular — Show
  /// tarafındaki `eventsId` dizisine bağımlı değildir. `Show.eventsId`
  /// güncellenmeyi unutulursa (ör. Firebase Console'dan elle eklenmiş bir
  /// etkinlik) bu yöntem yine de o etkinliği bulur.
  Future<Either<Failure, List<Event>>> getEventsByShowIds(
      final List<String> showIds);

  Stream<Map<String, Map<String, dynamic>>> getEventSeatStatusStream(
      final String eventId);

  Future<Either<Failure, bool>> attemptReservation(
      final String eventId, final String seatId, final String customerId);

  Future<Either<Failure, bool>> releaseReservation(
      final String eventId, final String seatId, final String customerId);

  Future<Either<Failure, bool>> confirmPurchase(final String eventId,
      final List<String> seatIds, final String customerId);
}
