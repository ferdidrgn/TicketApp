import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../../../core/base/base_repo.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_data_source_and_impl.dart';
import '../mappers/user_mapper.dart';

class UserRepositoryImpl extends BaseRepository implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, bool>> saveUser(
          final User user, final String? downloadUrl,
          {final bool isUpdate = false}) =>
      execute(() async => remoteDataSource.saveUser(user.toModel(), downloadUrl,
          isUpdate: isUpdate));

  @override
  Future<Either<Failure, User?>> getUserById(final String userId) =>
      execute(() async {
        final userModel = await remoteDataSource.getUserById(userId);
        if (userModel == null) return null;
        return userModel.toEntity();
      });

  @override
  Future<Either<Failure, bool>> deleteUser(final String userId) =>
      execute(() async => remoteDataSource.deleteUser(userId));
}
