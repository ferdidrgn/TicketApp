import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../data/repositories/stage_repository_provider.dart';
import '../../domain/entities/stage.dart';
import '../../domain/usecases/add_stage_use_case_impl.dart';
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
}
