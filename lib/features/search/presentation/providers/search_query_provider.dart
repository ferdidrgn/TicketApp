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

/// 🔥 MERKEZİ ARAMA MANTIĞI
@riverpod
SearchResultState searchResult(final Ref ref) {
  final query = ref.watch(searchQueryProvider);
  final filterIndex = ref.watch(searchFilterProvider);

  // 🔥 Riverpod Generator ile oluşturulan provider'lar AsyncValue döner.
  final showsAsync = ref.watch(showsProvider(isLimit: false));
  final playersAsync = ref.watch(playersProvider(isLimit: false));
  final stagesAsync = ref.watch(stagesProvider(isLimit: false));
  final teamsAsync = ref.watch(teamsProvider(isLimit: false));

  // isLoading durumunu AsyncValue'ların kendi durumundan alıyoruz.
  final bool isLoading = showsAsync.isLoading ||
      playersAsync.isLoading ||
      stagesAsync.isLoading ||
      teamsAsync.isLoading;

  // valueOrNull hatasını gidermek için .value kullanıyoruz.
  // .value, veri varsa veriyi yoksa (veya yükleniyorsa) null döner.
  final shows = showsAsync.value ?? [];
  final players = playersAsync.value ?? [];
  final stages = stagesAsync.value ?? [];
  final teams = teamsAsync.value ?? [];

  // Filtreleme Fonksiyonu
  List<T> filterItems<T>(
      final List<T> items, final String Function(T) selector) {
    if (query.isEmpty) return items;
    return items
        .where((final i) => selector(i).toLowerCase().contains(query))
        .toList();
  }

  return SearchResultState(
    isLoading: isLoading,
    shows: (filterIndex == 0 || filterIndex == 1)
        ? filterItems<Show>(shows, (final s) => s.name)
        : [],
    players: (filterIndex == 0 || filterIndex == 2)
        ? filterItems<Player>(
            players, (final p) => '${p.firstName} ${p.lastName}')
        : [],
    stages: (filterIndex == 0 || filterIndex == 3)
        ? filterItems<Stage>(stages, (final s) => s.name)
        : [],
    teams: (filterIndex == 0 || filterIndex == 4)
        ? filterItems<Team>(teams, (final t) => t.name)
        : [],
  );
}
