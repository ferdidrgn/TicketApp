import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import 'package:ticketapp/data/providers/player/player_provider.dart';
import '../../../domain/entities/player.dart';
import 'player_state.dart';

/// Oyuncu verilerinin yüklenmesi, önbelleklenmesi ve ağ durumuna göre
/// otomatik yeniden yüklenmesinden sorumlu ViewModel sınıfı
class PlayerNotifier extends BaseNotifierWithNetworkChecker<PlayerState> {
  @override
  PlayerState initialState() => const PlayerState();

  @override
  void reloadData() => getPlayers(false);

  Future<void> refresh() => getPlayers(false);

  Future<void> getPlayers(final isLimit) => executeWithInternetCheck(
        () => ref.read(getPlayersUseCaseProvider).call(isLimit),
        onSuccess: _handlePlayersLoaded,
      );

  Future<void> getPlayersByIds(final List<String> playerIds) async {
    if (playerIds.isEmpty) {
      _handleEmptyPlayerIds();
      return;
    }

    await executeWithInternetCheck(
      () => ref.read(getPlayerByIdUseCaseProvider).call(playerIds),
      onSuccess: _handlePlayersLoaded,
    );
  }

  void clearPlayers() =>
      state = state.copyWith(dataList: const [], dataSingle: null);

  void _handlePlayersLoaded(final List<Player>? players) =>
      state = state.copyWith(dataList: players);

  void _handleEmptyPlayerIds() => state = state.copyWith(
      isLoading: false, errorMessage: 'Oyuncu ID listesi boş olamaz');
}

/// PlayerState için yardımcı metodlar sağlayan extension
extension PlayerStateX on PlayerState {
  bool hasPlayer(final String playerId) {
    if (dataList == null) return false;
    return dataList!.any((final player) => player.id == playerId);
  }

  int get playerCount => dataList?.length ?? 0;
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
