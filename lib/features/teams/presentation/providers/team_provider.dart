import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/failures.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../data/repositories/team_repository_provider.dart';
import '../../domain/entities/team.dart';
import '../../domain/usecases/get_team_by_id_use_case_impl.dart';
import '../../domain/usecases/get_teams_use_case_impl.dart';

part 'team_provider.g.dart';

// ==============================================================================
// USE CASE PROVIDERS (Dependency Injection)
// ==============================================================================

@riverpod
GetTeamsUseCase getTeamsUseCase(final Ref ref) =>
    GetTeamsUseCaseImpl(ref.watch(teamRepositoryProvider));

@riverpod
GetTeamByIdUseCase getTeamByIdUseCase(final Ref ref) =>
    GetTeamByIdUseCaseImpl(ref.watch(teamRepositoryProvider));

// ==============================================================================
// DATA PROVIDERS (READ ONLY)
// ==============================================================================

/// 🔥 TÜM TAKIMLARI ÇEKER
/// Parametre: isLimit (bool) -> true ise son 20 kaydı getirir.
@riverpod
Future<List<Team>> teams(final Ref ref, {required final bool isLimit}) async =>
    ref.watch(getTeamsUseCaseProvider).call(isLimit).getOrThrow();

/// 🆔 TEK BİR TAKIM VE DETAYLARINI ÇEKER (Composite)
/// Bu provider, bir takımın kendisini ve ilişkili gösterilerini (Show) paketler.
@riverpod
Future<TeamDetailState> teamDetail(final Ref ref, final String teamId) async {
  // 1. Takımı Çek
  final teams =
      await ref.watch(getTeamByIdUseCaseProvider).call([teamId]).getOrThrow();
  if (teams.isEmpty) throw Exception('Takım bulunamadı');
  final team = teams.first;

  // 2. İlişkili Gösterileri (Shows) Çek
  // Boş stringleri filtrele
  final showIds = team.showsId.where((final id) => id.isNotEmpty).toList();

  final shows = showIds.isNotEmpty
      ? await ref.watch(showsByIdsProvider(showIds).future)
      : <Show>[];

  return TeamDetailState(team: team, shows: shows);
}

/// UI Model: Takım ve Gösterileri bir arada tutar
class TeamDetailState {
  final Team team;
  final List<Show> shows;

  const TeamDetailState({required this.team, required this.shows});
}
