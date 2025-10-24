import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../repository/event_repository.dart';

abstract class ConfirmPurchaseUseCase {
  Future<Either<Failure, void>> call(final String eventId,
      final List<String> seatIds, final String customerId);
}

class ConfirmPurchaseUseCaseImpl implements ConfirmPurchaseUseCase {
  final EventRepository repository;

  ConfirmPurchaseUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, void>> call(final String eventId,
          final List<String> seatIds, final String customerId) =>
      repository.confirmPurchase(eventId, seatIds, customerId);
}
