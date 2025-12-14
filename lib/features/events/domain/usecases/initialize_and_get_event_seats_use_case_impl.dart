import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/event_repository.dart';

abstract class InitializeAndGetEventSeatsUseCase {
  Future<Either<Failure, void>> call(final String eventId);
}

class InitializeAndGetEventSeatsUseCaseImpl
    implements InitializeAndGetEventSeatsUseCase {
  final EventRepository repository;

  InitializeAndGetEventSeatsUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, void>> call(final String eventId) =>
      repository.initializeAndGetEventSeats(eventId);
}
