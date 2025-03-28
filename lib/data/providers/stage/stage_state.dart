import '../../../core/common/base_loadable_state.dart';
import '../../../domain/entities/stage.dart';

class StageState extends LoadableState<Stage, List<Stage>> {
  const StageState({
    final Stage? stage,
    final List<Stage>? stages,
    super.isLoading,
    super.errorMessage,
  }) : super(dataSingle: stage, dataList: stages);

  @override
  StageState copyWith({
    final Stage? dataSingle,
    final List<Stage>? dataList,
    final bool? isLoading,
    final String? errorMessage,
  }) {
    return StageState(
      stage: dataSingle ?? this.dataSingle,
      stages: dataList ?? this.dataList,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
