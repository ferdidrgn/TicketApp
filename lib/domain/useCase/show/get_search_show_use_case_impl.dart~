import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../data/model/show_model.dart';
import '../../repository/show_repository.dart';

abstract class GetSearchShowUseCase {
  Future<Either<Failure, List<ShowModel?>>> call(
      final List<String?> categories, final String? type);
}

class GetSearchShowUseCaseImpl implements GetSearchShowUseCase {
  final ShowRepository repository;

  GetSearchShowUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, List<ShowModel?>>> call(
      final List<String?> categories, final String? type) async {
    return repository.getSearchShow(categories, type);
  }
}
