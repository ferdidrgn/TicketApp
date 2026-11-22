import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/event_repository.dart';

abstract class DeleteEventUseCase {
  Future<Either<Failure, bool>> call(final String eventId);
}

class DeleteEventUseCaseImpl implements DeleteEventUseCase {
  final EventRepository repository;

  DeleteEventUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(final String eventId) async =>
      repository.deleteEvent(eventId);
}
