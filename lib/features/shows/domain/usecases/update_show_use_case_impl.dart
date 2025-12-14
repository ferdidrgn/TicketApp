import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/show_repository.dart';

abstract class UpdateShowUseCase {
  Future<Either<Failure, bool>> call(
      final String showId, final Map<String, dynamic> updatedData);
}

class UpdateShowUseCaseImpl implements UpdateShowUseCase {
  final ShowRepository repository;

  UpdateShowUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(
          final String showId, final Map<String, dynamic> updatedData) async =>
      repository.updateShow(showId, updatedData);
}
