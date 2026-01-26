import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../../../core/errors/failures.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../data/repositories/player_repository_provider.dart';
import '../../domain/entities/player.dart';
import '../../domain/usecases/get_player_by_id_use_case_impl.dart';
import '../../domain/usecases/get_player_search_use_case_impl.dart';
import '../../domain/usecases/get_players_use_case_impl.dart';

part 'player_provider.g.dart';

// ==============================================================================
// 1. USE CASE PROVIDERS
// ==============================================================================

@riverpod
GetPlayersUseCase getPlayersUseCase(final Ref ref) =>
    GetPlayersUseCaseImpl(ref.watch(playerRepositoryProvider));

@riverpod
GetPlayerByIdUseCase getPlayerByIdUseCase(final Ref ref) =>
    GetPlayerByIdUseCaseImpl(ref.watch(playerRepositoryProvider));

@riverpod
GetPlayerSearchUseCase getPlayerSearchUseCase(final Ref ref) =>
    GetPlayerSearchUseCaseImpl(ref.watch(playerRepositoryProvider));

// ==============================================================================
// 2. DATA PROVIDERS
// ==============================================================================

@riverpod
Future<List<Player>> players(final Ref ref,
        {final bool isLimit = false}) async =>
    ref.watch(getPlayersUseCaseProvider).call(isLimit).getOrThrow();

@riverpod
Future<List<Player>> playersByIds(final Ref ref, final List<String> ids) async {
  final validIds = ids.where((final id) => id.trim().isNotEmpty).toList();
  if (validIds.isEmpty) return [];
  return ref.watch(getPlayerByIdUseCaseProvider).call(validIds).getOrThrow();
}

@riverpod
Future<Player?> playerById(final Ref ref, final String id) async {
  if (id.isEmpty) return null;
  // Tekil oyuncu verisini çekiyoruz
  final result = await ref.watch(playersByIdsProvider([id]).future);
  return result.isNotEmpty ? result.first : null;
}

/// 🔥 OYUNCU DETAY VE GÖSTERİLERİNİ BİRLEŞTİREN ANA PROVIDER
@riverpod
Future<PlayerDetailState> playerDetail(
    final Ref ref, final String playerId) async {
  // 1. Oyuncuyu getir
  final player = await ref.watch(playerByIdProvider(playerId).future);
  if (player == null) throw Exception('Oyuncu bulunamadı');

  // 2. Tüm gösteri ID'lerini birleştir
  final allShowIds = [...player.nowShowsId, ...player.oldShowsId];

  // 3. Gösterileri çek
  final shows = allShowIds.isNotEmpty
      ? await ref.watch(showsByIdsProvider(allShowIds).future)
      : <Show>[];

  // 4. 🔥 UI'ın beklediği ayrıştırılmış state'i döndür
  return PlayerDetailState(
    player: player,
    activeShows:
        shows.where((final s) => player.nowShowsId.contains(s.id)).toList(),
    pastShows:
        shows.where((final s) => player.oldShowsId.contains(s.id)).toList(),
  );
}

// ==============================================================================
// 3. STATE CLASS (UI Getter hatalarını burası çözer)
// ==============================================================================
class PlayerDetailState {
  final Player player;
  final List<Show> activeShows;
  final List<Show> pastShows;

  PlayerDetailState({
    required this.player,
    required this.activeShows,
    required this.pastShows,
  });
}

extension PlayerListX on List<Player> {
  List<Player> filterByIds(final List<String> ids) =>
      where((final p) => ids.contains(p.id)).toList();
}
