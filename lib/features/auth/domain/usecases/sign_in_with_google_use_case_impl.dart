import 'package:dartz/dartz.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

abstract class SignInWithGoogleUseCase {
  Future<Either<Failure, GoogleSignInAccount?>> call();
}

class SignInWithGoogleUseCaseImpl implements SignInWithGoogleUseCase {
  final AuthRepository remoteDataSource;

  SignInWithGoogleUseCaseImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, GoogleSignInAccount?>> call() async {
    return remoteDataSource.signInWithGoogle();
  }
}
