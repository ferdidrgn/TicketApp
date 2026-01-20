import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

abstract class SignInAnonymouslyUseCase {
  Future<Either<Failure, User?>> call();
}

class SignInAnonymouslyUseCaseImpl implements SignInAnonymouslyUseCase {
  final AuthRepository remoteDataSource;

  SignInAnonymouslyUseCaseImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, User?>> call() async {
    return await remoteDataSource.signInAnonymously();
  }
}

