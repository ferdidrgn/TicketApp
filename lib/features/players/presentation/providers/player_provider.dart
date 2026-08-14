import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/failures.dart';
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
///
/// ⚠️ ÖNEMLİ: nowShowsId / oldShowsId listelerinden biri boşsa (veya o
/// listedeki gösteriler artık Firestore'da yoksa / çekilirken hata verirse)
/// sayfanın TAMAMI kilitlenmemeli. Bu yüzden aktif ve geçmiş gösteriler
/// birbirinden BAĞIMSIZ ve hataya karşı toleranslı şekilde çekilir; biri
/// başarısız olsa bile diğeri ve oyuncunun kendi bilgileri (bio, ödüller vb.)
/// normal şekilde gösterilir. Boş/başarısız taraf sadece "gösteri yok"
/// mesajıyla boş liste döner.
@riverpod
Future<PlayerDetailState> playerDetail(
    final Ref ref, final String playerId) async {
  // 1. Oyuncuyu getir (bu kısım gerçekten kritik; oyuncu yoksa sayfa
  // zaten anlamsız olur, o yüzden burada hata fırlatmak doğru).
  final player = await ref.watch(playerByIdProvider(playerId).future);
  if (player == null) throw Exception('Oyuncu bulunamadı');

  // 2. Aktif ve geçmiş gösterileri BİRBİRİNDEN AYRI ve hataya toleranslı
  // şekilde çek. Böylece örneğin oldShowsId boşsa/hatalıysa sadece
  // "Arşiv henüz güncellenmemiş." mesajı gösterilir, tüm sayfa kilitlenmez.
  final results = await Future.wait([
    _safeFetchShows(ref, player.nowShowsId),
    _safeFetchShows(ref, player.oldShowsId),
  ]);

  // 3. 🔥 UI'ın beklediği ayrıştırılmış state'i döndür
  return PlayerDetailState(
    player: player,
    activeShows: results[0],
    pastShows: results[1],
  );
}

/// Verilen gösteri ID listesini çeker. Liste boşsa ya da çekim sırasında
/// herhangi bir hata (network, Firestore whereIn limiti, silinmiş döküman
/// vb.) oluşursa sayfanın tamamını çökertmek yerine sessizce boş liste
/// döner; ilgili sekme "gösteri yok" durumunu gösterir.
Future<List<Show>> _safeFetchShows(
    final Ref ref, final List<String> showIds) async {
  if (showIds.isEmpty) return <Show>[];
  try {
    final shows = await ref.watch(showsByIdsProvider(showIds).future);
    return shows.where((final s) => showIds.contains(s.id)).toList();
  } catch (_) {
    // Kasıtlı olarak yutuluyor: bir kategori gösterisi çekilemese bile
    // oyuncu detay sayfasının geri kalanı çalışmaya devam etmeli.
    return <Show>[];
  }
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
