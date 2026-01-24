import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../repositories/show_repository.dart';

abstract class DeleteShowUseCase {
  Future<Either<Failure, bool>> call(final String showId);
}

class DeleteShowUseCaseImpl implements DeleteShowUseCase {
  final ShowRepository repository;

  DeleteShowUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(final String showId) async =>
      repository.deleteShow(showId);
}
