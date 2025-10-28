import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../entities/show.dart';
import '../../repository/show_repository.dart';

abstract class GetShowsUseCase {
  Future<Either<Failure, List<Show>>> call(final bool isLimit);
}

class GetShowsUseCaseImpl implements GetShowsUseCase {
  final ShowRepository repository;

  GetShowsUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Show>>> call(final bool isLimit) async {
    final result = await repository.getShows(isLimit);
    return result.fold(
        (final failure) => Left(failure),
        (final showsModels) => Right(showsModels
                ?.map((final showModel) => showModel?.toEntity())
                .whereType<Show>()
                .toList() ??
            [])); //Show a çevirdik.
  }
}
