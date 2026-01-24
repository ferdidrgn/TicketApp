import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/user_repository.dart';

abstract class GetUserByIdUseCase {
  Future<Either<Failure, User?>> call(final String userId);
}

class GetUserByIdUseCaseImpl implements GetUserByIdUseCase {
  final UserRepository repository;

  GetUserByIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, User?>> call(final String userId) async =>
      repository.getUserById(userId);
}
