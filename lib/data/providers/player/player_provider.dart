import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/useCase/player/get_player_by_id_use_case_impl.dart';
import '../../../domain/useCase/player/get_players_use_case_impl.dart';
import '../../repository/player/player_repository_provider.dart';
import 'player_notifier.dart';
import 'player_state.dart';

final playerProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>((final ref) {
  return PlayerNotifier(
    ref.watch(getPlayerByIdUseCaseProvider),
    ref.watch(getPlayersUseCaseProvider),
  );
});

// Use case providers
final getPlayerByIdUseCaseProvider =
    Provider<GetPlayerByIdUseCase>((final ref) {
  final repository = ref.watch(playerRepositoryProvider);
  return GetPlayerByIdUseCaseImpl(repository);
});

final getPlayersUseCaseProvider = Provider<GetPlayersUseCase>((final ref) {
  final repository = ref.watch(playerRepositoryProvider);
  return GetPlayersUseCaseImpl(repository);
});
