import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/stage_repository.dart';

abstract class UpdateStageUseCase {
  Future<Either<Failure, bool>> call(final String stageId,
      final Map<String, dynamic> updatedData, final File? imageFile);
}

class UpdateStageUseCaseImpl implements UpdateStageUseCase {
  final StageRepository repository;

  UpdateStageUseCaseImpl(this.repository);

  @override
  Future<Either<Failure, bool>> call(final String stageId,
          final Map<String, dynamic> updatedData, final File? imageFile) async =>
      repository.updateStage(stageId, updatedData, imageFile);
}
