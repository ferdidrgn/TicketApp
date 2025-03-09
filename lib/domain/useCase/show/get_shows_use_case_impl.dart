import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../data/model/show_model.dart';
import '../../repository/show_repository.dart';

abstract class GetShowsUseCase {
  Future<Either<Failure, List<ShowModel?>>> call(final isLimit);
}

class GetShowsUseCaseImpl implements GetShowsUseCase {
  final ShowRepository repository;

  GetShowsUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<ShowModel?>>> call(final isLimit) async {
    return repository.getShows(isLimit);
  }
}
