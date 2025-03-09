import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../repository/show_repository.dart';

abstract class UpdateShowUseCase {
  Future<Either<Failure, void>> call(
      final String showId, final Map<String, dynamic> updatedData);
}

class UpdateShowUseCaseImpl implements UpdateShowUseCase {
  final ShowRepository repository;

  UpdateShowUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, void>> call(
      final String showId, final Map<String, dynamic> updatedData) async {
    return repository.updateShow(showId, updatedData);
  }
}
