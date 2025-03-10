import 'package:dartz/dartz.dart';
import 'package:ticketapp/domain/repository/login_repository.dart';
import '../../../../core/errors/failures.dart';

abstract class SignOutUseCase {
  Future<Either<Failure, void>> call();
}

class SignOutUseCaseImpl implements SignOutUseCase {
  final LoginRepository remoteDataSource;

  SignOutUseCaseImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, void>> call() async {
    return remoteDataSource.signOut();
  }
}
