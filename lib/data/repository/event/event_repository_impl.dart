import 'package:dartz/dartz.dart';
import 'package:ticketapp/data/model/event_model.dart';
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
  Future<Either<Failure, void>> initializeAndGetEventSeats(
      final String eventId) async {
    return execute(() => remoteDataSource.initializeAndGetEventSeats(eventId));
  }

  @override
  Future<Either<Failure, List<EventModel?>?>> getEventsByIds(
      final List<String> eventIds) async {
    return execute(() => remoteDataSource.getEventsByIds(eventIds));
  }

  @override
  Stream<Map<String, Map<String, dynamic>>> getEventSeatStatusStream(
      final String eventId) {
    // Stream'ler 'execute' bloğuna sarılmaz çünkü anlık veri akışıdırlar
    try {
      return remoteDataSource.getEventSeatStatusStream(eventId);
    } catch (e) {
      // Data source'daki senkron bir hata (örn: eventId boş) fırlatılırsa
      return Stream.error(e);
    }
  }

  @override
  Future<Either<Failure, bool>> attemptReservation(final String eventId,
      final String seatId, final String customerId) async {
    return execute(
        () => remoteDataSource.attemptReservation(eventId, seatId, customerId));
  }

  @override
  Future<Either<Failure, void>> releaseReservation(final String eventId,
      final String seatId, final String customerId) async {
    return execute(
        () => remoteDataSource.releaseReservation(eventId, seatId, customerId));
  }

  @override
  Future<Either<Failure, void>> confirmPurchase(final String eventId,
      final List<String> seatIds, final String customerId) async {
    return execute(
        () => remoteDataSource.confirmPurchase(eventId, seatIds, customerId));
  }
}
