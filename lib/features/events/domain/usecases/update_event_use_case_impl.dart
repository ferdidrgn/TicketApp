import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/event_repository.dart';

abstract class UpdateEventUseCase {
  Future<Either<Failure, bool>> call(
      final String eventId, final Map<String, dynamic> updatedData);
}

class UpdateEventUseCaseImpl implements UpdateEventUseCase {
  final EventRepository repository;

  UpdateEventUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(
          final String eventId, final Map<String, dynamic> updatedData) async =>
      repository.updateEvent(eventId, updatedData);
}
