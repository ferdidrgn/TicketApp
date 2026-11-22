import '../../domain/entities/team_manager_entities.dart';
import '../../domain/repositories/team_repository.dart';
import '../datasources/team_remote_data_source.dart';

class TeamRepositoryImpl implements TeamRepository {
  final TeamRemoteDataSource _remote;

  TeamRepositoryImpl(this._remote);

  @override
  Future<List<TeamManagerTeam>> getMyManagedTeams() async {
    try {
      final json = await _remote.getMyManagedTeams();
      final teams = (json['teams'] as List?) ?? const [];
      return teams
          .map((final e) => TeamManagerTeam.fromJson(e as Map))
          .toList();
    } catch (e) {
      throw mapTeamError(e);
    }
  }

  @override
  Future<NotifyPreview> notifyPreview({
    required final String eventId,
    final String? template,
    final Map<String, int>? params,
    final String? title,
    final String? body,
  }) async {
    try {
      final json = await _remote.teamNotifyPreview({
        'target': {'type': 'event', 'id': eventId},
        if (template != null) 'template': template,
        if (params != null) 'params': params,
        if (title != null) 'title': title,
        if (body != null) 'body': body,
      });
      return NotifyPreview.fromJson(json);
    } catch (e) {
      throw mapTeamError(e);
    }
  }

  @override
  Future<NotifySendResult> sendNotification({
    required final String eventId,
    required final String requestId,
    final String? template,
    final Map<String, int>? params,
    final String? title,
    final String? body,
  }) async {
    try {
      final json = await _remote.teamSendNotification({
        'target': {'type': 'event', 'id': eventId},
        if (template != null) 'template': template,
        if (params != null) 'params': params,
        if (title != null) 'title': title,
        if (body != null) 'body': body,
        'confirm': true,
        'requestId': requestId,
      });
      return NotifySendResult.fromJson(json);
    } catch (e) {
      throw mapTeamError(e);
    }
  }

  @override
  Future<List<TeamStatsShow>> getTeamStats({final String? teamId}) async {
    try {
      final json = await _remote.teamStats({
        if (teamId != null) 'teamId': teamId,
      });
      final shows = (json['shows'] as List?) ?? const [];
      return shows
          .map((final e) => TeamStatsShow.fromJson(e as Map))
          .toList();
    } catch (e) {
      throw mapTeamError(e);
    }
  }
}
