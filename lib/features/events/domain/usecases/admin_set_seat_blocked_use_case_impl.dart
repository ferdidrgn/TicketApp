import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/event_repository.dart';

abstract class AdminSetSeatBlockedUseCase {
  Future<Either<Failure, bool>> call(
      final String eventId, final String seatId, final bool blocked);
}

class AdminSetSeatBlockedUseCaseImpl implements AdminSetSeatBlockedUseCase {
  final EventRepository repository;

  AdminSetSeatBlockedUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(
          final String eventId, final String seatId, final bool blocked) async =>
      repository.adminSetSeatBlocked(eventId, seatId, blocked);
}
