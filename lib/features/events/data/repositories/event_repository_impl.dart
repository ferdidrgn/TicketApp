import 'package:dartz/dartz.dart';
import 'package:ticketapp/features/events/data/models/event_model.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/base/base_repo.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_remote_data_source_and_impl.dart';
import '../mappers/event_mapper.dart';

class EventRepositoryImpl extends BaseRepository implements EventRepository {
  final EventRemoteDataSource remoteDataSource;

  EventRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, bool>> addEvent(final Event event) async =>
      execute(() async {
        final model = event.toModel();
        return remoteDataSource.addEvent(model);
      });

  @override
  Future<Either<Failure, List<Event>>> getEventsByIds(
          final List<String> eventIds) async =>
      execute(() async {
        final List<EventModel> models = await remoteDataSource.getEventsByIds(eventIds);
        return models.map((final model) => model.toEntity()).toList();
      });

  @override
  Future<Either<Failure, List<Event>>> getEventsByShowIds(
          final List<String> showIds) async =>
      execute(() async {
        final List<EventModel> models =
            await remoteDataSource.getEventsByShowIds(showIds);
        return models.map((final model) => model.toEntity()).toList();
      });

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
  Future<Either<Failure, bool>> adminSetSeatBlocked(
      final String eventId, final String seatId, final bool blocked) async {
    return execute(
        () => remoteDataSource.adminSetSeatBlocked(eventId, seatId, blocked));
  }
}
