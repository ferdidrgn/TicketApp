import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';

abstract class EventRepository {
  Future<Either<Failure, void>> initializeAndGetEventSeats(final String? eventId);

  Future<Either<Failure, Map<String, Map<String, dynamic>>>> getSeatStatusByEvent(final String? eventId);

  Future<Either<Failure, List<String?>>> getPurchasedSeatsByCustomerId(final String? eventId, final String? customerId);

  Future<Either<Failure, void>> updateSeatStatus(final String? eventId, final String? seatId, final String? status, {final String? customerId});

  Future<Either<Failure, String?>> getStageId(final String? eventId);

  Future<Either<Failure, String?>> getEventPrice(final String? eventId);

  Future<Either<Failure, Map<String, String>?>> getEventDate(final String? eventId, {final bool formatWithMonthName = false});

  Future<Either<Failure, void>> reserveSeat(final String? eventId, final String? seatId, final String? customerId);

  Future<Either<Failure, void>> cancelReservation(final String? eventId, final String? seatId);
}