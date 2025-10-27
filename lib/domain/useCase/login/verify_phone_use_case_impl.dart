import 'package:dartz/dartz.dart';
import 'package:ticketapp/domain/repository/login_repository.dart';
import '../../../../core/errors/failures.dart';

abstract class VerifyPhoneUseCase {
  Future<Either<Failure, bool>> call(
    final String phoneNumber, {
    required final void Function(String) onVerificationCompleted,
    required final void Function(String) onCodeSent,
    required final void Function(String) onAutoRetrievalTimeout,
  });
}

class VerifyPhoneUseCaseImpl implements VerifyPhoneUseCase {
  final LoginRepository remoteDataSource;

  VerifyPhoneUseCaseImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, bool>> call(
    final String phoneNumber, {
    required final void Function(String) onVerificationCompleted,
    required final void Function(String) onCodeSent,
    required final void Function(String) onAutoRetrievalTimeout,
  }) {
    return remoteDataSource.verifyPhone(
      phoneNumber,
      onVerificationCompleted: onVerificationCompleted,
      onCodeSent: onCodeSent,
      onAutoRetrievalTimeout: onAutoRetrievalTimeout,
    );
  }
}
