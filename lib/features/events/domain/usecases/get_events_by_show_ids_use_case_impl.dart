import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/event.dart';
import '../repositories/event_repository.dart';

abstract class GetEventsByShowIdsUseCase {
  Future<Either<Failure, List<Event>>> call(final List<String> showIds);
}

class GetEventsByShowIdsUseCaseImpl implements GetEventsByShowIdsUseCase {
  final EventRepository repository;

  GetEventsByShowIdsUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Event>>> call(
          final List<String> showIds) async =>
      repository.getEventsByShowIds(showIds);
}
