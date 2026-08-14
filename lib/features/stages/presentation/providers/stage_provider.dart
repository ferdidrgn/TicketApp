import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/failures.dart';
import '../../data/repositories/stage_repository_provider.dart';
import '../../domain/entities/stage.dart';
import '../../domain/usecases/get_search_stage_use_case_impl.dart';
import '../../domain/usecases/get_stage_by_id_use_case_impl.dart';
import '../../domain/usecases/get_stages_use_case_impl.dart';

part 'stage_provider.g.dart';

// ==============================================================================
// 1. USE CASE PROVIDERS (Dependency Injection)
// ==============================================================================

@riverpod
GetStagesUseCase getStagesUseCase(final Ref ref) =>
    GetStagesUseCaseImpl(ref.watch(stageRepositoryProvider));

@riverpod
GetStagesByIdsUseCase getStageByIdUseCase(final Ref ref) =>
    GetStageByIdUseCaseImpl(ref.watch(stageRepositoryProvider));

@riverpod
GetSearchStageUseCase getSearchStageUseCase(final Ref ref) =>
    GetSearchStageUseCaseImpl(ref.watch(stageRepositoryProvider));

// ==============================================================================
// 2. DATA PROVIDERS (READ ONLY)
// ==============================================================================

/// 🔥 TÜM SAHNELERİ ÇEKER
/// Kullanım: ref.watch(stagesProvider)
@riverpod
Future<List<Stage>> stages(final Ref ref,
        {required final bool isLimit}) async =>
    ref.watch(getStagesUseCaseProvider).call(isLimit).getOrThrow();

/// 🆔 ID LİSTESİNE GÖRE SAHNELERİ ÇEKER
/// Kullanım: ref.watch(stagesByIdsProvider(['id1', 'id2']))
@riverpod
Future<List<Stage>> stagesByIds(final Ref ref, final List<String> ids) async {
  if (ids.isEmpty) return [];
  return ref.watch(getStageByIdUseCaseProvider).call(ids).getOrThrow();
}

/// 🔍 SAHNE ARAMA (Manuel Tetiklenen State)
/// Arama sonuçlarını tutmak için bir Notifier kullanıyoruz.
@riverpod
class StageSearch extends _$StageSearch {
  @override
  FutureOr<List<Stage>> build() => [];

  Future<void> search(final String query) async {
    if (query.isEmpty) {
      state = const AsyncData([]);
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async =>
        ref.read(getSearchStageUseCaseProvider).call(query).getOrThrow());
  }
}

// ==============================================================================
// 3. UI HELPERS (Eski Extension Metotlarının Modern Hali)
// ==============================================================================

extension StageListX on List<Stage> {
  /// Belirli bir ID'ye sahip sahneyi bulur
  Stage? findById(final String id) {
    try {
      return firstWhere((final element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Tüm sahne ID'lerini liste olarak döner
  List<String> get allIds => map((final e) => e.id).toList();
}
