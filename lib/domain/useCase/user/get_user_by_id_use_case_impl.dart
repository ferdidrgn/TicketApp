import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../data/model/user_model.dart';
import '../../repository/user_repository.dart';

abstract class GetUserByIdUseCase {
  Future<Either<Failure, UserModel?>> call(final String userId);
}

class GetUserByIdUseCaseImpl implements GetUserByIdUseCase {
  final UserRepository repository;

  GetUserByIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, UserModel?>> call(final String userId) async {
    return repository.getUserById(userId);
  }
}
