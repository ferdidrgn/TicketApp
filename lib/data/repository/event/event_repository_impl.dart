import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../core/common/base_repo.dart';
import '../../../domain/repository/event_repository.dart';
import '../../datasources/event/event_remote_data_source_and_impl.dart';

class EventRepositoryImpl extends BaseRepository implements EventRepository {
  final EventRemoteDataSource remoteDataSource;

  EventRepositoryImpl({
    required this.remoteDataSource,
    required super.internetService,
  });

  @override
  Future<Either<Failure, void>> initializeAndGetEventSeats(final String eventId) async {
    return execute(() async {
      if (eventId.isEmpty) throw Exception('Event ID cannot be empty.');
      await remoteDataSource.initializeAndGetEventSeats(eventId);
    });
  }

  @override
  Future<Either<Failure, Map<String, Map<String, dynamic>>?>> getSeatStatusByEvent(final String eventId) async {
    return execute(() async {
      if (eventId.isEmpty) throw Exception('Event ID cannot be empty.');
      return remoteDataSource.getSeatStatusByEvent(eventId);
    });
  }

  @override
  Future<Either<Failure, List<String?>?>> getPurchasedSeatsByCustomerId(final String eventId, final String customerId) async {
    return execute(() async {
      if (eventId.isEmpty || customerId.isEmpty) throw Exception('Event ID and Customer ID cannot be empty.');
      return remoteDataSource.getPurchasedSeatsByCustomerId(eventId, customerId);
    });
  }

  @override
  Future<Either<Failure, void>> updateSeatStatus(final String eventId, final String seatId, final String status, {final String? customerId}) async {
    return execute(() async {
      if (eventId.isEmpty || seatId.isEmpty || status.isEmpty) throw Exception('Event ID, Seat ID, and Status cannot be empty.');
      await remoteDataSource.updateSeatStatus(eventId, seatId, status, customerId: customerId);
    });
  }

  @override
  Future<Either<Failure, String?>> getStageId(final String eventId) async {
    return execute(() async {
      if (eventId.isEmpty) throw Exception('Event ID cannot be empty.');
      return remoteDataSource.getStageId(eventId);
    });
  }

  @override
  Future<Either<Failure, String?>> getEventPrice(final String eventId) async {
    return execute(() async {
      if (eventId.isEmpty) throw Exception('Event ID cannot be empty.');
      return remoteDataSource.getEventPrice(eventId);
    });
  }

  @override
  Future<Either<Failure, Map<String, String>?>> getEventDate(final String eventId, {final bool formatWithMonthName = false}) async {
    return execute(() async {
      if (eventId.isEmpty) throw Exception('Event ID cannot be empty.');
      return remoteDataSource.getEventDate(eventId, formatWithMonthName: formatWithMonthName);
    });
  }

  @override
  Future<Either<Failure, void>> reserveSeat(final String eventId, final String seatId, final String customerId) async {
    return execute(() async {
      if (eventId.isEmpty || seatId.isEmpty || customerId.isEmpty) throw Exception('Event ID, Seat ID, and Customer ID cannot be empty.');
      await remoteDataSource.reserveSeat(eventId, seatId, customerId);
    });
  }

  @override
  Future<Either<Failure, void>> cancelReservation(final String eventId, final String seatId) async {
    return execute(() async {
      if (eventId.isEmpty || seatId.isEmpty) throw Exception('Event ID and Seat ID cannot be empty.');
      await remoteDataSource.cancelReservation(eventId, seatId);
    });
  }
}
