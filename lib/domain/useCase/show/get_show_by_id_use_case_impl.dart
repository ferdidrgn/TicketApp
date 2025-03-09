import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../data/model/show_model.dart';
import '../../repository/show_repository.dart';

abstract class GetShowByIdUseCase {
  Future<Either<Failure, ShowModel?>> call(final String showId);
}

class GetShowByIdUseCaseImpl implements GetShowByIdUseCase {
  final ShowRepository repository;

  GetShowByIdUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, ShowModel?>> call(final String showId) async {
    return repository.getShowById(showId);
  }
}
