import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/purchase_repository.dart';

abstract class ConfirmFreeUseCase {
  Future<Either<Failure, List<String>>> call(final String orderId);
}

class ConfirmFreeUseCaseImpl implements ConfirmFreeUseCase {
  final PurchaseRepository repository;

  ConfirmFreeUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<String>>> call(final String orderId) =>
      repository.confirmFree(orderId);
}
