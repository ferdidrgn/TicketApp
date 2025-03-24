import 'package:ticketapp/core/common/base_state.dart';
import 'package:ticketapp/data/model/team_model.dart';

class TeamState extends BaseState{
  final List<TeamModel?> teams;
  final TeamModel? team;

  TeamState({
    this.teams = const [],
    this.team,
    super.isLoading = false,
    super.errorMessage,
  });

  @override
  TeamState copyWith({
    final List<TeamModel?>? teams,
    final TeamModel? team,
    final bool? isLoading,
    final String? errorMessage,
  }) {
    return TeamState(
      teams: teams ?? this.teams,
      team: team ?? this.team,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}