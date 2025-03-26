import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../repository/event_repository.dart';

abstract class GetPurchasedSeatsByCustomerIdUseCase {
  Future<Either<Failure, List<String>?>> call(
      final String eventId, final String customerId);
}

class GetPurchasedSeatsByCustomerIdUseCaseImpl
    implements GetPurchasedSeatsByCustomerIdUseCase {
  final EventRepository repository;

  GetPurchasedSeatsByCustomerIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<String>?>> call(
      final String eventId, final String customerId) async {
    final resultTicketsIds =
        await repository.getPurchasedSeatsByCustomerId(eventId, customerId);
    return resultTicketsIds.fold((failure) => Left(failure), (ticketsIds) {
      return Right(List<String>.from(ticketsIds ?? []));
    });
  }
}
