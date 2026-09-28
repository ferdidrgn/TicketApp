import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../data/repositories/player_repository_provider.dart';
import '../../domain/entities/player.dart';
import '../../domain/usecases/add_player_use_case_impl.dart';
import '../../domain/usecases/delete_player_use_case_impl.dart';
import '../../domain/usecases/update_player_use_case_impl.dart';
import 'player_provider.dart';

// 🔧 KODLAMA NOTU: `player_provider.dart` `@riverpod` codegen kullanıyor ve
// bir `player_provider.g.dart`'ı var — build_runner bu sandbox'ta
// çalışmadığından oraya yeni bir `@riverpod` provider EKLENEMEZ. Bu YENİ
// mutation provider'ı diğer admin mutation provider'ları (Event/Stage/
// Team) ile AYNI, klasik/codegen'siz `Notifier`+`NotifierProvider`
// API'siyle ayrı bir dosyada tanımlandı.

final addPlayerUseCaseProvider = Provider<AddPlayerUseCase>(
    (final ref) => AddPlayerUseCaseImpl(ref.watch(playerRepositoryProvider)));

final updatePlayerUseCaseProvider = Provider<UpdatePlayerUseCase>(
    (final ref) =>
        UpdatePlayerUseCaseImpl(ref.watch(playerRepositoryProvider)));

final deletePlayerUseCaseProvider = Provider<DeletePlayerUseCase>(
    (final ref) =>
        DeletePlayerUseCaseImpl(ref.watch(playerRepositoryProvider)));

final playerMutationProvider =
    NotifierProvider<PlayerMutationNotifier, AsyncValue<void>>(
        PlayerMutationNotifier.new);

class PlayerMutationNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// ➕ Admin panelinden yeni bir oyuncu ekler.
  Future<void> addPlayer(final Player player, final File? imageFile) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(addPlayerUseCaseProvider)
          .call(player, imageFile)
          .getOrThrow();
      ref.invalidate(playersProvider);
    });
  }

  /// 🔄 Admin panelinden bir oyuncuyu (Phase 2: edit) günceller.
  Future<void> updatePlayer({
    required final String playerId,
    required final Map<String, dynamic> updatedData,
    final File? imageFile,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(updatePlayerUseCaseProvider)
          .call(playerId, updatedData, imageFile)
          .getOrThrow();
      ref.invalidate(playersProvider);
    });
  }

  /// 🗑️ Admin panelinden bir oyuncuyu (Phase 2) siler.
  Future<void> deletePlayer(final String playerId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(deletePlayerUseCaseProvider).call(playerId).getOrThrow();
      ref.invalidate(playersProvider);
    });
  }
}
