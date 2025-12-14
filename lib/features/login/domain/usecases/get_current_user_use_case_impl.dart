import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ticketapp/features/login/domain/repositories/login_repository.dart';
import '../../../../core/errors/failures.dart';

abstract class GetCurrentUserUseCase {
  Future<Either<Failure, User?>> call();
}

class GetCurrentUserUseCaseImpl implements GetCurrentUserUseCase {
  final LoginRepository remoteDataSource;

  GetCurrentUserUseCaseImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, User?>> call() {
    return remoteDataSource.getCurrentUser();
  }
}
