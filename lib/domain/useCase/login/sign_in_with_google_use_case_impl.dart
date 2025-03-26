import 'package:dartz/dartz.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ticketapp/domain/repository/login_repository.dart';
import '../../../../core/errors/failures.dart';

abstract class SignInWithGoogleUseCase {
  Future<Either<Failure, GoogleSignInAccount?>> call();
}

class SignInWithGoogleUseCaseImpl implements SignInWithGoogleUseCase {
  final LoginRepository remoteDataSource;

  SignInWithGoogleUseCaseImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, GoogleSignInAccount?>> call() async {
    return remoteDataSource.signInWithGoogle();
  }
}
