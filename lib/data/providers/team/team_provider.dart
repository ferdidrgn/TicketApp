import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/useCase/team/get_team_by_id_use_case_impl.dart';
import '../../../domain/useCase/team/get_teams_use_case_impl.dart';
import '../../repository/team/team_repository_provider.dart';
import 'team_notifier.dart';
import 'team_state.dart';

final teamProvider =
    NotifierProvider.autoDispose<TeamNotifier, TeamState>(TeamNotifier.new);

// Use case providers
final getTeamsUseCaseProvider = Provider<GetTeamsUseCase>(
  (final ref) => GetTeamsUseCaseImpl(ref.watch(teamRepositoryProvider)),
);

final getTeamByIdUseCaseProvider = Provider<GetTeamByIdUseCase>(
  (final ref) => GetTeamByIdUseCaseImpl(ref.watch(teamRepositoryProvider)),
);
