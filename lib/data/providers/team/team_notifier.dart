import 'package:ticketapp/core/common/base_notifier.dart';
import '../../../domain/useCase/team/get_team_by_id_use_case_impl.dart';
import '../../../domain/useCase/team/get_teams_use_case_impl.dart';
import 'team_state.dart';

class TeamNotifier extends BaseNotifier<TeamState> {
  final GetTeamsUseCase getTeamsUseCase;
  final GetTeamByIdUseCase getTeamByIdUseCase;

  TeamNotifier(this.getTeamsUseCase, this.getTeamByIdUseCase)
      : super(TeamState());

  Future<void> loadTeams(final isLimit) async {
    await handleOperation(() => getTeamsUseCase.call(isLimit),
        onSuccess: (final teams) => state = state.copyWith(dataList: teams));
  }

  Future<void> loadTeamsByIds(final List<String> teamsIds) async {
    await handleOperation(() => getTeamByIdUseCase.call(teamsIds),
        onSuccess: (final teams) => state = state.copyWith(dataList: teams));
  }
}
