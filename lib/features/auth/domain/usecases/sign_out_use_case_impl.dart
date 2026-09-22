import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';

abstract class SignOutUseCase {
  Future<Either<Failure, bool>> call();
}

class SignOutUseCaseImpl implements SignOutUseCase {
  final AuthRepository remoteDataSource;

  SignOutUseCaseImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, bool>> call() async {
    return remoteDataSource.signOut();
  }
}
