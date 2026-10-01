import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/stage.dart';
import '../repositories/stage_repository.dart';

abstract class AddStageUseCase {
  Future<Either<Failure, bool>> call(final Stage stage, final File? imageFile);
}

class AddStageUseCaseImpl implements AddStageUseCase {
  final StageRepository repository;

  AddStageUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(
          final Stage stage, final File? imageFile) async =>
      repository.addStage(stage, imageFile);
}
