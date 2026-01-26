import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/providers/player_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/team_provider.dart';

part 'search_query_provider.g.dart';

// --- STATE MODEL ---
class SearchResultState {
  final List<Show> shows;
  final List<Player> players;
  final List<Stage> stages;
  final List<Team> teams;
  final bool isLoading;

  const SearchResultState({
    required this.shows,
    required this.players,
    required this.stages,
    required this.teams,
    this.isLoading = false,
  });
}

@riverpod
class SearchFilter extends _$SearchFilter {
  @override
  // 0: Tümü, 1: Etkinlikler, 2: Oyuncular, 3: Mekanlar, 4: Ekipler
  int build() => 0;

  void setFilter(final int index) => state = index;
}

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void update(final String query) => state = query.toLowerCase();
}

@riverpod
Future<SearchResultState> searchResult(final Ref ref) async {
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final filterIndex = ref.watch(searchFilterProvider);

  // 1. ADIM: Tüm verileri paralel ve güvenli bir şekilde çek
  final results = await Future.wait<dynamic>([
    ref.watch(showsProvider(isLimit: false).future),
    ref.watch(playersProvider(isLimit: false).future),
    ref.watch(stagesProvider(isLimit: false).future),
    ref.watch(teamsProvider(isLimit: false).future),
  ]);

  final allShows = results[0] as List<Show>;
  final allPlayers = results[1] as List<Player>;
  final allStages = results[2] as List<Stage>;
  final allTeams = results[3] as List<Team>;

  // 2. ADIM: Gerçek Filtreleme Mantığı (Arama kutusu doluysa)
  List<T> applyFilter<T>(
      final List<T> items, final String Function(T) searchField) {
    if (query.isEmpty) return items;
    return items
        .where((final item) => searchField(item).toLowerCase().contains(query))
        .toList();
  }

  // 3. ADIM: Sonuçları Paketle
  return SearchResultState(
    isLoading: false,
    shows: (filterIndex == 0 || filterIndex == 1)
        ? applyFilter(allShows, (final s) => s.name)
        : [],
    players: (filterIndex == 0 || filterIndex == 2)
        ? applyFilter(allPlayers, (final p) => "${p.firstName} ${p.lastName}")
        : [],
    stages: (filterIndex == 0 || filterIndex == 3)
        ? applyFilter(allStages, (final s) => s.name)
        : [],
    teams: (filterIndex == 0 || filterIndex == 4)
        ? applyFilter(allTeams, (final t) => t.name)
        : [],
  );
}
