import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/user_repository.dart';

abstract class SaveUserUseCase {
  Future<Either<Failure, bool>> call(final User user, final String downloadUrl,
      {final isUpdate = false});
}

class SaveUserUseCaseImpl implements SaveUserUseCase {
  final UserRepository repository;

  SaveUserUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(final User user, final String downloadUrl,
          {final isUpdate = false}) async =>
      repository.saveUser(user, downloadUrl, isUpdate: isUpdate);
}
