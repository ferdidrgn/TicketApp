import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ticketapp/features/login/domain/repositories/login_repository.dart';
import '../../../../core/errors/failures.dart';

abstract class SignInAnonymouslyUseCase {
  Future<Either<Failure, User?>> call();
}

class SignInAnonymouslyUseCaseImpl implements SignInAnonymouslyUseCase {
  final LoginRepository remoteDataSource;

  SignInAnonymouslyUseCaseImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, User?>> call() async {
    return await remoteDataSource.signInAnonymously();
  }
}

