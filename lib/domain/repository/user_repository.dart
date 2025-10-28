import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../data/model/user_model.dart';

abstract class UserRepository {
  Future<Either<Failure, bool>> saveUser(final UserModel user, final String downloadUrl, {final bool isUpdate = false});
  Future<Either<Failure, UserModel?>> getUserById(final String userId);
  Future<Either<Failure, bool>> deleteUser(final String userId);
}
