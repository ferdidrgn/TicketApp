import 'package:ticketapp/data/model/team_model.dart';

class TeamState {
  final List<TeamModel?> teams;
  final TeamModel? team;
  final bool isLoading;
  final String? errorMessage;

  TeamState({
    this.teams = const [],
    this.team,
    this.isLoading = false,
    this.errorMessage,
  });

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