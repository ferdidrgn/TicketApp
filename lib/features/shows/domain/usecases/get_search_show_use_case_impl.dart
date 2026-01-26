import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/show.dart';
import '../repositories/show_repository.dart';

abstract class GetSearchShowUseCase {
  Future<Either<Failure, List<Show>>> call(
      final String? query, final List<String> categories, final String? type);
}

class GetSearchShowUseCaseImpl implements GetSearchShowUseCase {
  final ShowRepository repository;

  GetSearchShowUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<Show>>> call(final String? query,
          final List<String> categories, final String? type) async =>
      repository.getSearchShow(query, categories, type);
}
