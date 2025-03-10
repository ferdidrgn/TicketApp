import 'package:firebase_auth/firebase_auth.dart';
import 'package:ticketapp/domain/repository/login_repository.dart';

abstract class GetCurrentUserUseCase {
  User? call();
}

class GetCurrentUserUseCaseImpl implements GetCurrentUserUseCase {
  final LoginRepository remoteDataSource;

  GetCurrentUserUseCaseImpl(this.remoteDataSource);

  @override
  User? call() {
    return remoteDataSource.getCurrentUser();
  }
}
