import '../entities/purchase_entities.dart';
import '../repositories/purchase_repository.dart';

abstract class WatchOrderUseCase {
  Stream<PurchaseOrder?> call(final String orderId);
}

class WatchOrderUseCaseImpl implements WatchOrderUseCase {
  final PurchaseRepository repository;

  WatchOrderUseCaseImpl(this.repository);

  @override
  Stream<PurchaseOrder?> call(final String orderId) =>
      repository.watchOrder(orderId);
}
