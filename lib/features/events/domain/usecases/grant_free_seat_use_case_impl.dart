import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/event_repository.dart';

abstract class GrantFreeSeatUseCase {
  Future<Either<Failure, String>> call(
      final String eventId, final List<String> seatIds, final String note);
}

class GrantFreeSeatUseCaseImpl implements GrantFreeSeatUseCase {
  final EventRepository repository;

  GrantFreeSeatUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, String>> call(final String eventId,
          final List<String> seatIds, final String note) async =>
      repository.grantFreeSeat(eventId, seatIds, note);
}
