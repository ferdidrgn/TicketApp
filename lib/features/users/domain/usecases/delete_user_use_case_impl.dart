import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../repositories/user_repository.dart';

abstract class DeleteUserUseCase {
  Future<Either<Failure, bool>> call(final String userId);
}

class DeleteUserUseCaseImpl implements DeleteUserUseCase {
  final UserRepository repository;

  DeleteUserUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(final String userId) async {
    return repository.deleteUser(userId);
  }
}
