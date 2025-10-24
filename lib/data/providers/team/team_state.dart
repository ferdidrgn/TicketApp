import '../../../core/common/base_loadable_state.dart';
import '../../../domain/entities/team.dart';

class TeamState extends LoadableState<Team, List<Team>> {
  const TeamState({
    final List<Team>? teams,
    final Team? team,
    super.isLoading = false,
    super.errorMessage,
  }) : super(dataSingle: team, dataList: teams);

  @override
  TeamState copyWith({
    final Team? dataSingle,
    final List<Team>? dataList,
    final bool? isLoading,
    final String? errorMessage,
  }) =>
      TeamState(
        team: dataSingle ?? dataSingle,
        teams: dataList ?? this.dataList,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}
