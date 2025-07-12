import 'package:ticketapp/core/common/base_notifier_with_network_checker.dart';
import '../../../core/network/internet_service.dart';
import '../../../domain/useCase/player/get_player_by_id_use_case_impl.dart';
import '../../../domain/useCase/player/get_players_use_case_impl.dart';
import 'player_state.dart';

class PlayerNotifier extends BaseNotifierWithNetworkChecker<PlayerState> {
  final GetPlayerByIdUseCase _getPlayerByIdUseCase;
  final GetPlayersUseCase _getPlayersUseCase;

  PlayerNotifier(
    final InternetService internetService,
    this._getPlayerByIdUseCase,
    this._getPlayersUseCase,
  ) : super(internetService, const PlayerState());

  @override // Internet restore olduğunda yapılacak işlemler
  void reloadData() => loadPlayers(false);

  Future<void> loadPlayers(final isLimit) => executeWithInternetCheck(
        () => _getPlayersUseCase.call(isLimit),
        onSuccess: (final players) => state = state.copyWith(dataList: players),
      );

  Future<void> loadPlayersByIds(final List<String> playerIds) =>
      executeWithInternetCheck(
        () => _getPlayerByIdUseCase.call(playerIds),
        onSuccess: (final players) => state = state.copyWith(dataList: players),
      );
}
