import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../repository/event_repository.dart';

abstract class GetSeatStatusByEventUseCase {
  Future<Either<Failure, Map<String, Map<String, dynamic>>>>
  call(final String? eventId);
}

class GetSeatStatusByEventUseCaseImpl implements GetSeatStatusByEventUseCase {
  final EventRepository repository;

  GetSeatStatusByEventUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, Map<String, Map<String, dynamic>>>>
  call(final String? eventId) async {
    return repository.getSeatStatusByEvent(eventId);
  }
}
