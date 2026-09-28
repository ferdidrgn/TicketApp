import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/stage.dart';

abstract class StageRepository {
  Future<Either<Failure, List<Stage>>> getSearchStage(final String query);
  Future<Either<Failure, List<Stage>>> getStages(final bool isLimit);
  Future<Either<Failure, List<Stage>>> getStagesByIds(final List<String> stagesIds);

  /// ➕ Admin panelinden yeni bir sahne (mekân) oluşturur.
  Future<Either<Failure, bool>> addStage(final Stage stage, final File? imageFile);
}
