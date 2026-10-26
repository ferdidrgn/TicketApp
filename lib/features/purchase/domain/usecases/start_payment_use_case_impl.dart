import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/purchase_entities.dart';
import '../repositories/purchase_repository.dart';

abstract class StartPaymentUseCase {
  Future<Either<Failure, PaymentSession>> call(final String orderId, final String returnUrl);
}

class StartPaymentUseCaseImpl implements StartPaymentUseCase {
  final PurchaseRepository repository;

  StartPaymentUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, PaymentSession>> call(final String orderId, final String returnUrl) =>
      repository.startPayment(orderId, returnUrl);
}
