import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

abstract class GetCurrentUserUseCase {
  Future<Either<Failure, User?>> call();
}

class GetCurrentUserUseCaseImpl implements GetCurrentUserUseCase {
  final AuthRepository remoteDataSource;

  GetCurrentUserUseCaseImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, User?>> call() {
    return remoteDataSource.getCurrentUser();
  }
}
