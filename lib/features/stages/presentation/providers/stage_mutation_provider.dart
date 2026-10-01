import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../data/repositories/stage_repository_provider.dart';
import '../../domain/entities/stage.dart';
import '../../domain/usecases/add_stage_use_case_impl.dart';
import '../../domain/usecases/delete_stage_use_case_impl.dart';
import '../../domain/usecases/update_stage_use_case_impl.dart';
import 'stage_provider.dart';

// 🔧 KODLAMA NOTU: `stage_provider.dart` zaten `@riverpod` codegen
// kullanıyor ve eşleşen `stage_provider.g.dart`'ı var — build_runner bu
// sandbox'ta çalışmadığı için o dosyaya yeni bir `@riverpod` provider
// EKLENEMEZ (CLAUDE.md). Bu YENİ mutation (yazma) provider'ı, tıpkı
// `event_mutation_provider.dart`/`theme_notifier.dart`'taki gibi klasik/
// codegen'siz `Notifier`+`NotifierProvider` API'siyle ayrı bir dosyada
// tanımlandı.

final addStageUseCaseProvider = Provider<AddStageUseCase>(
    (final ref) => AddStageUseCaseImpl(ref.watch(stageRepositoryProvider)));

final updateStageUseCaseProvider = Provider<UpdateStageUseCase>((final ref) =>
    UpdateStageUseCaseImpl(ref.watch(stageRepositoryProvider)));

final deleteStageUseCaseProvider = Provider<DeleteStageUseCase>((final ref) =>
    DeleteStageUseCaseImpl(ref.watch(stageRepositoryProvider)));

final stageMutationProvider =
    NotifierProvider<StageMutationNotifier, AsyncValue<void>>(
        StageMutationNotifier.new);

class StageMutationNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// ➕ Admin panelinden yeni bir sahne (mekân) ekler.
  Future<void> addStage(final Stage stage, final File? imageFile) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(addStageUseCaseProvider)
          .call(stage, imageFile)
          .getOrThrow();
      ref.invalidate(stagesProvider);
    });
  }

  /// 🔄 Admin panelinden bir sahneyi (Phase 2: edit) günceller.
  Future<void> updateStage({
    required final String stageId,
    required final Map<String, dynamic> updatedData,
    final File? imageFile,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(updateStageUseCaseProvider)
          .call(stageId, updatedData, imageFile)
          .getOrThrow();
      ref.invalidate(stagesProvider);
      ref.invalidate(stagesByIdsProvider);
    });
  }

  /// 🗑️ Admin panelinden bir sahneyi (Phase 2) siler.
  Future<void> deleteStage(final String stageId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(deleteStageUseCaseProvider).call(stageId).getOrThrow();
      ref.invalidate(stagesProvider);
    });
  }
}
