import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../data/model/show_model.dart';
import '../../repository/show_repository.dart';

abstract class AddShowUseCase {
  Future<Either<Failure, void>> call(
      final ShowModel show, final Uri? showIdAddOrUpdateImgUrl);
}

class AddShowUseCaseImpl implements AddShowUseCase {
  final ShowRepository repository;

  AddShowUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, void>> call(
      final ShowModel show, final Uri? showIdAddOrUpdateImgUrl) async {
    return repository.addShow(show, showIdAddOrUpdateImgUrl);
  }
}
