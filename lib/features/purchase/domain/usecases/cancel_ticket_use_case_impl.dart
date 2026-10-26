import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/purchase_repository.dart';

/// Kullanıcının kendi (sahnede ödemeli / ücretsiz) biletini iptal eder.
abstract class CancelTicketUseCase {
  Future<Either<Failure, void>> call(final String ticketId);
}

class CancelTicketUseCaseImpl implements CancelTicketUseCase {
  final PurchaseRepository repository;

  CancelTicketUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, void>> call(final String ticketId) =>
      repository.cancelTicket(ticketId);
}
