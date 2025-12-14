import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../../data/models/show_model.dart';
import '../repositories/show_repository.dart';

abstract class AddShowUseCase {
  Future<Either<Failure, bool>> call(
      final ShowModel show, final Uri? showIdAddOrUpdateImgUrl);
}

class AddShowUseCaseImpl implements AddShowUseCase {
  final ShowRepository repository;

  AddShowUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(
      final ShowModel show, final Uri? showIdAddOrUpdateImgUrl) async {
    return repository.addShow(show, showIdAddOrUpdateImgUrl);
  }
}
