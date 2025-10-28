import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import 'package:ticketapp/data/providers/team/team_provider.dart';
import 'team_state.dart';

class TeamNotifier extends BaseNotifierWithNetworkChecker<TeamState> {
  @override
  TeamState initialState() => const TeamState();

  @override
  void reloadData() => loadTeams(false);

  Future<void> loadTeams(final bool isLimit) => executeWithInternetCheck(
        () => ref.read(getTeamsUseCaseProvider).call(isLimit),
        onSuccess: (final teams) => state = state.copyWith(dataList: teams),
      );

  Future<void> loadTeamsByIds(final List<String> teamsIds) =>
      executeWithInternetCheck(
        () => ref.read(getTeamByIdUseCaseProvider).call(teamsIds),
        onSuccess: (final teams) => state = state.copyWith(dataList: teams),
      );
}

extension TeamStateX on TeamState {
  /// Belirli bir takım var mı?
  bool hasTeam(final String teamId) {
    if (dataList == null) return false;
    return dataList!.any((final team) => team.id == teamId);
  }

  /// Belirli bir takımı getir
  dynamic getTeamById(final String teamId) {
    if (dataList == null) return null;
    try {
      return dataList!.firstWhere((final team) => team.id == teamId);
    } catch (_) {
      return null;
    }
  }

  /// Toplam takım sayısı
  int get teamCount => dataList?.length ?? 0;

  /// Takım listesi boş mu değil mi?
  bool get hasData => dataList != null && dataList!.isNotEmpty;

  /// Tüm takım ID'leri
  List<String> get teamIds =>
      dataList?.map((final team) => team.id).toList() ?? [];

  /// İlk takım veya null
  dynamic get firstTeam =>
      dataList?.isNotEmpty == true ? dataList!.first : null;

  /// Son takım veya null
  dynamic get lastTeam => dataList?.isNotEmpty == true ? dataList!.last : null;
}
