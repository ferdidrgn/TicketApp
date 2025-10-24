import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../repository/event_repository.dart';

abstract class GetEventDetailsUseCase {
  Future<Either<Failure, Map<String, dynamic>?>> call(final String eventId,
      {final bool formatWithMonthName = false});
}

class GetEventDetailsUseCaseImpl implements GetEventDetailsUseCase {
  final EventRepository repository;

  GetEventDetailsUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, Map<String, dynamic>?>> call(final String eventId,
          {final bool formatWithMonthName = false}) =>
      repository.getEventDetails(eventId,
          formatWithMonthName: formatWithMonthName);
}
