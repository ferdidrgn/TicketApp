import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/purchase_entities.dart';
import '../repositories/purchase_repository.dart';

abstract class GetOpenOrdersUseCase {
  Future<Either<Failure, List<PurchaseOrder>>> call(final String userId);
}

class GetOpenOrdersUseCaseImpl implements GetOpenOrdersUseCase {
  final PurchaseRepository repository;

  GetOpenOrdersUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<PurchaseOrder>>> call(final String userId) =>
      repository.getOpenOrders(userId);
}
