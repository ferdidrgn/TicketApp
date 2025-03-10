import 'package:dartz/dartz.dart';
import 'package:ticketapp/domain/repository/login_repository.dart';
import '../../../../core/errors/failures.dart';

abstract class VerifyOtpUseCase {
  Future<Either<Failure, bool>> call(
      final String verificationId, final String otp);
}

class VerifyOtpUseCaseImpl implements VerifyOtpUseCase {
  final LoginRepository remoteDataSource;

  VerifyOtpUseCaseImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, bool>> call(
      final String verificationId, final String otp) async {
    return remoteDataSource.verifyOtp(verificationId, otp);
  }
}
