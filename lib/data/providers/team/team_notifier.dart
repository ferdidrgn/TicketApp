import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import '../../../core/network/internet_service.dart';
import '../../../domain/useCase/team/get_team_by_id_use_case_impl.dart';
import '../../../domain/useCase/team/get_teams_use_case_impl.dart';
import 'team_state.dart';

class TeamNotifier extends BaseNotifierWithNetworkChecker<TeamState> {
  final GetTeamsUseCase _getTeamsUseCase;
  final GetTeamByIdUseCase _getTeamByIdUseCase;

  TeamNotifier(
    final InternetService internetService,
    this._getTeamsUseCase,
    this._getTeamByIdUseCase,
  ) : super(internetService, const TeamState());

  @override
  void reloadData() => loadTeams(false);

  Future<void> loadTeams(final isLimit) => executeWithInternetCheck(
        () => _getTeamsUseCase.call(isLimit),
        onSuccess: (final teams) => state = state.copyWith(dataList: teams),
      );

  Future<void> loadTeamsByIds(final List<String> teamsIds) =>
      executeWithInternetCheck(
        () => _getTeamByIdUseCase.call(teamsIds),
        onSuccess: (final teams) => state = state.copyWith(dataList: teams),
      );
}
