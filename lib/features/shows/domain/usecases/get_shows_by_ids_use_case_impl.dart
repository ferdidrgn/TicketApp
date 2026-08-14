import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/show.dart';
import '../repositories/show_repository.dart';

abstract class GetShowsByIdsUseCase {
  Future<Either<Failure, List<Show>>> call(final List<String> showsIds);
}

class GetShowsByIdsUseCaseImpl implements GetShowsByIdsUseCase {
  final ShowRepository repository;

  GetShowsByIdsUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Show>>> call(final List<String> showsIds) async =>
      repository.getShowsByIds(showsIds);
}
