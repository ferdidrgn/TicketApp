import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/internet_service_provider.dart';
import '../../../domain/useCase/team/get_team_by_id_use_case_impl.dart';
import '../../../domain/useCase/team/get_teams_use_case_impl.dart';
import '../../repository/team/team_repository_provider.dart';
import 'team_notifier.dart';
import 'team_state.dart';

final teamProvider =
    StateNotifierProvider<TeamNotifier, TeamState>((final ref) {
  return TeamNotifier(
    ref.read(internetServiceProvider),
    ref.watch(getTeamsUseCaseProvider),
    ref.watch(getTeamByIdUseCaseProvider),
  );
});

// Use case providers
final getTeamsUseCaseProvider = Provider<GetTeamsUseCase>((final ref) {
  final repository = ref.watch(teamRepositoryProvider);
  return GetTeamsUseCaseImpl(repository);
});

final getTeamByIdUseCaseProvider = Provider<GetTeamByIdUseCase>((final ref) {
  final repository = ref.watch(teamRepositoryProvider);
  return GetTeamByIdUseCaseImpl(repository);
});
