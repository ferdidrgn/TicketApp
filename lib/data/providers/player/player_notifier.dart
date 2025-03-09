import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/useCase/player/get_player_by_id_use_case_impl.dart';
import '../../../domain/useCase/player/get_players_use_case_impl.dart';
import '../../model/player_model.dart';
import 'player_state.dart';

class PlayerNotifier extends StateNotifier<PlayerState> {
  final GetPlayerByIdUseCase getPlayerByIdUseCase;
  final GetPlayersUseCase getPlayersUseCase;

  PlayerNotifier(this.getPlayerByIdUseCase, this.getPlayersUseCase)
      : super(PlayerState());

  Future<void> loadPlayerById(final String playerId) async {
    _setLoadingState(true);
    final result = await getPlayerByIdUseCase.call(playerId);

    result.fold(
      (final failure) => _setErrorState(failure.message),
      (final player) => _setPlayerState(player),
    );
  }

  Future<void> loadPlayers(final isLimit) async {
    _setLoadingState(true);
    final result = await getPlayersUseCase.call(isLimit);

    result.fold(
      (final failure) => _setErrorState(failure.message),
      (final players) => _setPlayersState(players),
    );
  }

  void _setLoadingState(final isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void _setErrorState(final String errorMessage) {
    state = state.copyWith(errorMessage: errorMessage, isLoading: false);
  }

  void _setPlayerState(final PlayerModel? player) {
    state = state.copyWith(player: player, isLoading: false);
  }

  void _setPlayersState(final List<PlayerModel?> players) {
    state = state.copyWith(players: players, isLoading: false);
  }
}
