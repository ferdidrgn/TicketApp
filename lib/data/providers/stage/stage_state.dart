import 'package:ticketapp/data/model/stage_model.dart';

import '../../../core/common/base_state.dart';

class StageState extends BaseState {
  final List<StageModel?> stages;
  final StageModel? stage;

  StageState({
    this.stages = const [],
    this.stage,
    super.isLoading,
    super.errorMessage,
  });

  @override
  StageState copyWith({
    final List<StageModel?>? stages,
    final StageModel? stage,
    final bool? isLoading,
    final String? errorMessage,
  }) {
    return StageState(
      stages: stages ?? this.stages,
      stage: stage ?? this.stage,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
