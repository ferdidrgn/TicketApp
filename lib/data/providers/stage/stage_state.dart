import '../../../core/common/base_state.dart';
import '../../../domain/entities/stage.dart';

class StageState extends BaseState {
  List<Stage>? stages;
  Stage? stage;

  StageState({
    this.stages = const [],
    this.stage,
    super.isLoading,
    super.errorMessage,
  });

  @override
  StageState copyWith({
    List<Stage>? stages,
    Stage? stage,
    bool? isLoading,
    String? errorMessage,
  }) {
    return StageState(
      stages: stages ?? this.stages,
      stage: stage ?? this.stage,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
