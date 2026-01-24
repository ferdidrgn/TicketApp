import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/domain/entities/player.dart' as entity;
import '../../../players/presentation/providers/player_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/team_provider.dart';

part 'search_provider.g.dart';

/// Arama Sayfası State Modeli
class SearchResultState {
  final List<Show> shows;
  final List<entity.Player> players;
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
  int build() =>
      0; // 0: Tümü, 1: Etkinlikler, 2: Oyuncular, 3: Mekanlar, 4: Ekipler
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

  // Tüm veri kaynaklarını izle
  final shows = ref.watch(showProvider).dataList ?? [];
  final players = ref.watch(playerProvider).dataList ?? [];
  final stages = ref.watch(stageProvider).dataList ?? [];
  final teams = ref.watch(teamProvider).dataList ?? [];

  final isLoading =
      ref.watch(showProvider).isLoading || ref.watch(playerProvider).isLoading;

  // Filtreleme Fonksiyonu
  List<T> filterItems<T>(
      final List<T> items, final String Function(T) nameSelector) {
    if (query.isEmpty) return items;
    return items
        .where((final i) => nameSelector(i).toLowerCase().contains(query))
        .toList();
  }

  return SearchResultState(
    isLoading: isLoading,
    shows: filterIndex == 0 || filterIndex == 1
        ? filterItems(shows, (final s) => s.name)
        : [],
    players: filterIndex == 0 || filterIndex == 2
        ? filterItems(players, (final p) => '${p.firstName} ${p.lastName}')
        : [],
    stages: filterIndex == 0 || filterIndex == 3
        ? filterItems(stages, (final s) => s.name)
        : [],
    teams: filterIndex == 0 || filterIndex == 4
        ? filterItems(teams, (final t) => t.name)
        : [],
  );
}
