import '../../../domain/entities/stage.dart';

class StageState {
  final List<Stage?> stages;
  final Stage? stage;
  final bool isLoading;
  final String? errorMessage;

  StageState({
    this.stages = const [],
    this.stage,
    this.isLoading = false,
    this.errorMessage,
  });

  StageState copyWith({
    final List<Stage?>? stages,
    final Stage? stage,
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