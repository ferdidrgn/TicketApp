import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/event_repository.dart';

abstract class ConfirmPurchaseUseCase {
  Future<Either<Failure, bool>> call(final String eventId,
      final List<String> seatIds, final String customerId);
}

class ConfirmPurchaseUseCaseImpl implements ConfirmPurchaseUseCase {
  final EventRepository repository;

  ConfirmPurchaseUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(final String eventId,
          final List<String> seatIds, final String customerId) =>
      repository.confirmPurchase(eventId, seatIds, customerId);
}
