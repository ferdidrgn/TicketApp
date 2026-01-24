import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Entity Importları (Dosya yollarınızın doğruluğundan emin olun)
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/providers/player_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../../../teams/domain/entities/team.dart';
import '../../../teams/presentation/providers/team_provider.dart';

part 'search_query_provider.g.dart';

// =============================================================================
// 1. STATE MODEL
// =============================================================================

class SearchResultState {
  final List<Show> shows;
  final List<Player> players;
  final List<Stage> stages;
  final List<Team> teams;
  final bool isLoading;

  const SearchResultState({
    this.shows = const [],
    this.players = const [],
    this.stages = const [],
    this.teams = const [],
    this.isLoading = false,
  });
}

// =============================================================================
// 2. CONTROLLER PROVIDERS
// =============================================================================

@riverpod
class SearchFilter extends _$SearchFilter {
  @override
  int build() =>
      0; // 0: Tümü, 1: Etkinlikler, 2: Oyuncular, 3: Mekanlar, 4: Ekipler

  void setFilter(int index) => state = index;
}

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void update(String query) => state = query.toLowerCase();
}

// =============================================================================
// 3. MAIN LOGIC PROVIDER
// =============================================================================

@riverpod
SearchResultState searchResult(Ref ref) {
  final query = ref.watch(searchQueryProvider);
  final filterIndex = ref.watch(searchFilterProvider);

  // 1. Veri Kaynaklarını İzle (Provider isimlerinize dikkat edin!)
  // Not: Eğer 'showsProvider' parametre alıyorsa (örn: isLimit), buraya ekleyin.
  // Burada 'showProvider' vb. isimlerin projenizdeki generated isimlerle (örn: showsProvider)
  // aynı olduğundan emin olun. Genelde 'showsProvider(isLimit: false)' gibi kullanılır.

  // Örnek: Eğer providerlarınız FutureProvider ise:
  final showsAsync = ref.watch(showsProvider(isLimit: false));
  final playersAsync =
      ref.watch(playersProvider(isLimit: false)); // Parametre varsa ekleyin
  final stagesAsync = ref.watch(stagesProvider(isLimit: false));
  final teamsAsync = ref.watch(teamsProvider(isLimit: false));

  // 2. Yüklenme Durumunu Kontrol Et
  final bool isLoading = showsAsync.isLoading ||
      playersAsync.isLoading ||
      stagesAsync.isLoading ||
      teamsAsync.isLoading;

  // 3. Verileri Güvenli Şekilde Al (Null ise boş liste)
  final shows = showsAsync.valueOrNull ?? [];
  final players = playersAsync.valueOrNull ?? [];
  final stages = stagesAsync.valueOrNull ?? [];
  final teams = teamsAsync.valueOrNull ?? [];

  // 4. Filtreleme Yardımcı Fonksiyonu
  List<T> filterItems<T>(List<T> items, String Function(T) selector) {
    if (query.isEmpty) return items;
    return items
        .where((i) => selector(i).toLowerCase().contains(query))
        .toList();
  }

  // 5. Sonuçları Döndür
  return SearchResultState(
    isLoading: isLoading,
    shows: (filterIndex == 0 || filterIndex == 1)
        ? filterItems<Show>(shows, (s) => s.name)
        : [],
    players: (filterIndex == 0 || filterIndex == 2)
        ? filterItems<Player>(players, (p) => '${p.firstName} ${p.lastName}')
        : [],
    stages: (filterIndex == 0 || filterIndex == 3)
        ? filterItems<Stage>(stages, (s) => s.name)
        : [],
    teams: (filterIndex == 0 || filterIndex == 4)
        ? filterItems<Team>(teams, (t) => t.name)
        : [],
  );
}
