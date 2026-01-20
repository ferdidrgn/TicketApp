import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

abstract class VerifyOtpUseCase {
  Future<Either<Failure, bool>> call(
      final String verificationId, final String otp);
}

class VerifyOtpUseCaseImpl implements VerifyOtpUseCase {
  final AuthRepository repository;

  VerifyOtpUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(
          final String verificationId, final String otp) =>
      repository.verifyOtp(verificationId, otp);
}
