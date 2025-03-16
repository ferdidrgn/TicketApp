import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../repository/event_repository.dart';

abstract class GetEventDateUseCase {
  Future<Either<Failure, Map<String, String>?>> call(final String eventId, {final bool formatWithMonthName = false});
}

class GetEventDateUseCaseImpl implements GetEventDateUseCase {
  final EventRepository repository;

  GetEventDateUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, Map<String, String>?>> call(final String eventId, {final bool formatWithMonthName = false}) async {
    return repository.getEventDate(eventId, formatWithMonthName: formatWithMonthName);
  }
}
