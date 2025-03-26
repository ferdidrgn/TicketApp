import 'package:ticketapp/core/common/base_state.dart';
import '../../../domain/entities/team.dart';

class TeamState extends BaseState{
  List<Team>? teams;
  Team? team;

  TeamState({
    this.teams = const [],
    this.team,
    super.isLoading = false,
    super.errorMessage,
  });

  @override
  TeamState copyWith({
    List<Team>? teams,
    Team? team,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TeamState(
      teams: teams ?? this.teams,
      team: team ?? this.team,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}