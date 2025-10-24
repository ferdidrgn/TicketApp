import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/useCase/stage/get_search_stage_use_case_impl.dart';
import '../../../domain/useCase/stage/get_stage_by_id_use_case_impl.dart';
import '../../../domain/useCase/stage/get_stages_use_case_impl.dart';
import '../../repository/stage/stage_repository_provider.dart';
import 'stage_notifier.dart';
import 'stage_state.dart';

final stageProvider =
    NotifierProvider<StageNotifier, StageState>(StageNotifier.new);

// Use case providers
final getStagesUseCaseProvider = Provider<GetStagesUseCase>(
  (final ref) => GetStagesUseCaseImpl(ref.watch(stageRepositoryProvider)),
);

final getStageByIdUseCaseProvider = Provider<GetStagesByIdsUseCase>(
  (final ref) => GetStageByIdUseCaseImpl(ref.watch(stageRepositoryProvider)),
);

final getSearchStageUseCaseProvider = Provider<GetSearchStageUseCase>(
  (final ref) => GetSearchStageUseCaseImpl(ref.watch(stageRepositoryProvider)),
);
