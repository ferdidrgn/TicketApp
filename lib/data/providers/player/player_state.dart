import '../../../core/common/base_state.dart';
import '../../../domain/entities/player.dart';

class PlayerState extends BaseState {
  Player? player;
  List<Player>? players;

  PlayerState({
    this.player,
    this.players = const [],
    super.isLoading,
    super.errorMessage,
  });

  @override
  PlayerState copyWith({
    Player? player,
    List<Player>? players,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PlayerState(
      player: player ?? this.player,
      players: players ?? this.players,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
