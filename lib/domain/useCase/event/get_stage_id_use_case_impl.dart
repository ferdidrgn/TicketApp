import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../repository/event_repository.dart';

abstract class GetStageIdUseCase {
  Future<Either<Failure, String?>> call(final String eventId);
}

class GetStageIdUseCaseImpl implements GetStageIdUseCase {
  final EventRepository repository;

  GetStageIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, String?>> call(final String eventId) async {
    return repository.getStageId(eventId);
  }
}
