import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../data/model/show_model.dart';
import '../../repository/show_repository.dart';

abstract class GetShowsByIdsUseCase {
  Future<Either<Failure, List<ShowModel?>>> call(final List<String> showsIds);
}

class GetShowsByIdsUseCaseImpl implements GetShowsByIdsUseCase {
  final ShowRepository repository;

  GetShowsByIdsUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<ShowModel?>>> call(final List<String> showsIds) async {
    return repository.getShowsByIds(showsIds);
  }
}
