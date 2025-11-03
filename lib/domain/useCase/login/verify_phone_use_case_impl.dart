import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/repository/login_repository.dart';

abstract class VerifyPhoneUseCase {
  Future<Either<Failure, String>> call({
    required final String phoneNumber,
    required final void Function(PhoneAuthCredential) onVerificationCompleted,
    required final void Function(String, int?) onCodeSent,
    required final void Function(String) onAutoRetrievalTimeout,
  });
}

class VerifyPhoneUseCaseImpl implements VerifyPhoneUseCase {
  final LoginRepository repository;

  VerifyPhoneUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, String>> call({
    required final String phoneNumber,
    required final void Function(PhoneAuthCredential) onVerificationCompleted,
    required final void Function(String, int?) onCodeSent,
    required final void Function(String) onAutoRetrievalTimeout,
  }) async {
    return repository.verifyPhone(
      phoneNumber: phoneNumber,
      onVerificationCompleted: onVerificationCompleted,
      onCodeSent: onCodeSent,
      onAutoRetrievalTimeout: onAutoRetrievalTimeout,
    );
  }
}
