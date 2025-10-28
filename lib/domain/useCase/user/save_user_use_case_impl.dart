import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../data/model/user_model.dart';
import '../../repository/user_repository.dart';

abstract class SaveUserUseCase {
  Future<Either<Failure, bool>> call(
      final UserModel user, final String downloadUrl,
      {final isUpdate = false});
}

class SaveUserUseCaseImpl implements SaveUserUseCase {
  final UserRepository repository;

  SaveUserUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(
      final UserModel user, final String downloadUrl,
      {final isUpdate = false}) async {
    return repository.saveUser(user, downloadUrl, isUpdate: isUpdate);
  }
}
