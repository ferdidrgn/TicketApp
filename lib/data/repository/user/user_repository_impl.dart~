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

  @override
  Future<Either<Failure, void>> saveUser(
      final UserModel user, final String downloadUrl,
      {final isUpdate = false}) async {
    if (await internetService.isConnected) {
      try {
        await remoteDataSource.saveUser(user, downloadUrl, isUpdate: isUpdate);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, UserModel?>> getUserById(final String userId) async {
    if (await internetService.isConnected) {
      try {
        final user = await remoteDataSource.getUserById(userId);
        return Right(user);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(final String userId) async {
    if (await internetService.isConnected) {
      try {
        await remoteDataSource.deleteUser(userId);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('No internet connection'));
    }
  }
}
