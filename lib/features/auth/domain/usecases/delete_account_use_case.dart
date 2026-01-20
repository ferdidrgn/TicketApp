import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/auth_repository.dart';
abstract class DeleteAccountUseCase {
  Future<Either<Failure, bool>> call();
}

class DeleteAccountUseCaseImpl implements DeleteAccountUseCase {
  final AuthRepository repository;

  DeleteAccountUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call() async {
    return repository.deleteAccount();
  }
}
