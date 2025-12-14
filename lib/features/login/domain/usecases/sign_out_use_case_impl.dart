import 'package:dartz/dartz.dart';
import 'package:ticketapp/features/login/domain/repositories/login_repository.dart';
import '../../../../../core/errors/failures.dart';

abstract class SignOutUseCase {
  Future<Either<Failure, bool>> call();
}

class SignOutUseCaseImpl implements SignOutUseCase {
  final LoginRepository remoteDataSource;

  SignOutUseCaseImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, bool>> call() async {
    return remoteDataSource.signOut();
  }
}
