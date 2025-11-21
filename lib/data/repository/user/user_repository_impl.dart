import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../core/common/base_repo.dart';
import '../../../domain/repository/user_repository.dart';
import '../../datasources/user/user_remote_data_source_and_impl.dart';
import '../../model/user_model.dart';

class UserRepositoryImpl extends BaseRepository implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl({
    required this.remoteDataSource,
    //required super.internetService,
  });

  @override
  Future<Either<Failure, bool>> saveUser(
      final UserModel user, final String downloadUrl,
      {final bool isUpdate = false}) async {
    return execute(
        () => remoteDataSource.saveUser(user, downloadUrl, isUpdate: isUpdate));
  }

  @override
  Future<Either<Failure, UserModel?>> getUserById(final String userId) async {
    return execute(() async {
      if (userId.isEmpty) throw Exception('User ID cannot be empty.');
      return remoteDataSource.getUserById(userId);
    });
  }

  @override
  Future<Either<Failure, bool>> deleteUser(final String userId) async {
    return execute(() async {
      if (userId.isEmpty) throw Exception('User ID cannot be empty.');
      await remoteDataSource.deleteUser(userId);
      return true;
    });
  }
}
