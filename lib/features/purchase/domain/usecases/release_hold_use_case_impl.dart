import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/purchase_repository.dart';

abstract class ReleaseHoldUseCase {
  Future<Either<Failure, void>> call(final String orderId);
}

class ReleaseHoldUseCaseImpl implements ReleaseHoldUseCase {
  final PurchaseRepository repository;

  ReleaseHoldUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, void>> call(final String orderId) =>
      repository.releaseHold(orderId);
}
