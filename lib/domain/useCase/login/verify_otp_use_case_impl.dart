import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../../domain/repository/login_repository.dart';

abstract class VerifyOtpUseCase {
  Future<Either<Failure, bool>> call(final String verificationId, final String otp);
}

class VerifyOtpUseCaseImpl implements VerifyOtpUseCase {
  final LoginRepository repository;

  VerifyOtpUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(final String verificationId, final String otp) async {
    return repository.verifyOtp(verificationId, otp);
  }
}
