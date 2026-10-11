import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/stage.dart';

abstract class StageRepository {
  Future<Either<Failure, List<Stage>>> getSearchStage(final String query);
  Future<Either<Failure, List<Stage>>> getStages(final bool isLimit);
  Future<Either<Failure, List<Stage>>> getStagesByIds(final List<String> stagesIds);

  /// `getStagesByIds` ile aynı sorgular; anahtar = istenen stageId
  /// (`documentId` veya alan `_id` alias). Değerde `Stage.id` her zaman
  /// Firestore doc id’dir.
  Future<Either<Failure, Map<String, Stage>>> resolveStagesByIds(
      final List<String> stageIds);

  /// Verilen oyun ID’lerinden en az birini `showsId` içinde tutan sahneler.
  Future<Either<Failure, List<Stage>>> getStagesByShowIds(
      final List<String> showIds);

  /// ➕ Admin panelinden yeni bir sahne (mekân) oluşturur.
  Future<Either<Failure, bool>> addStage(final Stage stage, final File? imageFile);

  /// 🔄 Admin panelinden bir sahneyi günceller (Phase 2). `imageFile`
  /// verilirse görsel `addStage` ile AYNI Storage yoluna yeniden yüklenir.
  Future<Either<Failure, bool>> updateStage(final String stageId,
      final Map<String, dynamic> updatedData, final File? imageFile);

  /// 🗑️ Admin panelinden bir sahneyi siler (Phase 2).
  Future<Either<Failure, bool>> deleteStage(final String stageId);
}
