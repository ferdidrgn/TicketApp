import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/purchase_repository.dart';

/// Rezervasyonu onaylar: koltuklar bilete dönüşür, tutar sahnede ödenir.
abstract class ConfirmReservationUseCase {
  Future<Either<Failure, List<String>>> call(final String orderId);
}

class ConfirmReservationUseCaseImpl implements ConfirmReservationUseCase {
  final PurchaseRepository repository;

  ConfirmReservationUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(final String orderId) =>
      repository.confirmReservation(orderId);
}
