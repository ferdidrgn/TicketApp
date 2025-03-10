import 'package:dartz/dartz.dart';
import 'package:ticketapp/domain/repository/login_repository.dart';
import '../../../../core/errors/failures.dart';

abstract class SignInWithGoogleUseCase {
  Future<Either<Failure, String?>> call();
}

class SignInWithGoogleUseCaseImpl implements SignInWithGoogleUseCase {
  final LoginRepository remoteDataSource;

  SignInWithGoogleUseCaseImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, String?>> call() async {
    return remoteDataSource.signInWithGoogle();
  }
}
