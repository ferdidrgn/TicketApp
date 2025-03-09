import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/stage.dart';
import '../../../domain/useCase/stage/get_search_stage_use_case_impl.dart';
import '../../../domain/useCase/stage/get_stage_by_id_use_case_impl.dart';
import '../../../domain/useCase/stage/get_stages_use_case_impl.dart';
import 'stage_state.dart';

class StageNotifier extends StateNotifier<StageState> {
  final GetStagesUseCase getStagesUseCase;
  final GetStageByIdUseCase getStageByIdUseCase;
  final GetSearchStageUseCase getSearchStageUseCase;

  StageNotifier(this.getStagesUseCase, this.getStageByIdUseCase, this.getSearchStageUseCase)
      : super(StageState());

  Future<void> loadStages(final isLimit) async {
    _setLoadingState(true);
    final result = await getStagesUseCase.call(isLimit);

    result.fold(
          (final failure) => _setErrorState(failure.message),
          (final stages) {
        final convertedStages = stages.map((final stage) => stage?.toEntity()).toList();
        _setStagesState(convertedStages);
      },
    );
  }

  Future<void> loadStageById(final String stageId) async {
    _setLoadingState(true);
    final result = await getStageByIdUseCase.call(stageId);

    result.fold(
          (final failure) => _setErrorState(failure.message),
          (final stage) => _setStageState(stage?.toEntity()),
    );
  }

  Future<void> searchStage(final String query) async {
    _setLoadingState(true);
    final result = await getSearchStageUseCase.call(query);

    result.fold(
          (final failure) => _setErrorState(failure.message),
          (final stages) {
        final convertedStages = stages.map((final stage) => stage?.toEntity()).toList();
        _setStagesState(convertedStages);
      },
    );
  }

  void _setLoadingState(final bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void _setErrorState(final String errorMessage) {
    state = state.copyWith(errorMessage: errorMessage, isLoading: false);
  }

  void _setStagesState(final List<Stage?> stages) {
    state = state.copyWith(stages: stages, isLoading: false);
  }

  void _setStageState(final Stage? stage) {
    state = state.copyWith(stage: stage, isLoading: false);
  }
}
