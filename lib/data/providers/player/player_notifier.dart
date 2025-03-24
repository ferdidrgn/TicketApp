import '../../../core/common/base_notifier.dart';
import '../../../domain/useCase/player/get_player_by_id_use_case_impl.dart';
import '../../../domain/useCase/player/get_players_use_case_impl.dart';
import 'player_state.dart';

class PlayerNotifier extends BaseNotifier<PlayerState> {
  final GetPlayerByIdUseCase getPlayerByIdUseCase;
  final GetPlayersUseCase getPlayersUseCase;

  PlayerNotifier(this.getPlayerByIdUseCase, this.getPlayersUseCase)
      : super(PlayerState());

  Future<void> loadPlayerById(final String playerId) async {
    await handleOperation(
          () => getPlayerByIdUseCase.call(playerId),
      onSuccess: (final player) => state = state.copyWith(player: player),
    );
  }

  Future<void> loadPlayers(final isLimit) async {
    await handleOperation(
          () => getPlayersUseCase.call(isLimit),
      onSuccess: (final players) => state = state.copyWith(players: players),
    );
  }
}
