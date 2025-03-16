import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../core/network/internet_service.dart';
import '../../../domain/repository/user_repository.dart';
import '../../datasources/user/user_remote_data_source_and_impl.dart';
import '../../model/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;
  final InternetService internetService;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.internetService,
  });

  Future<Either<Failure, T>> _execute<T>(final Future<T> Function() action) async {
    if (await internetService.isConnected)
      try {
        final result = await action();
        return Right(result);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    else return const Left(NetworkFailure('No internet connection'));
  }

  @override
  Future<Either<Failure, void>> saveUser(final UserModel user, final String downloadUrl, {final bool isUpdate = false}) async {
    return _execute(() async {
      await remoteDataSource.saveUser(user, downloadUrl, isUpdate: isUpdate);
    });
  }

  @override
  Future<Either<Failure, UserModel?>> getUserById(final String userId) async {
    return _execute(() async {
      if (userId.isEmpty) throw Exception('User ID cannot be empty.');
      return remoteDataSource.getUserById(userId);
    });
  }

  @override
  Future<Either<Failure, void>> deleteUser(final String userId) async {
    return _execute(() async {
      if (userId.isEmpty) throw Exception('User ID cannot be empty.');
      await remoteDataSource.deleteUser(userId);
    });
  }
}
