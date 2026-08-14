import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../players/domain/entities/player.dart';
import '../../../players/presentation/providers/player_provider.dart';
import '../../../shows/domain/entities/show.dart';
import '../../../shows/presentation/providers/show_provider.dart';
import '../../../stages/domain/entities/stage.dart';
import '../../../stages/presentation/providers/stage_provider.dart';
import '../../../users/data/repositories/user_repository_provider.dart';
import '../../../users/domain/entities/favorite_type.dart';
import '../../../users/domain/usecases/set_favorite_use_case_impl.dart';
import '../../../users/presentation/providers/user_provider.dart';

/// 🔥 Elle (codegen'siz) tanımlanmış provider'lar.
/// Bu dosya, `build_runner` çalıştırılamayan ortamlarda bile güvenle
/// derlensin diye Riverpod'un generator'ı yerine klasik API kullanır.

final setFavoriteUseCaseProvider = Provider<SetFavoriteUseCase>(
  (final ref) => SetFavoriteUseCaseImpl(ref.watch(userRepositoryProvider)),
);

/// Verilen öğenin kullanıcının favorilerinde olup olmadığını anlık olarak döner.
/// `userProfileProvider`ı izlediği için favori değiştiğinde otomatik güncellenir.
final isFavoriteProvider =
    Provider.family<bool, ({String itemId, FavoriteType type})>(
        (final ref, final params) {
  final user = ref.watch(userProfileProvider).value;
  if (user == null || params.itemId.isEmpty) return false;

  switch (params.type) {
    case FavoriteType.show:
      return user.favoriteShows.contains(params.itemId);
    case FavoriteType.stage:
      return user.favoriteStages.contains(params.itemId);
    case FavoriteType.player:
      return user.favoritePlayers.contains(params.itemId);
  }
});

/// Favori ekleme/çıkarma mutasyonunu yönetir.
/// State: o an Firestore'a yazılmakta olan "type:itemId" anahtarlarının
/// kümesi — böylece sadece dokunulan buton spinner gösterir, ekrandaki
/// diğer favori butonları etkilenmez.
class FavoriteMutation extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  String _key(final String itemId, final FavoriteType type) =>
      '${type.name}:$itemId';

  bool isPending(final String itemId, final FavoriteType type) =>
      state.contains(_key(itemId, type));

  /// Favori durumunu tersine çevirir. Başarılı olursa true döner.
  Future<bool> toggle(
      {required final String itemId, required final FavoriteType type}) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || itemId.isEmpty) return false;

    final key = _key(itemId, type);
    if (state.contains(key)) return false; // zaten işlem sürüyor

    final isCurrentlyFavorite =
        ref.read(isFavoriteProvider((itemId: itemId, type: type)));

    state = {...state, key};
    var success = true;
    try {
      await ref
          .read(setFavoriteUseCaseProvider)
          .call(userId, itemId, type, !isCurrentlyFavorite)
          .getOrThrow();
      ref.invalidate(userProfileProvider);
    } catch (_) {
      success = false;
    } finally {
      if (ref.mounted) state = {...state}..remove(key);
    }
    return success;
  }
}

final favoriteMutationProvider =
    NotifierProvider<FavoriteMutation, Set<String>>(FavoriteMutation.new);

/// Kullanıcının tüm favorilerini (oyun/sahne/sanatçı) ilgili tam
/// varlıklarla birlikte getiren birleşik provider. `myTickets` provider'ı
/// ile aynı desen: önce ID listelerini User dökümanından al, sonra
/// paralel olarak gerçek varlıkları çek.
class MyFavorites {
  final List<Show> shows;
  final List<Stage> stages;
  final List<Player> players;

  const MyFavorites({
    required this.shows,
    required this.stages,
    required this.players,
  });

  bool get isEmpty => shows.isEmpty && stages.isEmpty && players.isEmpty;
}

final myFavoritesProvider =
    FutureProvider.autoDispose<MyFavorites>((final ref) async {
  final user = await ref.watch(userProfileProvider.future);
  if (user == null) {
    return const MyFavorites(shows: [], stages: [], players: []);
  }

  final results = await Future.wait([
    ref.watch(showsByIdsProvider(user.favoriteShows).future),
    ref.watch(stagesByIdsProvider(user.favoriteStages).future),
    ref.watch(playersByIdsProvider(user.favoritePlayers).future),
  ]);

  return MyFavorites(
    shows: results[0] as List<Show>,
    stages: results[1] as List<Stage>,
    players: results[2] as List<Player>,
  );
});
