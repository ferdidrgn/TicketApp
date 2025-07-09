import 'package:ticketapp/core/common/base_loadable_state.dart';
import '../../../domain/entities/player.dart';

class PlayerState extends LoadableState<Player, List<Player>> {
  const PlayerState({
    final Player? player,
    final List<Player>? players,
    super.isLoading,
    super.errorMessage,
  }) : super(dataSingle: player, dataList: players);

  @override
  PlayerState copyWith({
    final Player? dataSingle,
    final List<Player>? dataList,
    final bool? isLoading,
    final String? errorMessage,
  }) {
    return PlayerState(
      player: dataSingle ?? this.dataSingle,
      players: dataList ?? this.dataList,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
