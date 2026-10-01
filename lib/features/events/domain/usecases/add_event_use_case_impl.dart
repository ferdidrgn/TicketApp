import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/event.dart';
import '../repositories/event_repository.dart';

abstract class AddEventUseCase {
  Future<Either<Failure, bool>> call(final Event event);
}

class AddEventUseCaseImpl implements AddEventUseCase {
  final EventRepository repository;

  AddEventUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(final Event event) async =>
      repository.addEvent(event);
}
