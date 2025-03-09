import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../repository/event_repository.dart';

abstract class GetPurchasedSeatsByCustomerIdUseCase {
  Future<Either<Failure, List<String?>>> call(
      final String? eventId, final String? customerId);
}

class GetPurchasedSeatsByCustomerIdUseCaseImpl
    implements GetPurchasedSeatsByCustomerIdUseCase {
  final EventRepository repository;

  GetPurchasedSeatsByCustomerIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<String?>>> call(
      final String? eventId, final String? customerId) async {
    return repository.getPurchasedSeatsByCustomerId(eventId, customerId);
  }
}
