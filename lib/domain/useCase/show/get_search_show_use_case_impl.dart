import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../entities/show.dart';
import '../../repository/show_repository.dart';

abstract class GetSearchShowUseCase {
  Future<Either<Failure, List<Show>>> call(
      final List<String> categories, final String? type);
}

class GetSearchShowUseCaseImpl implements GetSearchShowUseCase {
  final ShowRepository repository;

  GetSearchShowUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Show>>> call(
      final List<String> categories, final String? type) async {
    final result = await repository.getSearchShow(categories, type);
    return result.fold(
        (final failure) => Left(failure),
        (final showsModels) => Right(showsModels
                ?.map((final showModel) => showModel?.toEntity())
                .whereType<Show>()
                .toList() ??
            []));
  }
}
