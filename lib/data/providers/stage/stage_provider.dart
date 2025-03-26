import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/useCase/stage/get_search_stage_use_case_impl.dart';
import '../../../domain/useCase/stage/get_stage_by_id_use_case_impl.dart';
import '../../../domain/useCase/stage/get_stages_use_case_impl.dart';
import '../../repository/stage/stage_repository_provider.dart';
import 'stage_notifier.dart';
import 'stage_state.dart';

final stageProvider =
    StateNotifierProvider<StageNotifier, StageState>(( ref) {
  return StageNotifier(
    ref.watch(getStagesUseCaseProvider),
    ref.watch(getStageByIdUseCaseProvider),
    ref.watch(getSearchStageUseCaseProvider),
  );
});

// Use case providers
final getStagesUseCaseProvider = Provider<GetStagesUseCase>(( ref) {
  final repository = ref.watch(stageRepositoryProvider);
  return GetStagesUseCaseImpl(repository);
});

final getStageByIdUseCaseProvider = Provider<GetStagesByIdsUseCase>(( ref) {
  final repository = ref.watch(stageRepositoryProvider);
  return GetStageByIdUseCaseImpl(repository);
});

final getSearchStageUseCaseProvider =
    Provider<GetSearchStageUseCase>(( ref) {
  final repository = ref.watch(stageRepositoryProvider);
  return GetSearchStageUseCaseImpl(repository);
});
