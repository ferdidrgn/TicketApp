import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../events/domain/entities/event.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/providers/player_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/domain/next_session.dart';
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
  final Map<String, NextSessionHint> nextByShow;
  final bool isLoading;

  const SearchResultState({
    required this.shows,
    required this.players,
    required this.stages,
    required this.teams,
    this.nextByShow = const {},
    this.isLoading = false,
  });
}

/// Kısa sorgular yalnızca ada bakar. İki karakterden itibaren tür, adres,
/// biyografi ve açıklama da eşleşir; ad eşleşmesi her zaman önde kalır.
List<Show> filterShowsForQuery(final List<Show> shows, final String query) {
  if (query.isEmpty) return shows;
  final List<Show> byName = [];
  final List<Show> byDetail = [];
  for (final Show show in shows) {
    if (show.name.toLowerCase().contains(query)) {
      byName.add(show);
    } else if (query.length >= 2 &&
        '${show.category} ${show.type} ${show.description}'
            .toLowerCase()
            .contains(query)) {
      byDetail.add(show);
    }
  }
  return [...byName, ...byDetail];
}

List<Player> filterPlayersForQuery(
    final List<Player> players, final String query) {
  if (query.isEmpty) return players;
  final List<Player> byName = [];
  final List<Player> byDetail = [];
  for (final Player player in players) {
    final String name = '${player.firstName} ${player.lastName}'.toLowerCase();
    if (name.contains(query)) {
      byName.add(player);
    } else if (query.length >= 2 &&
        '${player.bio} ${player.quote}'.toLowerCase().contains(query)) {
      byDetail.add(player);
    }
  }
  return [...byName, ...byDetail];
}

List<Stage> filterStagesForQuery(final List<Stage> stages, final String query) {
  if (query.isEmpty) return stages;
  final List<Stage> byName = [];
  final List<Stage> byDetail = [];
  for (final Stage stage in stages) {
    if (stage.name.toLowerCase().contains(query)) {
      byName.add(stage);
    } else if (query.length >= 2 &&
        '${stage.address} ${stage.description}'.toLowerCase().contains(query)) {
      byDetail.add(stage);
    }
  }
  return [...byName, ...byDetail];
}

List<Team> filterTeamsForQuery(final List<Team> teams, final String query) {
  if (query.isEmpty) return teams;
  final List<Team> byName = [];
  final List<Team> byDetail = [];
  for (final Team team in teams) {
    if (team.name.toLowerCase().contains(query)) {
      byName.add(team);
    } else if (query.length >= 2 &&
        team.description.toLowerCase().contains(query)) {
      byDetail.add(team);
    }
  }
  return [...byName, ...byDetail];
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

  // Gösteriler (shows) için kaynak, sorgu durumuna göre değişir:
  // - Kutu boşken (göz atma / "önerilenler" hâli): kullanıcının kendi
  //   talebi ("en son yaratılan aktif oyunluğa göre filtrelemeler yap
  //   önce en yeniler ve aktifler ekrana gelsin") gereği en son eklenen
  //   oyun en üstte — bkz. `home_show_filter_provider.dart`'taki AYNI
  //   `sortShowsByCreatedAtDescending` mantığı (ana sayfayla tutarlı
  //   davranış). Hiçbir oyun listeden tamamen kaybolmaz, sadece sıra
  //   değişir.
  // - Kullanıcı bir şey yazdığında (açık arama): TÜM oyunlar aranır —
  //   geçmiş bir oyunu ismiyle arayan biri onu hâlâ bulabilmeli, sıralama
  //   burada önemsiz (query eşleşmesiyle zaten daralıyor).
  final Future<List<Show>> showsFuture;
  if (query.isEmpty) {
    showsFuture = ref.watch(showsActiveFirstProvider(false).future).then((final shows) {
      final sorted = List<Show>.of(shows);
      sortShowsByCreatedAtDescending(sorted);
      return sorted;
    });
  } else {
    showsFuture = ref.watch(showsProvider(isLimit: false).future);
  }

  // 1. ADIM: Tüm verileri paralel ve güvenli bir şekilde çek
  final results = await Future.wait<dynamic>([
    showsFuture,
    ref.watch(playersProvider(isLimit: false).future),
    ref.watch(stagesProvider(isLimit: false).future),
    ref.watch(teamsProvider(isLimit: false).future),
  ]);

  final allShows = results[0] as List<Show>;
  final allPlayers = results[1] as List<Player>;
  final allStages = results[2] as List<Stage>;
  final allTeams = results[3] as List<Team>;

  Map<String, List<Event>> eventsByShow = const {};
  try {
    eventsByShow = await ref.watch(eventsByShowMapProvider(false).future);
  } catch (_) {
    eventsByShow = const {};
  }
  final Map<String, NextSessionHint> nextByShow = {};
  eventsByShow.forEach((final String id, final List<Event> events) {
    final NextSessionHint? hint = nextSessionHint(events);
    if (hint != null) nextByShow[id] = hint;
  });

  return SearchResultState(
    isLoading: false,
    shows: (filterIndex == 0 || filterIndex == 1)
        ? filterShowsForQuery(allShows, query)
        : [],
    players: (filterIndex == 0 || filterIndex == 2)
        ? filterPlayersForQuery(allPlayers, query)
        : [],
    stages: (filterIndex == 0 || filterIndex == 3)
        ? filterStagesForQuery(allStages, query)
        : [],
    teams: (filterIndex == 0 || filterIndex == 4)
        ? filterTeamsForQuery(allTeams, query)
        : [],
    nextByShow: nextByShow,
  );
}
