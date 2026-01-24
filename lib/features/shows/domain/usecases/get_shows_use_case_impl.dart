import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/show.dart';
import '../repositories/show_repository.dart';

abstract class GetShowsUseCase {
  Future<Either<Failure, List<Show>>> call(final bool isLimit);
}

class GetShowsUseCaseImpl implements GetShowsUseCase {
  final ShowRepository repository;

  GetShowsUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Show>>> call(final bool isLimit) async =>
      repository.getShows(isLimit);
}
