import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/event.dart';
import '../repositories/event_repository.dart';

abstract class GetEventsByIdsUseCase {
  Future<Either<Failure, List<Event>>> call(final List<String> eventIds);
}

class GetEventsByIdsUseCaseImpl implements GetEventsByIdsUseCase {
  final EventRepository repository;

  GetEventsByIdsUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Event>>> call(
          final List<String> eventIds) async =>
      repository.getEventsByIds(eventIds);
}
