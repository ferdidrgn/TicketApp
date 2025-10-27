import 'package:dartz/dartz.dart';
import 'package:ticketapp/domain/repository/login_repository.dart';
import '../../../../core/errors/failures.dart';

abstract class VerifyPhoneUseCase {
  Future<Either<Failure, void>> call(
    final String phoneNumber,
    final Function(String) onVerificationCompleted,
    final Function(String) onCodeSent,
    final Function(String) onAutoRetrievalTimeout,
  );
}

class VerifyPhoneUseCaseImpl implements VerifyPhoneUseCase {
  final LoginRepository remoteDataSource;

  VerifyPhoneUseCaseImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, void>> call(
    final String phoneNumber,
    final Function(String) onVerificationCompleted,
    final Function(String) onCodeSent,
    final Function(String) onAutoRetrievalTimeout,
  ) async {
    return remoteDataSource.verifyPhone(
      phoneNumber,
      onVerificationCompleted,
      onCodeSent,
      onAutoRetrievalTimeout,
    );
  }
}
