import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../repository/event_repository.dart';

abstract class GetEventPriceUseCase {
  Future<Either<Failure, String?>> call(final String? eventId);
}

class GetEventPriceUseCaseImpl implements GetEventPriceUseCase {
  final EventRepository repository;

  GetEventPriceUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, String?>> call(final String? eventId) async {
    return repository.getEventPrice(eventId);
  }
}
