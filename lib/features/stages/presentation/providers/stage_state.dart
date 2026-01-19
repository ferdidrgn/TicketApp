import '../../../../core/base/base_loadable_state.dart';
import '../../domain/entities/stage.dart';

class StageState extends LoadableState<Stage, List<Stage>> {
  const StageState({
    super.dataList,
    super.dataSingle,
    super.isLoading,
    super.errorMessage,
  });

  @override
  StageState copyWith({
    final Stage? dataSingle,
    final List<Stage>? dataList,
    final bool? isLoading,
    final String? errorMessage,
  }) =>
      StageState(
        dataSingle: dataSingle ?? this.dataSingle,
        dataList: dataList ?? this.dataList,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}
