import 'package:ticketapp/core/common/base_notifier.dart';
import 'package:ticketapp/data/providers/player/player_provider.dart';
import '../../../domain/entities/player.dart';
import 'player_state.dart';

/// Oyuncu verilerinin yüklenmesi, önbelleklenmesi ve ağ durumuna göre
/// otomatik yeniden yüklenmesinden sorumlu ViewModel sınıfı
class PlayerNotifier extends BaseNotifier<PlayerState> {
  @override
  PlayerState initialState() => const PlayerState();

  Future<void> refresh() => getPlayers(false);

  Future<void> getPlayers(final bool isLimit) => execute(
        () => ref.read(getPlayersUseCaseProvider).call(isLimit),
        onSuccess: (final players) => _setPlayersLoaded(players),
      );

  Future<void> getPlayersByIds(final List<String> playerIds) async {
    if (playerIds.isEmpty) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Oyuncu ID listesi boş olamaz');
      return;
    }

    await execute(
      () => ref.read(getPlayerByIdUseCaseProvider).call(playerIds),
      onSuccess: (final players) => _setPlayersLoaded(players),
    );
  }

  void _setPlayersLoaded(final List<Player>? players) => state = state.copyWith(
      dataList: players,
      dataSingle: players?.length == 1 ? players!.first : state.dataSingle,
      errorMessage: null);
}

/// PlayerState için yardımcı metodlar sağlayan extension
/// PlayerState için extension metodlar
extension PlayerStateX on PlayerState {
  bool get hasData => dataList != null && dataList!.isNotEmpty;

  /// Verilen ID'ye sahip oyuncuyu state'ten bulur
  Player? getPlayerById(final String playerId) {
    if (dataList == null) return null;
    try {
      return dataList!.firstWhere((final player) => player.id == playerId);
    } catch (_) {
      return null;
    }
  }

  /// Verilen ID listesine sahip oyuncuları state'ten bulur
  /// (Hatanın çözümü bu metoddur)
  List<Player> getPlayersByIds(final List<String> playerIds) {
    if (dataList == null) return [];
    return dataList!
        .where((final player) => playerIds.contains(player.id))
        .toList();
  }
}

// ==============================================================================
// USAGE EXAMPLES
// ==============================================================================

/// Example 1: Basic loading
/// ```dart
/// final notifier = ref.read(playerProvider.notifier);
/// await notifier.loadPlayers(shouldLimit: false);
/// ```
///
/// Example 2: Load specific players
/// ```dart
/// final playerIds = ['player1', 'player2', 'player3'];
/// await notifier.loadPlayersByIds(playerIds);
/// ```
///
/// Example 3: Refresh data (Pull-to-refresh)
/// ```dart
/// await notifier.refresh();
/// ```
///
/// Example 4: Clear data on logout
/// ```dart
/// notifier.clearPlayers();
/// ```
///
/// Example 5: Watch state in UI
/// ```dart
/// final playerState = ref.watch(playerProvider);
/// if (playerState.isLoading) return const LoadingWidget();
/// if (playerState.hasError) return ErrorWidget(playerState.errorMessage);
/// if (playerState.isListEmpty) return const EmptyWidget();
/// return PlayerListWidget(playerState.dataList!);
/// ```
///
/// Example 6: Extension usage
/// ```dart
/// final notifier = ref.read(playerProvider.notifier);
/// if (notifier.hasPlayer('player123')) {
///   final player = notifier.getPlayerFromState('player123');
/// }
/// ```
