import 'package:ticketapp/core/common/base_notifier_with_base_state.dart';
import '../../../domain/useCase/stage/get_search_stage_use_case_impl.dart';
import '../../../domain/useCase/stage/get_stage_by_id_use_case_impl.dart';
import '../../../domain/useCase/stage/get_stages_use_case_impl.dart';
import 'stage_state.dart';

class StageNotifier extends BaseNotifierWithBaseState<StageState> {
  final GetStagesUseCase getStagesUseCase;
  final GetStagesByIdsUseCase getStagesByIdsUseCase;
  final GetSearchStageUseCase getSearchStageUseCase;

  StageNotifier(this.getStagesUseCase, this.getStagesByIdsUseCase,
      this.getSearchStageUseCase)
      : super(StageState());

  Future<void> loadStages(final isLimit) async {
    await handleOperation(
      () => getStagesUseCase.call(isLimit),
      onSuccess: (final stages) =>
          state = state.copyWith(dataList: stages),
    );
  }

  Future<void> loadStagesByIds(final List<String> stageIds) async {
    await handleOperation(
      () => getStagesByIdsUseCase.call(stageIds),
      onSuccess: (final stages) =>
          state = state.copyWith(dataList: stages),
    );
  }

  Future<void> searchStage(final String query) async {
    await handleOperation(
      () => getSearchStageUseCase.call(query),
      onSuccess: (final stages) =>
          state = state.copyWith(dataList: stages),
    );
  }
}
