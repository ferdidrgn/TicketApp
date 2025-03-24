import '../../../core/common/base_notifier.dart';
import '../../../domain/useCase/player/get_player_by_id_use_case_impl.dart';
import '../../../domain/useCase/player/get_players_use_case_impl.dart';
import 'player_state.dart';

class PlayerNotifier extends BaseNotifier<PlayerState> {
  final GetPlayerByIdUseCase getPlayerByIdUseCase;
  final GetPlayersUseCase getPlayersUseCase;

  PlayerNotifier(this.getPlayerByIdUseCase, this.getPlayersUseCase)
      : super(PlayerState());

  Future<void> loadPlayers(final isLimit) async {
    await handleOperation(
      () => getPlayersUseCase.call(isLimit),
      onSuccess: (final players) =>
          state = state.copyWith(players: players),
    );
  }

  Future<void> loadPlayersByIds(final List<String> playerIds) async {
    await handleOperation(
      () => getPlayerByIdUseCase.call(playerIds),
      onSuccess: (final players) =>
          state = state.copyWith(players: players),
    );
  }
}
