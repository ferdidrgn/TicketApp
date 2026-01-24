import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../../core/errors/failures.dart';
import '../entities/show.dart';
import '../repositories/show_repository.dart';

abstract class AddShowUseCase {
  Future<Either<Failure, bool>> call(
      final Show show, final File? showIdAddOrUpdateImgUrl);
}

class AddShowUseCaseImpl implements AddShowUseCase {
  final ShowRepository repository;

  AddShowUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(
          final Show show, final File? showIdAddOrUpdateImgUrl) async =>
      repository.addShow(show, showIdAddOrUpdateImgUrl);
}
