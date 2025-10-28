import '../../../core/common/base_loadable_state.dart';
import '../../../domain/entities/team.dart';

class TeamState extends LoadableState<Team, List<Team>> {
  const TeamState({
    super.dataList,
    super.dataSingle,
    super.isLoading = false,
    super.errorMessage,
  });

  @override
  TeamState copyWith({
    final Team? dataSingle,
    final List<Team>? dataList,
    final bool? isLoading,
    final String? errorMessage,
  }) =>
      TeamState(
        dataSingle: dataSingle ?? dataSingle,
        dataList: dataList ?? this.dataList,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}
