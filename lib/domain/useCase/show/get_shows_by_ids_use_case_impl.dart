import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../entities/show.dart';
import '../../repository/show_repository.dart';

abstract class GetShowsByIdsUseCase {
  Future<Either<Failure, List<Show>>> call(final List<String> showsIds);
}

class GetShowsByIdsUseCaseImpl implements GetShowsByIdsUseCase {
  final ShowRepository repository;

  GetShowsByIdsUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Show>>> call(final List<String> showsIds) async {
    final result = await repository.getShowsByIds(showsIds);
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
