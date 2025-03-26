import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../entities/user.dart';
import '../../repository/user_repository.dart';

abstract class GetUserByIdUseCase {
  Future<Either<Failure, User>> call(final String userId);
}

class GetUserByIdUseCaseImpl implements GetUserByIdUseCase {
  final UserRepository repository;

  GetUserByIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, User>> call(final String userId) async {
    final result = await repository.getUserById(userId);
    return result.fold(
      (final failure) => Left(failure),
      (final userModel) {
        final user = userModel?.toEntity();
        if (user == null) return Left(ServerFailure("User bilgisi yok. Giriş yapılmamış."));
        return Right(user);
      },
    );
  }
}
