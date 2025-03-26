import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../entities/show.dart';
import '../../repository/show_repository.dart';

abstract class GetShowsUseCase {
  Future<Either<Failure, List<Show>>> call(isLimit);
}

class GetShowsUseCaseImpl implements GetShowsUseCase {
  ShowRepository repository;

  GetShowsUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Show>>> call(isLimit) async {
    final result = await repository.getShows(isLimit);
    return result.fold(
      (final failure) => Left(failure),
      (final showsModels) {
        final shows = showsModels
                ?.map((final showModel) => showModel?.toEntity())
                .whereType<Show>()
                .toList() ??
            [];
        return Right(shows);
      },
    );
  }
}
