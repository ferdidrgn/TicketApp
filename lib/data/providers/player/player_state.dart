import '../../../domain/entities/player.dart';
import '../../model/player_model.dart';

class PlayerState {
  final List<PlayerModel?> players;
  final PlayerModel? player;
  final bool isLoading;
  final String? errorMessage;

  PlayerState({
    this.players = const [],
    this.player,
    this.isLoading = false,
    this.errorMessage,
  });

  PlayerState copyWith({
    final List<PlayerModel?>? players,
    final PlayerModel? player,
    final bool? isLoading,
    final String? errorMessage,
  }) {
    return PlayerState(
      players: players ?? this.players,
      player: player ?? this.player,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
