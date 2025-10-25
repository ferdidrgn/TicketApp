import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../entities/event.dart';
import '../../repository/event_repository.dart';

abstract class GetEventsByIdsUseCase {
  Future<Either<Failure, List<Event>>> call(final List<String> eventIds);
}

class GetEventsByIdsUseCaseImpl implements GetEventsByIdsUseCase {
  final EventRepository repository;

  GetEventsByIdsUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Event>>> call(final List<String> eventIds) async {
    final result = await repository.getEventsByIds(eventIds);
    return result.fold(
      (final failure) => Left(failure),
      (final eventsModel) {
        final events = eventsModel
                ?.map((final eventsModel) => eventsModel?.toEntity())
                .whereType<Event>()
                .toList() ??
            [];
        return Right(events);
      },
    );
  }
}
