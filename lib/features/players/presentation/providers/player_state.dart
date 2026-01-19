import '../../../../core/base/base_loadable_state.dart';
import '../../domain/entities/player.dart';

class PlayerState extends LoadableState<Player, List<Player>> {
  const PlayerState({
    super.dataList,
    super.dataSingle,
    super.isLoading,
    super.errorMessage,
  });

  @override
  PlayerState copyWith({
    final Player? dataSingle,
    final List<Player>? dataList,
    final bool? isLoading,
    final String? errorMessage,
  }) =>
      PlayerState(
        dataSingle: dataSingle ?? this.dataSingle,
        dataList: dataList ?? this.dataList,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage,
      );
}
