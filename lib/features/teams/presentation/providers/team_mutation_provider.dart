import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../data/repositories/team_repository_provider.dart';
import '../../domain/entities/team.dart';
import '../../domain/usecases/add_team_use_case_impl.dart';
import 'team_provider.dart';

// 🔧 KODLAMA NOTU: `team_provider.dart` `@riverpod` codegen kullanıyor ve
// bir `team_provider.g.dart`'ı var — build_runner bu sandbox'ta
// çalışmadığından oraya yeni bir `@riverpod` provider EKLENEMEZ. Bu YENİ
// mutation provider'ı `event_mutation_provider.dart`/`stage_mutation_
// provider.dart` ile AYNI, klasik/codegen'siz `Notifier`+`NotifierProvider`
// API'siyle ayrı bir dosyada tanımlandı.

final addTeamUseCaseProvider = Provider<AddTeamUseCase>(
    (final ref) => AddTeamUseCaseImpl(ref.watch(teamRepositoryProvider)));

final teamMutationProvider =
    NotifierProvider<TeamMutationNotifier, AsyncValue<void>>(
        TeamMutationNotifier.new);

class TeamMutationNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// ➕ Admin panelinden yeni bir topluluk (Team) ekler.
  Future<void> addTeam(final Team team, final File? imageFile) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(addTeamUseCaseProvider)
          .call(team, imageFile)
          .getOrThrow();
      ref.invalidate(teamsProvider);
    });
  }
}
